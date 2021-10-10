#include <assert.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <libgen.h>
#include <pthread.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/utsname.h>

#include "jni.h"
#include "log.h"
#include "utils.h"
#include "JavaLauncher.h"
#include "external/fishhook/fishhook.h"

#import "customcontrols/CustomControlsUtils.h"
#import "LauncherPreferences.h"

// PojavLancher: fixme: are these wrong?
#define FULL_VERSION "1.8.0-internal"
#define DOT_VERSION "1.8"

#if CONFIG_RELEASE == 1
# define CONFIG_TYPE "release"
#else
# define CONFIG_TYPE "debug"
#endif

#ifndef CONFIG_COMMIT
# define CONFIG_COMMIT unspecified
#endif

static char java_libs_path[2048];
static char args_path[2048];
static char env_path[2048];
static char log_path[2048];

extern char **environ;

static const char* const_progname = "java";
static const char* const_launcher = "openjdk";
static const char** const_jargs = NULL;
static const char** const_appclasspath = NULL;
static const jboolean const_javaw = JNI_FALSE;
static const jboolean const_cpwildcard = JNI_TRUE;
static const jint const_ergo_class = 0; // DEFAULT_POLICY

typedef jint JLI_Launch_func(int argc, char ** argv, /* main argc, argc */
        int jargc, const char** jargv,          /* java args */
        int appclassc, const char** appclassv,  /* app classpath */
        const char* fullversion,                /* full version defined */
        const char* dotversion,                 /* dot version defined */
        const char* pname,                      /* program name */
        const char* lname,                      /* launcher name */
        jboolean javaargs,                      /* JAVA_ARGS */
        jboolean cpwildcard,                    /* classpath wildcard*/
        jboolean javaw,                         /* windows-only javaw */
        jint ergo                               /* ergonomics class policy */
);

int main(int argc, char * argv[]);

static int (*orig_dladdr)(const void* addr, Dl_info* info);
static void* (*orig_mmap)(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
static char* (*orig_realpath)(const char *restrict path, char *restrict resolved_path);
static void (*orig_sys_icache_invalidate)(void *start, size_t len);

static int margc = 0;
static char* margv[1000];
static int pfd[2];
static int log_fd;
static pthread_t logger;
static BOOL filteredSessionID;

const char *javaHome;
const char *renderer;
const char *allocmem;
const char *multidir;

char *homeDir;

NSString *javaHome_pre;
NSString *renderer_pre;
NSString *allocmem_pre;
NSString *multidir_pre;

int hooked_dladdr(const void* addr, Dl_info* info) {
    int retVal = orig_dladdr(addr, info);
    if (addr == main) {
        NSLog(@"hooked dladdr");
        info->dli_fname = getenv("JAVA_EXT_EXECNAME");
        NSLog(@"name = %s", info->dli_fname);
    }
    return retVal;
}

void *hooked_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    NSLog(@"mmap(%p, %ld, %d, %d, %d, %lld)", addr, len, prot, flags, fd, offset);

    if (flags & MAP_JIT) {
        NSLog(@"'-> Found JIT mmap");
        //flags &= ~MAP_JIT;
    }

    // raise(SIGINT);
    return orig_mmap(addr, len, prot, flags, fd, offset);
}

char *hooked_realpath(const char *restrict path, char *restrict resolved_path) {
    NSLog(@"hooked realpath %s", path);
    if (!strncmp(javaHome, path, strlen(javaHome))) {
        strcpy(resolved_path, path);
        return resolved_path;
    } else {
        return orig_realpath(path, resolved_path);
    }
}

void hooked_sys_icache_invalidate(void *start, size_t len) {
    // mprotect(start, 16384, PROT_EXEC | PROT_READ);
    // NSLog(@"mprotect errno %d", errno);
    orig_sys_icache_invalidate(start, len);
}

static void *logger_thread() {
    ssize_t rsize;
    char buf[2048];
    while((rsize = read(pfd[0], buf, sizeof(buf)-1)) > 0) {
        // Filter out Session ID here
        int index;
        if (!filteredSessionID) {
            char *sessionStr = strstr(buf, "(Session ID is ");
            if (sessionStr) {
                char *censorStr = "(Session ID is <censored>)\n\0";
                strcpy(sessionStr, censorStr);
                rsize = strlen(buf);
                filteredSessionID = true;
            }
        }
        write(log_fd, buf, rsize);
    }
    close(log_fd);
    return NULL;
}

void init_hookFunctions() {
    // if (!started && strncmp(argv[0], "/Applications", 13)) 
    {
        // Jailed only: hook some functions for symlinked JRE home dir
        int retval = rebind_symbols((struct rebinding[4]){
            //{"dlopen", hooked_dlopen, (void *)&orig_dlopen},
            {"dladdr", hooked_dladdr, (void *)&orig_dladdr},
            {"mmap", hooked_mmap, (void *)&orig_mmap},
            {"realpath", hooked_realpath, (void *)&orig_realpath},
            {"sys_icache_invalidate", hooked_sys_icache_invalidate, (void *)&orig_sys_icache_invalidate}
        }, 4);
        NSLog(@"hook retval = %d", retval);
    }
}

void init_loadCustomEnv() {
    FILE *envFile = fopen(env_path, "r");

    debug("[Pre-init] Reading custom environment variables (custom_env.txt), opened=%d\n", envFile != NULL);

    if (envFile) {
        char *line = NULL;
        size_t len = 0;
        ssize_t read;
        while ((read = getline(&line, &len, envFile)) != -1) {
            if (line[0] == '#' || line[0] == '\n') continue;
            if (line[read-1] == '\n') {
                line[read-1] = '\0';
            }
            if (strchr(line, '=') != NULL) {
                debug("[Pre-init] Added custom env: %s", line);
                setenv(strtok(line, "="), strtok(NULL, "="), 1);
            } else {
                debug("[Pre-init] Warning: skipped empty value custom env: %s", line);
            }
        }
        fclose(envFile);
    }
}

void init_loadCustomJvmFlags() {
    NSString *jvmargs = getPreference(@"java_args");
    BOOL isFirstArg = YES;
    for (NSString *jvmarg in [jvmargs componentsSeparatedByString:@" -"]) {
        if ([jvmarg length] == 0) continue;
        if (isFirstArg) {
            isFirstArg = NO;
            margv[margc] = (char *) [jvmarg UTF8String];
        } else {
            margv[margc] = (char *) [[@"-" stringByAppendingString:jvmarg] UTF8String];
        }
        NSLog(@"[Pre-init] Added custom JVM flag: %s", margv[margc]);
        ++margc;
    }
}

void init_migrateToPlist(char* prefKey, char* filename) {
    // NSString *readmeStr = @"#README - this file has been merged into launcher_preferences.plist";
    NSError *error;
    NSString *str, *path_str;

    // overrideargs.txt
    path_str = [NSString stringWithFormat:@"%s/%s", getenv("POJAV_HOME"), filename];
    str = [NSString stringWithContentsOfFile:path_str encoding:NSUTF8StringEncoding error:&error];
    if (error == nil && ![str hasPrefix:@"#README"]) {
        setPreference(@(prefKey), str);
        [@"#README - this file has been merged into launcher_preferences.plist" writeToFile:path_str atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

void init_logDeviceAndVer (char *argument) {
    struct utsname systemInfo;
    uname(&systemInfo);
    // Hardware + software
    const char *deviceHardware = systemInfo.machine;
    const char *deviceSoftware = [[[UIDevice currentDevice] systemVersion] cStringUsingEncoding:NSUTF8StringEncoding];

    // Jailbreak
    const char *deviceJailbreak;
    if (strncmp(argument, "/Applications", 13) == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/taurine"]) {
            deviceJailbreak = "Taurine";
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/odyssey"]) {
            deviceJailbreak = "Odyssey";
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/chimera"]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/.procursus_strapped"]) {
                deviceJailbreak = "Chimera";
            } else {
                deviceJailbreak = "Chimera <1.4";
            }
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/etc/apt/undecimus"]) {
                deviceJailbreak = "unc0ver";
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/binpack/lib/dyld"]) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/.procursus_strapped"]) {
                    deviceJailbreak = "odysseyra1n";
                } else {
                    deviceJailbreak = "checkra1n";
                }
            }
        }
        debug("[Pre-Init] %s with iOS %s (%s)", deviceHardware, deviceSoftware, deviceJailbreak);
    } else {
        debug("[Pre-Init] %s with iOS %s", deviceHardware, deviceSoftware);
    }

    // PojavLauncher version
    debug("[Pre-Init] PojavLauncher version: %s - %s", CONFIG_TYPE, CONFIG_COMMIT);

    setenv("POJAV_DETECTEDHW", deviceHardware, 1);
    setenv("POJAV_DETECTEDSW", deviceSoftware, 1);
    if (strncmp(argument, "/Applications", 13) == 0) {
        setenv("POJAV_DETECTEDJB", deviceJailbreak, 1);
    }
}

void environmentFailsafes(char *argv[]) {
    if (strncmp(argv[0], "/Applications", 13) == 0) {
        if (0 == access("/usr/lib/jvm/java-8-openjdk/", F_OK)) {
            javaHome_pre = @"/usr/lib/jvm/java-8-openjdk";
        } else if (0 == access("/usr/lib/jvm/java-16-openjdk/", F_OK)) {
            debug("[Pre-init] Java 8 wasn't found on your device. Install Java 8 for more compatibility and the mod installer.");
            javaHome_pre = @"/usr/lib/jvm/java-16-openjdk";
        } else if (0 == access("/usr/lib/jvm/java-17-openjdk/", F_OK)) {
            debug("[Pre-init] Java 8 wasn't found on your device. Install Java 8 for more compatibility and the mod installer.");
            javaHome_pre = @"/usr/lib/jvm/java-17-openjdk";
        } else {
            debug("[Pre-init] FATAL ERROR: Java wasn't found on your device, PojavLauncher cannot continue, aborting.");
            abort();
        }
        javaHome = [javaHome_pre cStringUsingEncoding:NSUTF8StringEncoding];
        setPreference(@"java_home", javaHome_pre);
    } else {
        javaHome = calloc(1, 2048);
        sprintf((char *)javaHome, "%s/jre", homeDir);
    }
}

int launchJVM(int argc, char *argv[]) {
    if (0 != [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Documents/.pojavlauncher"]) {
        NSString *newDir = @"/usr/share/pojavlauncher";
        NSString *oldDir = @"/var/mobile/Documents/.pojavlauncher";
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:oldDir error:nil];
        for (NSString *file in files) {
            [fm moveItemAtPath:[oldDir stringByAppendingPathComponent:file] toPath:[newDir stringByAppendingPathComponent:file] error:nil];
        }
        [fm removeItemAtPath:oldDir error:nil];
        [fm createSymbolicLinkAtURL:oldDir withDestinationURL:newDir error:nil];
    }
    
    if (!started) {
        setenv("BUNDLE_PATH", dirname(argv[0]), 1);

        // Are we running on a jailbroken environment?
        if (strncmp(argv[0], "/Applications", 13) == 0) {
            setenv("HOME", "/usr/share", 1);
            setenv("OLD_POJAV_HOME", "/var/mobile/Documents/.pojavlauncher", 1);
            homeDir = "/usr/share/pojavlauncher";
        } else {
            char pojavHome[2048];
            sprintf(pojavHome, "%s/Documents", getenv("HOME"));
            homeDir = (char *) pojavHome;

            init_hookFunctions();
        }
        setenv("POJAV_HOME", homeDir, 1);
    } else {
        homeDir = getenv("POJAV_HOME");
    }

    init_loadCustomEnv();

    loadPreferences();

    init_migrateToPlist("selected_version", "config_ver.txt");
    init_migrateToPlist("java_args", "overrideargs.txt");

    sprintf((char*) env_path, "%s/custom_env.txt", homeDir);
    sprintf((char*) log_path, "%s/latestlog.txt", homeDir);
    sprintf((char*) java_libs_path, "%s/libs", getenv("BUNDLE_PATH"));
    
    mkdir(dirname(log_path), 755);

    if (!started) {
        debug("[Pre-init] Staring logging STDIO as jrelog:V\n");
        // Redirect stdio to latestlog.txt
        char newname[2048];
        sprintf(newname, "%s/latestlog.old.txt", homeDir);
        rename(log_path, newname);
        FILE* logFile = fopen(log_path, "w");
        if (!logFile) {
            debug("[Pre-init] Error: failed to open %s: %s", log_path, strerror(errno));
            assert(0 && "Failed to open latestlog.txt. Check oslog for more details.");
        }
        log_fd = fileno(logFile);
        setvbuf(stdout, 0, _IOLBF, 0); // make stdout line-buffered
        setvbuf(stderr, 0, _IONBF, 0); // make stderr unbuffered

        /* create the pipe and redirect stdout and stderr */
        pipe(pfd);
        dup2(pfd[1], 1);
        dup2(pfd[1], 2);

        /* spawn the logging thread */
        if(pthread_create(&logger, 0, logger_thread, 0) == -1) {
            char *fail_str = "Failed to start logging!";
            write(log_fd, fail_str, strlen(fail_str));
            close(log_fd);
        }
        pthread_detach(logger);
    }

    init_logDeviceAndVer(argv[0]);
    debug("[Pre-init] Beginning JVM launch\n");
    
    char javaAwtPath[4096];
    // I accidentally patched a bit wrong, the value should be a path containing libawt_xawt.dylib, but here is libawt.dylib path (no need to exist)
    sprintf(javaAwtPath, "%s/Frameworks/libawt.dylib", getenv("BUNDLE_PATH"));
    setenv("JAVA_AWT_PATH", javaAwtPath, 1);

    // setenv("LIBGL_FB", "2", 1);
    setenv("LIBGL_MIPMAP", "3", 1);

    // Fix white color on banner and sheep, since GL4ES 1.1.5
    setenv("LIBGL_NORMALIZE", "1", 1);

    // Disable overloaded functions hack for Minecraft 1.17+
    setenv("LIBGL_NOINTOVLHACK", "1", 1);

    // Override OpenGL version to 4.1 for Zink
    setenv("MESA_GL_VERSION_OVERRIDE", "4.1", 1);

    javaHome_pre = getPreference(@"java_home");
    javaHome = [javaHome_pre cStringUsingEncoding:NSUTF8StringEncoding];
    if ([javaHome_pre length] == 0) {
        environmentFailsafes(argv);
        debug("[Pre-init] JAVA_HOME environment variable was not set. Defaulting to %s for future use.\n", javaHome);
    } else {
        if (0 == [[NSFileManager defaultManager] fileExistsAtPath:javaHome_pre]) {
            debug("[Pre-Init] Failed to locate %s. Restoring default value for JAVA_HOME.", javaHome);
            environmentFailsafes(argv);
        } else {
            debug("[Pre-Init] Restored preference: JAVA_HOME is set to %s\n", javaHome);
        }
    }
    setenv("JAVA_HOME", javaHome, 1);

    if (!started && strncmp(argv[0], "/Applications", 13)) {
        char src[2048], dst[2048];

        // Symlink frameworks -> dylibs on jailed environment
        mkdir(javaHome, 755);

        // Symlink the skeleton part of JRE
        sprintf((char *)src, "%s/jre/man", getenv("BUNDLE_PATH"));
        sprintf((char *)dst, "%s/man", javaHome);
        symlink(src, dst);

        sprintf((char *)src, "%s/jre/lib", getenv("BUNDLE_PATH"));
        sprintf((char *)dst, "%s/lib", javaHome);
        mkdir(dst, 755);

        DIR *d;
        struct dirent *dir;
        d = opendir(src);
        assert(d);
        int i = 0;
        while ((dir = readdir(d)) != NULL) {
            // Skip "." and ".."
            if (i < 2) {
                i++;
                continue;
            } else if (!strncmp(dir->d_name, "jli", 3)) {
                sprintf((char *)dst, "%s/lib/jli", javaHome);
                mkdir(dst, 755);
                
                // libjli.dylib
                sprintf((char *)src, "%s/Frameworks/libjli.dylib.framework/libjli.dylib", getenv("BUNDLE_PATH"));
                sprintf((char *)dst, "%s/lib/jli/libjli.dylib", javaHome);
                symlink(src, dst);
            } else if (!strncmp(dir->d_name, "server", 6)) {
                sprintf((char *)dst, "%s/lib/server", javaHome);
                mkdir(dst, 755);

                // libjsig.dylib
                sprintf((char *)src, "%s/Frameworks/libjsig.dylib.framework/libjsig.dylib", getenv("BUNDLE_PATH"));
                sprintf((char *)dst, "%s/lib/server/libjsig.dylib", javaHome);
                symlink(src, dst);

                // libjvm.dylib
                sprintf((char *)src, "%s/Frameworks/libjvm.dylib.framework/libjvm.dylib", getenv("BUNDLE_PATH"));
                sprintf((char *)dst, "%s/lib/server/libjvm.dylib", javaHome);
                symlink(src, dst);

                // Xusage.txt
                sprintf((char *)src, "%s/jre/lib/server/Xusage.txt", getenv("BUNDLE_PATH"));
                sprintf((char *)dst, "%s/lib/server/Xusage.txt", javaHome);
                symlink(src, dst);
            } else {
                sprintf((char *)src, "%s/jre/lib/%s", getenv("BUNDLE_PATH"), dir->d_name);
                sprintf((char *)dst, "%s/lib/%s", javaHome, dir->d_name);
                symlink(src, dst);
            }
        }
        closedir(d);

        // Symlink dylibs
        sprintf((char *)src, "%s/Frameworks", getenv("BUNDLE_PATH"));
        d = opendir(src);
        assert(d);
        i = 0;
        while ((dir = readdir(d)) != NULL) {
            // Skip "." and ".."
            if (i < 2) {
                i++;
                continue;
            } else if (!strncmp(dir->d_name, "lib", 3) && strlen(dir->d_name) > 12) {
                char *dylibName = strdup(dir->d_name);
                dylibName[strlen(dylibName) - 10] = '\0';
                sprintf((char *)src, "%s/Frameworks/%s/%s", getenv("BUNDLE_PATH"), dir->d_name, dylibName);
                if (!strncmp(dir->d_name, "libjvm.dylib", 12)) {
                    sprintf((char *)dst, "%s/lib/server/%s", javaHome, dylibName);
                } else {
                    sprintf((char *)dst, "%s/lib/%s", javaHome, dylibName);
                }
                symlink(src, dst);
                dylibName[strlen(dylibName) - 11] = '.';
                free(dylibName);
            }
        }
        closedir(d);
    }

    renderer_pre = getPreference(@"renderer");
    renderer = [renderer_pre cStringUsingEncoding:NSUTF8StringEncoding];
    if ([renderer_pre length] == 0) {
        renderer_pre = @"libgl4es_114.dylib";
        setPreference(@"renderer", renderer_pre);
        renderer = [renderer_pre cStringUsingEncoding:NSUTF8StringEncoding];
        setenv("RENDERER", renderer, 1);
        debug("[Pre-init] RENDERER environment variable was not set. Defaulting to %s for future use.\n", renderer);
    } else {
        debug("[Pre-Init] Restored preference: RENDERER is set to %s\n", renderer);
    }
    
    allocmem_pre = [getPreference(@"allocated_memory") stringValue];
    allocmem = [allocmem_pre cStringUsingEncoding:NSUTF8StringEncoding];
    
    char *controlPath = calloc(1, 2048);
    sprintf(controlPath, "%s/controlmap", homeDir);
    mkdir(controlPath, S_IRWXU | S_IRWXG | S_IRWXO);
    setenv("POJAV_PATH_CONTROL", controlPath, 1);
    free(controlPath);
    generateAndSaveDefaultControl();

    char classpath[10000];

    // "/Applications/PojavLauncher.app/libs/launcher.jar:/Applications/PojavLauncher.app/libs/ExagearApacheCommons.jar:/Applications/PojavLauncher.app/libs/gson-2.8.6.jar:/Applications/PojavLauncher.app/libs/jsr305.jar:/Applications/PojavLauncher.app/libs/lwjgl3-minecraft.jar";

    // Generate classpath
    DIR *d;
    struct dirent *dir;
    d = opendir(java_libs_path);
    int cplen = 0;
    if (d) {
        // cplen += sprintf(classpath + cplen, "-Xbootclasspath/a:");
        while ((dir = readdir(d)) != NULL) {
            cplen += sprintf(classpath + cplen, "%s/%s:", java_libs_path, dir->d_name);
        }
        closedir(d);
    }
    debug("[Pre-init] Classpath generated: %s", classpath);
    
    multidir_pre = getPreference(@"game_directory");
    multidir = [multidir_pre cStringUsingEncoding:NSUTF8StringEncoding];
    if ([multidir_pre length] == 0) {
        multidir_pre = @"default";
        multidir = [multidir_pre cStringUsingEncoding:NSUTF8StringEncoding];
        setPreference(@"game_directory", multidir_pre);
        debug("[Pre-init] MULTI_DIR environment variable was not set. Defaulting to %s for future use.\n", multidir);
    } else {
        multidir = [multidir_pre cStringUsingEncoding:NSUTF8StringEncoding];
        debug("[Pre-init] Restored preference: MULTI_DIR is set to %s\n", multidir);
    }
    char *multidir_char = calloc(1, 2048);
    char *librarySym = calloc(1, 2048);
    snprintf(multidir_char, 2048, "%s/instances/%s", getenv("POJAV_HOME"), multidir);
    snprintf(librarySym, 2048, "%s/Library/Application Support/minecraft", getenv("POJAV_HOME"));
    remove(librarySym);
    if (0 != access(multidir_char, F_OK)) {
        mkdir(multidir_char, 755);
    }
    symlink(multidir_char, librarySym);
    setenv("POJAV_GAME_DIR", librarySym, 1);
    
    char *oldGameDir = calloc(1, 2048);
    snprintf(oldGameDir, 2048, "%s/../minecraft", getenv("OLD_POJAV_HOME"));
    if (0 == access(oldGameDir, F_OK)) {
        rename(oldGameDir, multidir_char);
        debug("[Pre-Init] Migrated old minecraft folder to new location.");
    }
    
    char *oldLibraryDir = calloc(1, 2048);
    snprintf(oldLibraryDir, 2048, "%s/../Library", getenv("OLD_POJAV_HOME"));
    if (0 == access(oldLibraryDir, F_OK)) {
        remove(oldLibraryDir);
    }
    // Check if JVM restarts
    if (!started) {
        char *frameworkPath = calloc(1, 2048);
        char *javaPath = calloc(1, 2048);
        char *userDir = calloc(1, 2048);
        char *userHome = calloc(1, 2048);
        char *memMin = calloc(1, 2048);
        char *memMax = calloc(1, 2048);
        snprintf(frameworkPath, 2048, "-Djava.library.path=%s/Frameworks:%s/Frameworks/libOSMesaOverride.dylib.framework", getenv("BUNDLE_PATH"), getenv("BUNDLE_PATH"));
        snprintf(javaPath, 2048, "%s/bin/java", javaHome);
        snprintf(userDir, 2048, "-Duser.dir=%s", getenv("POJAV_GAME_DIR"));
        snprintf(userHome, 2048, "-Duser.home=%s", getenv("POJAV_HOME"));
        snprintf(memMin, 2048, "-Xms%sM", allocmem);
        snprintf(memMax, 2048, "-Xmx%sM", allocmem);
        NSLog(@"[Pre-init] Java executable path: %s", javaPath);
        setenv("JAVA_EXT_EXECNAME", javaPath, 1);

        chdir(librarySym);

        margv[margc++] = javaPath;
        margv[margc++] = "-XstartOnFirstThread";
        margv[margc++] = "-Djava.system.class.loader=net.kdt.pojavlaunch.PojavClassLoader";
        margv[margc++] = memMin;
        margv[margc++] = memMax;
        margv[margc++] = frameworkPath;
        margv[margc++] = userDir;
        margv[margc++] = userHome;
        margv[margc++] = "-Dorg.lwjgl.system.allocator=system";
    } else {
        setenv("RENDERER", renderer, 1);
        debug("[Pre-init] RENDERER has been set to %s", getenv("RENDERER"));
    }

    // Load java
    char libjlipath8[2048]; // java 8
    char libjlipath16[2048]; // java 16+ (?)
    sprintf(libjlipath8, "%s/lib/jli/libjli.dylib", javaHome);
    sprintf(libjlipath16, "%s/lib/libjli.dylib", javaHome);
    void* libjli = dlopen(libjlipath16, RTLD_LAZY | RTLD_GLOBAL);

    if (!libjli) {
        debug("[Init] Can't load %s, trying %s", libjlipath16, libjlipath8);
        libjli = dlopen(libjlipath8, RTLD_LAZY | RTLD_GLOBAL);
        if (!libjli) {
            debug("[Init] JLI lib = NULL: %s", dlerror());
            return -1;
        }

        if (!started) {
            // Setup Caciocavallo
            margv[margc++] = "-Djava.awt.headless=false";
            margv[margc++] = "-Dcacio.font.fontmanager=sun.awt.X11FontManager";
            margv[margc++] = "-Dcacio.font.fontscaler=sun.font.FreetypeFontScaler";
            margv[margc++] = "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel";
            margv[margc++] = "-Dawt.toolkit=net.java.openjdk.cacio.ctc.CTCToolkit";
            margv[margc++] = "-Djava.awt.graphicsenv=net.java.openjdk.cacio.ctc.CTCGraphicsEnvironment";

            // Generate Caciocavallo bootclasspath
            char cacio_libs_path[2048];
            char cacio_classpath[8192];
            sprintf((char*) cacio_libs_path, "%s/libs_caciocavallo", getenv("BUNDLE_PATH"));
            cplen = sprintf(cacio_classpath, "-Xbootclasspath/p");
            d = opendir(cacio_libs_path);
            if (d) {
                while ((dir = readdir(d)) != NULL) {
                    cplen += sprintf(cacio_classpath + cplen, ":%s/%s", cacio_libs_path, dir->d_name);
                }
                closedir(d);
            }
            margv[margc++] = cacio_classpath;
        }
    }
    if (!started) {
        init_loadCustomJvmFlags();
    }
    debug("[Init] Found JLI lib");

    if (!started) {
        margv[margc++] = "-cp";
        margv[margc++] = classpath;
        margv[margc++] = "net.kdt.pojavlaunch.PLaunchApp";
        
        for (int i = 0; i < argc; i++) {
            margv[margc++] = argv[i];
        }
    }

    JLI_Launch_func *pJLI_Launch =
          (JLI_Launch_func *)dlsym(libjli, "JLI_Launch");
          
    if (NULL == pJLI_Launch) {
        debug("[Init] JLI_Launch = NULL");
        return -2;
    }

    // Free unused char arrays
    free(librarySym);
    free(multidir_char);
    free(oldGameDir);
    free(oldLibraryDir);

    debug("[Init] Calling JLI_Launch");
/*
    for (int i = 0; i < margc; i++) {
        debug("arg[%d] = %s", i, margv[i]);
    }
*/
    int targc = started ? argc : margc;
    char **targv = started ? argv : margv;
    
    if (!started) {
        started = true;
    }
/* debug:
for (int i = 0; i < targc; i++) {
debug("Arg=%s", targv[i]);
}
*/
    return pJLI_Launch(targc, targv,
                   0, NULL, // sizeof(const_jargs) / sizeof(char *), const_jargs,
                   0, NULL, // sizeof(const_appclasspath) / sizeof(char *), const_appclasspath,
                   FULL_VERSION,
                   DOT_VERSION,
                   const_progname, // (const_progname != NULL) ? const_progname : *margv,
                   const_launcher, // (const_launcher != NULL) ? const_launcher : *margv,
                   (const_jargs != NULL) ? JNI_TRUE : JNI_FALSE,
                   const_cpwildcard, const_javaw, const_ergo_class);
}
