#include <assert.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <libgen.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "log.h"
#include "utils.h"

#import "ios_uikit_bridge.h"
#import "JavaLauncher.h"
#import "LauncherPreferences.h"

#define fm NSFileManager.defaultManager

static char java_libs_path[2048];
static char args_path[2048];

extern char **environ;

static const char* const_progname = "java";
static const char* const_launcher = "openjdk";
static const char** const_jargs = NULL;
static const char** const_appclasspath = NULL;
static const jboolean const_javaw = JNI_FALSE;
static const jboolean const_cpwildcard = JNI_TRUE;
static const jint const_ergo_class = 0; // DEFAULT_POLICY

static int margc = -1;
static char* margv[1000];

const char *javaHome;
const char *renderer;
const char *allocmem;
const char *multidir;

char *homeDir;

NSString *renderer_pre;
NSString *allocmem_pre;
NSString *multidir_pre;

void init_loadCustomEnv() {
    /* Define default env */

    // I accidentally patched a bit wrong, the value should be a path containing libawt_xawt.dylib, but here is libawt.dylib path (no need to exist)
    setenv("JAVA_AWT_PATH", [NSString stringWithFormat:@"%s/Frameworks/libawt.dylib", getenv("BUNDLE_PATH")].UTF8String, 1);

    // Disable overloaded functions hack for Minecraft 1.17+
    setenv("LIBGL_NOINTOVLHACK", "1", 1);

    // Override OpenGL version to 4.1 for Zink
    setenv("MESA_GL_VERSION_OVERRIDE", "4.1", 1);

    /* Load custom env */
    FILE *envFile = fopen([NSString stringWithFormat:@"%s/custom_env.txt", getenv("POJAV_HOME")].UTF8String, "r");

    regLog("[Pre-init] Reading custom environment variables (custom_env.txt), opened=%d\n", envFile != NULL);

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
                regLog("[Pre-init] Added custom env: %s", line);
                setenv(strtok(line, "="), strtok(NULL, "="), 1);
            } else {
                regLog("[Pre-init] Warning: skipped empty value custom env: %s", line);
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
        //margv[margc] = (char *) [jvmarg UTF8String];

        ++margc;
        if (isFirstArg) {
            isFirstArg = NO;
            margv[margc] = (char *) [jvmarg UTF8String];
        } else {
            margv[margc] = (char *) [[@"-" stringByAppendingString:jvmarg] UTF8String];
        }

        NSLog(@"[JavaLauncher] Added custom JVM flag: %s", margv[margc]);
    }
}

NSString* environmentFailsafes(int minVersion) {
    NSString *javaHome = nil;
    if (getenv("POJAV_DETECTEDJB")) {
        BOOL foundJava8 = [fm fileExistsAtPath:JRE8_HOME_JB];
        if (!foundJava8) {
            regLog("[JavaLauncher] Java 8 wasn't found on your device. Install Java 8 for more compatibility and the mod installer.");
        }

        if (foundJava8 && minVersion <= 8) {
            javaHome = JRE8_HOME_JB;
        } else if ([fm fileExistsAtPath:JRE16_HOME_JB] && minVersion <= 16) {
            javaHome = JRE16_HOME_JB;
        } else if ([fm fileExistsAtPath:JRE17_HOME_JB] && minVersion <= 17) {
            javaHome = JRE17_HOME_JB;
        }
    } else if (minVersion <= 8) {
        javaHome = [NSString stringWithFormat:@"%s/jre", getenv("POJAV_HOME")];
    }

    if (javaHome == nil) {
        showDialog(viewController, NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"Minecraft %@ requires Java %d in order to run. Please install it first.", getPreference(@"selected_version"), minVersion]);
    }

    return javaHome;
}

int launchJVM(NSString *username, id launchTarget, int width, int height, int minVersion) {
    sprintf((char*) java_libs_path, "%s/libs", getenv("BUNDLE_PATH"));

    init_loadCustomEnv();

    regLog("[JavaLauncher] Beginning JVM launch\n");

    NSString *javaHome_pre = getPreference(@"java_home");

    // We handle unset JAVA_HOME right there
    if (username == nil || getSelectedJavaVersion() < minVersion) {
        NSLog(@"[JavaLauncher] Attempting to change to Java %d (actual might be higher)", minVersion);
        javaHome_pre = environmentFailsafes(minVersion);
        NSLog(@"[JavaLauncher] JAVA_HOME is now set to %@", javaHome_pre);
    } /* else if (javaHome_pre.length == 0) {
        javaHome_pre = environmentFailsafes(minVersion);
        setPreference(@"java_home", javaHome_pre);
        NSLog(@"[JavaLauncher] JAVA_HOME environment variable was not set. Default to %@ for future use.\n", javaHome_pre);
    } */ else {
        if (![NSFileManager.defaultManager fileExistsAtPath:javaHome_pre]) {
            javaHome_pre = environmentFailsafes(minVersion);
            setPreference(@"java_home", javaHome_pre);
            NSLog(@"[JavaLauncher] Failed to locate %@. Restored default value for JAVA_HOME.", javaHome_pre);
        } else {
            NSLog(@"[JavaLauncher] Restored preference: JAVA_HOME is set to %@\n", javaHome_pre);
        }
    }

    if (javaHome_pre == nil) {
        return 1;
    }

    javaHome = javaHome_pre.UTF8String;
    setenv("JAVA_HOME", javaHome, 1);

    if (!getenv("POJAV_DETECTEDJB")) {
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
    renderer = renderer_pre.UTF8String;
    if (renderer_pre.length == 0) {
        renderer_pre = @"libgl4es_114.dylib";
        setPreference(@"renderer", renderer_pre);
        renderer = [renderer_pre cStringUsingEncoding:NSUTF8StringEncoding];
        regLog("[JavaLauncher] RENDERER environment variable was not set. Defaulting to %s for future use.\n", renderer);
    } else {
        regLog("[JavaLauncher] Restored preference: RENDERER is set to %s\n", renderer);
    }
    setenv("POJAV_RENDERER", renderer, 1);
    
    allocmem_pre = [getPreference(@"allocated_memory") stringValue];
    allocmem = [allocmem_pre cStringUsingEncoding:NSUTF8StringEncoding];
    
    char classpath[10000];

    // "/Applications/PojavLauncher.app/libs/launcher.jar:/Applications/PojavLauncher.app/libs/ExagearApacheCommons.jar:/Applications/PojavLauncher.app/libs/gson-2.8.6.jar:/Applications/PojavLauncher.app/libs/jsr305.jar:/Applications/PojavLauncher.app/libs/lwjgl3-minecraft.jar";

    // Generate classpath
    DIR *d;
    struct dirent *dir;
    d = opendir(java_libs_path);
    int cplen = -2;
    if (d) {
        // cplen += sprintf(classpath + cplen, "-Xbootclasspath/a:");
        while ((dir = readdir(d)) != NULL) {
            if (cplen < 0) {
                ++cplen;
                continue;
            }
            cplen += sprintf(classpath + cplen, "%s/%s:", java_libs_path, dir->d_name);
        }
        classpath[cplen-1] = '\0';
        closedir(d);
    }
    debugLog("[JavaLauncher] Classpath generated: %s", classpath);

    // Check if JVM restarts
    char *frameworkPath, *javaPath, *jnaLibPath, *userDir, *userHome, *memMin, *memMax, *arcDNS;
    asprintf(&frameworkPath, "-Djava.library.path=%s/Frameworks:%s/Frameworks/libOSMesaOverride.dylib.framework", getenv("BUNDLE_PATH"), getenv("BUNDLE_PATH"));
    asprintf(&javaPath, "%s/bin/java", javaHome);
    asprintf(&jnaLibPath, "-Djna.boot.library.path=%s/Frameworks/libjnidispatch.dylib.framework", getenv("BUNDLE_PATH"));
    asprintf(&userDir, "-Duser.dir=%s", getenv("POJAV_GAME_DIR"));
    asprintf(&userHome, "-Duser.home=%s", getenv("POJAV_HOME"));
    asprintf(&memMin, "-Xms%sM", allocmem);
    asprintf(&memMax, "-Xmx%sM", allocmem);
    asprintf(&arcDNS, "-javaagent:%s/arc_dns_injector.jar=23.95.137.176", java_libs_path);
    NSLog(@"[JavaLauncher] Java executable path: %s", javaPath);
    setenv("JAVA_EXT_EXECNAME", javaPath, 1);

    margv[++margc] = javaPath;
    margv[++margc] = "-XstartOnFirstThread";
    margv[++margc] = "-Djava.system.class.loader=net.kdt.pojavlaunch.PojavClassLoader";
    margv[++margc] = memMin;
    margv[++margc] = memMax;
    margv[++margc] = frameworkPath;
    margv[++margc] = jnaLibPath;
    margv[++margc] = userDir;
    margv[++margc] = userHome;
    margv[++margc] = "-Dorg.lwjgl.system.allocator=system";
    margv[++margc] = "-Dlog4j2.formatMsgNoLookups=true";
    if([getPreference(@"arccapes_enable") boolValue]) {
        margv[++margc] = arcDNS;
    }
    NSString *selectedAccount = getPreference(@"internal_selected_account");
    if (selectedAccount != nil) {
        margv[++margc] = (char *) [NSString stringWithFormat:@"-Dpojav.selectedAccount=%@", selectedAccount].UTF8String;
    }

    // Load java
    char libjlipath8[2048]; // java 8
    char libjlipath16[2048]; // java 16+ (?)
    sprintf(libjlipath8, "%s/lib/jli/libjli.dylib", javaHome);
    sprintf(libjlipath16, "%s/lib/libjli.dylib", javaHome);
    setenv("INTERNAL_JLI_PATH", libjlipath16, 1);
    void* libjli = dlopen(libjlipath16, RTLD_LAZY | RTLD_GLOBAL);
    if (!libjli) {
        debugLog("[Init] Can't load %s, trying %s", libjlipath16, libjlipath8);
        setenv("INTERNAL_JLI_PATH", libjlipath8, 1);
        libjli = dlopen(libjlipath8, RTLD_LAZY | RTLD_GLOBAL);
        if (!libjli) {
            debugLog("[Init] JLI lib = NULL: %s", dlerror());
            return -1;
        }

        // Setup Caciocavallo
        margv[++margc] = "-Djava.awt.headless=false";
        margv[++margc] = "-Dcacio.font.fontmanager=sun.awt.X11FontManager";
        margv[++margc] = "-Dcacio.font.fontscaler=sun.font.FreetypeFontScaler";
        margv[++margc] = "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel";
        margv[++margc] = "-Dawt.toolkit=net.java.openjdk.cacio.ctc.CTCToolkit";
        margv[++margc] = "-Djava.awt.graphicsenv=net.java.openjdk.cacio.ctc.CTCGraphicsEnvironment";

        // Generate Caciocavallo bootclasspath
        char cacio_libs_path[2048];
        char cacio_classpath[8192];
        sprintf((char*) cacio_libs_path, "%s/libs_caciocavallo", getenv("BUNDLE_PATH"));
        cplen = sprintf(cacio_classpath, "-Xbootclasspath/p");
        d = opendir(cacio_libs_path);
        int skip = 2;
        if (d) {
            while ((dir = readdir(d)) != NULL) {
                if (skip > 0) {
                    --skip;
                    continue;
                }
                cplen += sprintf(cacio_classpath + cplen, ":%s/%s", cacio_libs_path, dir->d_name);
            }
            closedir(d);
        }
        margv[++margc] = cacio_classpath;
    } else {
        margv[++margc] = "--add-opens=java.base/java.net=ALL-UNNAMED";

        // TODO: workaround, will be removed once the startup part works without PLaunchApp
        margv[++margc] = "--add-exports=cpw.mods.bootstraplauncher/cpw.mods.bootstraplauncher=ALL-UNNAMED";
    }

    if ([launchTarget isKindOfClass:NSDictionary.class]) {
        for (NSString *arg in launchTarget[@"arguments"][@"jvm_processed"]) {
            margv[++margc] = (char *)arg.UTF8String;
        }
    }

    init_loadCustomJvmFlags();
    regLog("[Init] Found JLI lib");

    margv[++margc] = "-cp";
    margv[++margc] = classpath;
    margv[++margc] = "net.kdt.pojavlaunch.PojavLauncher";

    if (username == nil) {
        margv[++margc] = ".LaunchJAR";
    } else {
        margv[++margc] = (char *)username.UTF8String;
    }
    if ([launchTarget isKindOfClass:NSDictionary.class]) {
        margv[++margc] = (char *)[launchTarget[@"id"] UTF8String];
    } else {
        margv[++margc] = (char *)[launchTarget UTF8String];
    }
    margv[++margc] = (char *)[NSString stringWithFormat:@"%dx%d", width, height].UTF8String;

    pJLI_Launch = (JLI_Launch_func *)dlsym(libjli, "JLI_Launch");
          
    if (NULL == pJLI_Launch) {
        regLog("[Init] JLI_Launch = NULL");
        return -2;
    }

    regLog("[Init] Calling JLI_Launch");

/*
    for (int i = 0; i < margc; i++) {
        debugLog("Arg=%s", margv[i]);
    }
*/

    return pJLI_Launch(++margc, margv,
                   0, NULL, // sizeof(const_jargs) / sizeof(char *), const_jargs,
                   0, NULL, // sizeof(const_appclasspath) / sizeof(char *), const_appclasspath,
                   // PojavLancher: fixme: are these wrong?
                   "1.8.0-internal",
                   "1.8",

                   "java", "openjdk",
                   /* (const_jargs != NULL) ? JNI_TRUE : */ JNI_FALSE,
                   JNI_TRUE, JNI_FALSE, JNI_TRUE);
}
