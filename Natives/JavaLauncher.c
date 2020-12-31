#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>

#include "jni.h"
#include "JavaLauncher.h"

// PojavLancher: fixme: are these wrong?
#define FULL_VERSION "1.16.0-internal"
#define DOT_VERSION "1.16"

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

void append(char* s, char* c) {
    int len;
    for (len = strlen(s); c[len] != '\0'; len++) {
        s[len] = c[len];
    }
    s[len+1] = '\0';
}

int launchJVM() {
    char documentDir[1000], log_path[1000], main_jar[1000], args_path[1000];
    append(documentDir, getenv("HOME"));
    append(documentDir, "/Documents");
    
    append(log_path, documentDir);
    append(log_path, "/latestlog.txt");

    append(args_path, documentDir);
    append(args_path, "/overrideargs.txt");

    append(main_jar, getenv("APPDIR");
    append(main_jar, "/launcher.jar");

    // Redirect stdio to latestlog.txt
    FILE* logFile = fopen(log_path, "w");
    int log_fd = fileno(logFile);
    dup2(log_fd, 1);
    dup2(log_fd, 2);
    close(log_fd);
    printf("Started logging STDIO as jrelog\n");
    
    int margv = 0;
    char* margc[1000];
    margc[margv++] = "/usr/lib/jvm/java-16-openjdk/bin/java";
    
    printf("Reading custom JVM args (overrideargs.txt)");
    char jvmargs[10000];
    FILE* argsFile = fopen(args_path, "r");
    if (argsFile) {
        fscanf(argsFile, "%s", jvmargs);
        char *pch;
        pch = strtok(jvmargs, " ");
        while (pch != NULL) {
            margc[margv++] = pch;
            pch = strtok(NULL, " ");
        }
        fclose(argsFile);
    }
    
    margc[margv++] = "-jar";
    margc[margv++] = main_jar;

    // Load java
    void* libjli = dlopen("/usr/lib/jvm/java-16-openjdk/lib/libjli.dylib", RTLD_LAZY | RTLD_GLOBAL);

    if (NULL == libjli) {
        printf("JLI lib = NULL: %s\n", dlerror());
        return -1;
    }
    printf("Found JLI lib\n");

    JLI_Launch_func *pJLI_Launch =
          (JLI_Launch_func *)dlsym(libjli, "JLI_Launch");
          
    if (NULL == pJLI_Launch) {
        printf("JLI_Launch = NULL\n");
        return -2;
    }

    printf("Calling JLI_Launch\n");

    return pJLI_Launch(margc, margv,
                   0, NULL, // sizeof(const_jargs) / sizeof(char *), const_jargs,
                   0, NULL, // sizeof(const_appclasspath) / sizeof(char *), const_appclasspath,
                   FULL_VERSION,
                   DOT_VERSION,
                   *margv, // (const_progname != NULL) ? const_progname : *margv,
                   *margv, // (const_launcher != NULL) ? const_launcher : *margv,
                   (const_jargs != NULL) ? JNI_TRUE : JNI_FALSE,
                   const_cpwildcard, const_javaw, const_ergo_class);
}
