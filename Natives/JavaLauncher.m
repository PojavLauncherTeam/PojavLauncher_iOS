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

#include <sys/stat.h>
#include <sys/types.h>

#include "jni.h"
#include "log.h"
#include "utils.h"
#include "JavaLauncher.h"

#import "LauncherPreferences.h"

// PojavLancher: fixme: are these wrong?
#define FULL_VERSION "1.8.0-internal"
#define DOT_VERSION "1.8"

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

static int margc = 0;
static char* margv[1000];
static int pfd[2];
static pthread_t logger;

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
    for (NSString *jvmarg in [jvmargs componentsSeparatedByString:@" -"]) {
        if ([jvmarg length] == 0) continue;
        margv[margc] = (char *) [jvmarg UTF8String];
        NSLog(@"[Pre-init] Added custom JVM flag: %@", jvmarg);
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


int launchJVM(int argc, char *argv[]) {
    char *homeDir;
    if (!started) {
        setenv("BUNDLE_PATH", dirname(argv[0]), 1);

        // Are we running on a jailbroken environment?
        if (strncmp(argv[0], "/Applications", 13) == 0) {
            setenv("HOME", "/var/mobile", 1);
            homeDir = "/var/mobile/Documents/.pojavlauncher";
        } else {
            char pojavHome[2048];
            sprintf(pojavHome, "%s/Documents", getenv("HOME"));
            homeDir = (char *) pojavHome;
        }
        setenv("POJAV_HOME", homeDir, 1);
    } else {
        homeDir = getenv("POJAV_HOME");
    }

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
        int ret;
        char newname[2048];
        sprintf(newname, "%s/latestlog.old.txt", homeDir);
        ret = rename(log_path, newname);
        FILE* logFile = fopen(log_path, "w");
        if (!logFile) {
            debug("[Pre-init] Error: failed to open %s: %s", log_path, strerror(errno));
            assert(0 && "Failed to open latestlog.txt. Check oslog for more details.");
        }
        int log_fd = fileno(logFile);
        dup2(log_fd, 1);
        dup2(log_fd, 2);
        close(log_fd);
    }

    debug("[Pre-init] Beginning JVM launch\n");
    // setenv("LIBGL_FB", "2", 1);
    setenv("LIBGL_MIPMAP", "3", 1);

    // Fix white color on banner and sheep, since GL4ES 1.1.5
    setenv("LIBGL_NORMALIZE", "1", 1);

    init_loadCustomEnv();

    char *javaHome = getenv("JAVA_HOME");
    if (!javaHome) {
        if (strncmp(argv[0], "/Applications", 13) == 0) {
            javaHome = "/usr/lib/jvm/java-16-openjdk";
        } else {
            javaHome = calloc(1, 2048);
            sprintf(javaHome, "%s/jre8", getenv("BUNDLE_PATH"));
        }
        setenv("JAVA_HOME", javaHome, 1);
        debug("[Pre-init] JAVA_HOME environment variable not set. Defaulting to %s\n", javaHome);
    }

    char controlPath[2048];
    sprintf(controlPath, "%s/controlmap", homeDir);
    mkdir(controlPath, S_IRWXU | S_IRWXG | S_IRWXO);
    setenv("POJAV_PATH_CONTROL", controlPath, 1);

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

    // Check if JVM restarts
    if (!started) {
        char *frameworkPath = calloc(1, 2048);
        char *javaPath = calloc(1, 2048);
        char *userDir = calloc(1, 2048);
        char *userHome = calloc(1, 2048);
        snprintf(frameworkPath, 2048, "-Djava.library.path=%s/Frameworks", getenv("BUNDLE_PATH"));
        snprintf(javaPath, 2048, "%s/bin/java", javaHome);
        snprintf(userDir, 2048, "-Duser.dir=%s/Documents/minecraft", getenv("HOME"));
        snprintf(userHome, 2048, "-Duser.home=%s/Documents", getenv("HOME"));
        
        chdir(userDir);
        
        margv[margc++] = javaPath;
        margv[margc++] = "-XstartOnFirstThread";
        margv[margc++] = "-Djava.system.class.loader=net.kdt.pojavlaunch.PojavClassLoader";
        margv[margc++] = frameworkPath;
        margv[margc++] = userDir;
        margv[margc++] = userHome;
        margv[margc++] = "-Dorg.lwjgl.opengl.libname=libgl4es_114.dylib";
        margv[margc++] = "-Dorg.lwjgl.system.allocator=system";

        init_loadCustomJvmFlags();
    } else {
        // Locate gl4es library name:
        // Reverse the loop, since it is overridable.
        // FIXME: broken!
/*
        char* opengl_prefix = "-Dorg.lwjgl.opengl.libname=";
        for (int i = argc - 1; i >= 0; i--) {
            if (strncmp(opengl_prefix, argv[i], strlen(opengl_prefix)) == 0) {
                strtok(argv[i], "=");
                setenv("POJAV_OPENGL_LIBNAME", strtok(NULL, "="), 1);
                break;
            }
        }
*/
        setenv("POJAV_OPENGL_LIBNAME", "libgl4es_114.dylib", 1);

        debug("[Pre-init] OpenGL library name: %s", getenv("POJAV_OPENGL_LIBNAME"));
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
            margv[margc++] = "-Djava.awt.headless=true";
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

    debug("[Init] Calling JLI_Launch");

    for (int i = 0; i < margc; i++) {
        debug("arg[%d] = %s", i, margv[i]);
    }

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
