#include <dirent.h>
#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <spawn.h>

#include <sys/stat.h>
#include <sys/types.h>

#include "jni.h"
#include "log.h"
#include "utils.h"
#include "JavaLauncher.h"

// PojavLancher: fixme: are these wrong?
#define FULL_VERSION "1.16.0-internal"
#define DOT_VERSION "1.16"

static const char *java_libs_dir = "/Applications/PojavLauncher.app/libs";
static const char *args_path = "/var/mobile/Documents/.pojavlauncher/overrideargs.txt";
static const char *log_path = "/var/mobile/Documents/.pojavlauncher/latestlog.txt";

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

void init_loadCustomEnv() {
    FILE *envFile = fopen("/var/mobile/Documents/.pojavlauncher/custom_env.txt", "r");

    debug("[Pre-init] Reading custom environment variables (custom_env.txt), opened=%d\n", envFile != NULL);

    if (envFile) {
        char *line = NULL;
        size_t len = 0;
        ssize_t read;
        while ((read = getline(&line, &len, envFile)) != -1) {
            if (read == 0 || line[0] == '#') return;
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
    char jvmargs[10000];
    FILE* argsFile = fopen(args_path, "r");
    debug("[Pre-init] Reading custom JVM args (overrideargs.txt), opened=%d\n", argsFile != NULL);
    if (argsFile) {
        if (!fgets(jvmargs, 10000, argsFile)) {
            debug("[Pre-init] Warning: could not read overrideargs.txt");
            fclose(argsFile);
            return;
        }
        char *pch;
        pch = strtok(jvmargs, " ");
        while (pch != NULL) {
            margv[margc] = (char*)malloc((strlen(pch)+1) * sizeof(char));
            strcpy(margv[margc], pch);
            debug("[Pre-init] Added custom flag: %s", margv[margc]);
            pch = strtok(NULL, " ");
            ++margc;
        }
        fclose(argsFile);
    }
}

int launchJVM(int argc, char *argv[]) {
    if (!started) {
        debug("[Pre-init] Staring logging STDIO as jrelog:V\n");
        // Redirect stdio to latestlog.txt
        FILE* logFile = fopen(log_path, "w");
        int log_fd = fileno(logFile);
        dup2(log_fd, 1);
        dup2(log_fd, 2);
        close(log_fd);
    }

    debug("[Pre-init] Beginning JVM launch\n");
    // setenv("LIBGL_FB", "2", 1);
    setenv("LIBGL_MIPMAP", "3", 1);
    setenv("LIBGL_NORMALIZE", "1", 1);
    setenv("MESA_GL_VERSION_OVERRIDE", "4.6", 1);
    
    init_loadCustomEnv();
    
    mkdir("/var/mobile/Documents/.pojavlauncher/controlmap", S_IRWXU | S_IRWXG | S_IRWXO);
    chdir("/var/mobile/Documents/minecraft");

    char classpath[10000];
    
    // "/Applications/PojavLauncher.app/libs/launcher.jar:/Applications/PojavLauncher.app/libs/ExagearApacheCommons.jar:/Applications/PojavLauncher.app/libs/gson-2.8.6.jar:/Applications/PojavLauncher.app/libs/jsr305.jar:/Applications/PojavLauncher.app/libs/lwjgl3-minecraft.jar";
    
    // Generate classpath
    DIR *d;
    struct dirent *dir;
    d = opendir(java_libs_dir);
    int cplen = 0;
    if (d) {
        // cplen += sprintf(classpath + cplen, "-Xbootclasspath/a:");
        while ((dir = readdir(d)) != NULL) {
            cplen += sprintf(classpath + cplen, "%s/%s:", java_libs_dir, dir->d_name);
        }
        closedir(d);
    }
    debug("[Pre-init] Classpath generated: %s", classpath);

    // Check if JVM restarts
    if (!started) {
        margv[margc++] = "/usr/lib/jvm/java-16-openjdk/bin/java";
        margv[margc++] = "-XstartOnFirstThread";
        margv[margc++] = "-Djava.system.class.loader=net.kdt.pojavlaunch.PojavClassLoader";
        margv[margc++] = "-Djava.library.path=/Applications/PojavLauncher.app/Frameworks:/Applications/PojavLauncher.app/mesa_lib/lib";
        margv[margc++] = "-Duser.dir=/var/mobile/Documents/minecraft";
        margv[margc++] = "-Duser.home=/var/mobile/Documents";
        margv[margc++] = "-Dorg.lwjgl.opengl.libname=libOSMesaOverride.dylib";
        margv[margc++] = "-Dorg.lwjgl.system.allocator=system";

        init_loadCustomJvmFlags();

        margv[margc++] = "-cp";
        margv[margc++] = classpath;
        margv[margc++] = "net.kdt.pojavlaunch.PLaunchApp";
        
        for (int i = 0; i < argc; i++) {
            margv[margc++] = argv[i];
        }
    } else {
        // Locate gl4es library name:
        // Reverse the loop, since it is overridable.
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
    void* libjli = dlopen("/usr/lib/jvm/java-16-openjdk/lib/libjli.dylib", RTLD_LAZY | RTLD_GLOBAL);

    if (NULL == libjli) {
        debug("[Init] JLI lib = NULL: %s", dlerror());
        return -1;
    }
    debug("[Init] Found JLI lib");

    JLI_Launch_func *pJLI_Launch =
          (JLI_Launch_func *)dlsym(libjli, "JLI_Launch");
          
    if (NULL == pJLI_Launch) {
        debug("[Init] JLI_Launch = NULL");
        return -2;
    }

    debug("[Init] Calling JLI_Launch");
    
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
