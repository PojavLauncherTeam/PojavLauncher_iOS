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

#include "utils.h"

#import "ios_uikit_bridge.h"
#import "JavaLauncher.h"
#import "LauncherPreferences.h"

#define fm NSFileManager.defaultManager

extern char **environ;

static int margc = -1;
static const char* margv[1000];

void init_loadCustomEnv() {
    /* Define default env */

    // Silent Caciocavallo NPE error in locating Android-only lib
    setenv("LD_LIBRARY_PATH", "", 1);

    // Ignore mipmap for performance(?)
    setenv("LIBGL_MIPMAP", "3", 1);

    // Disable overloaded functions hack for Minecraft 1.17+
    setenv("LIBGL_NOINTOVLHACK", "1", 1);

    // Fix white color on banner and sheep, since GL4ES 1.1.5
    setenv("LIBGL_NORMALIZE", "1", 1);

    // Override OpenGL version to 4.1 for Zink
    setenv("MESA_GL_VERSION_OVERRIDE", "4.1", 1);

    // Runs JVM in a separate thread
    setenv("HACK_IGNORE_START_ON_FIRST_THREAD", "1", 1);

    /* Load custom env */
    NSString *envFile = [NSString stringWithFormat:@"%s/custom_env.txt", getenv("POJAV_HOME")];
    NSString *linesStr = [NSString stringWithContentsOfFile:envFile
        encoding:NSUTF8StringEncoding error:nil];
    if (linesStr == nil) return;
    NSLog(@"[Pre-init] Reading custom environment variables (custom_env.txt)");

    NSArray *lines = [linesStr componentsSeparatedByCharactersInSet:
        NSCharacterSet.newlineCharacterSet];

    for (NSString *line in lines) {
        if (line.length == 0 || [line hasPrefix:@"#"]) {
            continue;
        } else if (![line containsString:@"="]) {
            NSLog(@"[Pre-init] Warning: skipped empty value custom env: %@", line);
            continue;
        }
        NSRange range = [line rangeOfString:@"="];
        NSString *key = [line substringToIndex:range.location];
        NSString *value = [line substringFromIndex:range.location+range.length];
        setenv(key.UTF8String, value.UTF8String, 1);
        NSLog(@"[Pre-init] Added custom env: %@", line);
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
            margv[margc] = jvmarg.UTF8String;
        } else {
            margv[margc] = [@"-" stringByAppendingString:jvmarg].UTF8String;
        }

        NSLog(@"[JavaLauncher] Added custom JVM flag: %s", margv[margc]);
    }
}

NSString* environmentFailsafes(int minVersion) {
    NSString *jvmPath = [NSString stringWithFormat:@"%s/java_runtimes", getenv("POJAV_PREFER_EXTERNAL_JRE") ? getenv("POJAV_HOME") : getenv("BUNDLE_PATH")];
    NSString *javaHome = nil;

    NSString *jre8Path = [NSString stringWithFormat:@"%@/java-8-openjdk", jvmPath];
    NSString *jre17Path = [NSString stringWithFormat:@"%@/java-17-openjdk", jvmPath];

    if ([fm fileExistsAtPath:jre8Path] && minVersion <= 8) {
        javaHome = jre8Path;
    } else if ([fm fileExistsAtPath:jre17Path] && minVersion <= 17) {
        javaHome = jre17Path;
    }

    if (javaHome == nil) {
        showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Minecraft %@ requires Java %d in order to run. Please install it first.", getPreference(@"selected_version"), minVersion]);
    }

    return javaHome;
}

int launchJVM(NSString *username, id launchTarget, int width, int height, int minVersion) {
    init_loadCustomEnv();

    NSString *librariesPath = [NSString stringWithFormat:@"%s/libs", getenv("BUNDLE_PATH")];

    NSLog(@"[JavaLauncher] Beginning JVM launch");

    NSString *javaHome = getPreference(@"java_home");
    if (![javaHome hasPrefix:@"/"]) {
        javaHome = [NSString stringWithFormat:@"%s/java_runtimes/%@", getenv("POJAV_PREFER_EXTERNAL_JRE") ? getenv("POJAV_HOME") : getenv("BUNDLE_PATH"), javaHome];
    }

    // We handle unset JAVA_HOME right there
    if (getSelectedJavaVersion() < minVersion) {
        NSLog(@"[JavaLauncher] Attempting to change to Java %d (actual might be higher)", minVersion);
        javaHome = environmentFailsafes(minVersion);
        NSLog(@"[JavaLauncher] JAVA_HOME is now set to %@", javaHome);
    } /* else if (javaHome.length == 0) {
        javaHome_pre = environmentFailsafes(minVersion);
        setPreference(@"java_home", javaHome);
        NSLog(@"[JavaLauncher] JAVA_HOME environment variable was not set. Default to %@ for future use.\n", javaHome);
    } */ else {
        if (![fm fileExistsAtPath:javaHome]) {
            javaHome = environmentFailsafes(minVersion);
            setPreference(@"java_home", javaHome);
            NSLog(@"[JavaLauncher] Failed to locate %@. Restored default value for JAVA_HOME.", javaHome);
        } else {
            NSLog(@"[JavaLauncher] Restored preference: JAVA_HOME is set to %@\n", javaHome);
        }
    }

    if (javaHome == nil) {
        return 1;
    }

    setenv("JAVA_HOME", javaHome.UTF8String, 1);

    NSString *renderer = getPreference(@"renderer");
    if (renderer.length == 0) {
        renderer = @"auto";
        setPreference(@"renderer", renderer);
        NSLog(@"[JavaLauncher] RENDERER environment variable was not set. Defaulting to %@ for future use.\n", renderer);
    } else {
        NSLog(@"[JavaLauncher] Restored preference: RENDERER is set to %@\n", renderer);
    }
    setenv("POJAV_RENDERER", renderer.UTF8String, 1);
    
    int allocmem;
    if ([getPreference(@"auto_ram") boolValue]) {
        CGFloat autoRatio = getEntitlementValue(@"com.apple.private.memorystatus") ? 0.4 : 0.25;
        allocmem = roundf((NSProcessInfo.processInfo.physicalMemory / 1048576) * autoRatio);
    } else {
        allocmem = [getPreference(@"allocated_memory") intValue];
    }
    NSLog(@"[JavaLauncher] Max RAM allocation is set to %d MB", allocmem);

    margv[++margc] = [NSString stringWithFormat:@"%@/bin/java", javaHome].UTF8String;
    margv[++margc] = "-XstartOnFirstThread";
    margv[++margc] = "-Djava.system.class.loader=net.kdt.pojavlaunch.PojavClassLoader";
    margv[++margc] = "-Xms128M";
    margv[++margc] = [NSString stringWithFormat:@"-Xmx%dM", allocmem].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-Djava.library.path=%1$s/Frameworks", getenv("BUNDLE_PATH")].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-Djna.boot.library.path=%s/Frameworks", getenv("BUNDLE_PATH")].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-Duser.dir=%s", getenv("POJAV_GAME_DIR")].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-Duser.home=%s", getenv("POJAV_HOME")].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-Duser.timezone=%@", NSTimeZone.localTimeZone.name].UTF8String;
    margv[++margc] = [NSString stringWithFormat:@"-DUIScreen.maximumFramesPerSecond=%d", (int)UIScreen.mainScreen.maximumFramesPerSecond].UTF8String;
    margv[++margc] = "-Dorg.lwjgl.system.allocator=system";
    margv[++margc] = "-Dlog4j2.formatMsgNoLookups=true";
    if([getPreference(@"cosmetica") boolValue]) {
        margv[++margc] = [NSString stringWithFormat:@"-javaagent:%@/arc_dns_injector.jar=23.95.137.176", librariesPath].UTF8String;
    }

    // Setup Caciocavallo
    margv[++margc] = "-Djava.awt.headless=false";
    margv[++margc] = "-Dcacio.font.fontmanager=sun.awt.X11FontManager";
    margv[++margc] = "-Dcacio.font.fontscaler=sun.font.FreetypeFontScaler";

    // Disable Forge 1.16.x early progress window
    margv[++margc] = "-Dfml.earlyprogresswindow=false";

    // Load java
    NSString *libjlipath8 = [NSString stringWithFormat:@"%@/lib/jli/libjli.dylib", javaHome]; // java 8
    NSString *libjlipath11 = [NSString stringWithFormat:@"%@/lib/libjli.dylib", javaHome]; // java 11+
    setenv("INTERNAL_JLI_PATH", libjlipath11.UTF8String, 1);
    BOOL isJava8;
    void* libjli = dlopen(libjlipath11.UTF8String, RTLD_GLOBAL);
    isJava8 = libjli == NULL;
    if (!libjli) {
        NSDebugLog(@"[Init] Can't load %@ (%s), trying %@", libjlipath11, dlerror(), libjlipath8);
        setenv("INTERNAL_JLI_PATH", libjlipath8.UTF8String, 1);
        libjli = dlopen(libjlipath8.UTF8String, RTLD_GLOBAL);
        if (!libjli) {
            NSLog(@"[Init] JLI lib = NULL: %s", dlerror());
            return -1;
        }

        // Setup Caciocavallo
        margv[++margc] = "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel";
        margv[++margc] = "-Dawt.toolkit=net.java.openjdk.cacio.ctc.CTCToolkit";
        margv[++margc] = "-Djava.awt.graphicsenv=net.java.openjdk.cacio.ctc.CTCGraphicsEnvironment";
    } else {
        // Required by Cosmetica to inject DNS
        margv[++margc] = "--add-opens=java.base/java.net=ALL-UNNAMED";

        // Setup Caciocavallo
        margv[++margc] = "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel";
        margv[++margc] = "-Dawt.toolkit=com.github.caciocavallosilano.cacio.ctc.CTCToolkit";
        margv[++margc] = "-Djava.awt.graphicsenv=com.github.caciocavallosilano.cacio.ctc.CTCGraphicsEnvironment";

        // Required by Caciocavallo17 to access internal API
        margv[++margc] = "--add-exports=java.desktop/java.awt=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/java.awt.peer=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.java2d=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/java.awt.dnd.peer=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.awt=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.awt.event=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.awt.datatransfer=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.desktop/sun.font=ALL-UNNAMED";
        margv[++margc] = "--add-exports=java.base/sun.security.action=ALL-UNNAMED";
        margv[++margc] = "--add-opens=java.base/java.util=ALL-UNNAMED";
        margv[++margc] = "--add-opens=java.desktop/java.awt=ALL-UNNAMED";
        margv[++margc] = "--add-opens=java.desktop/sun.font=ALL-UNNAMED";
        margv[++margc] = "--add-opens=java.desktop/sun.java2d=ALL-UNNAMED";
        margv[++margc] = "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED";

        // TODO: workaround, will be removed once the startup part works without PLaunchApp
        margv[++margc] = "--add-exports=cpw.mods.bootstraplauncher/cpw.mods.bootstraplauncher=ALL-UNNAMED";
    }

    // Add Caciocavallo bootclasspath
    NSString *cacio_classpath = [NSString stringWithFormat:@"-Xbootclasspath/%s", isJava8 ? "p" : "a"];
    NSString *cacio_libs_path = [NSString stringWithFormat:@"%s/libs_caciocavallo%s", getenv("BUNDLE_PATH"), isJava8 ? "" : "17"];
    NSArray *files = [fm contentsOfDirectoryAtPath:cacio_libs_path error:nil];
    for(NSString *file in files) {
        if ([file hasSuffix:@".jar"]) {
            cacio_classpath = [NSString stringWithFormat:@"%@:%@/%@", cacio_classpath, cacio_libs_path, file];
        }
    }
    margv[++margc] = cacio_classpath.UTF8String;

    if (UIDevice.currentDevice.systemVersion.floatValue < 14 ||
        !getEntitlementValue(@"com.apple.developer.kernel.extended-virtual-addressing")) {
        // In jailed environment, where extended virtual addressing entitlement isn't
        // present (for free dev account), allocating compressed space fails.
        // FIXME: does extended VA allow allocating compressed class space?
        margv[++margc] = "-XX:-UseCompressedClassPointers";
    }

    if ([launchTarget isKindOfClass:NSDictionary.class]) {
        for (NSString *arg in launchTarget[@"arguments"][@"jvm_processed"]) {
            margv[++margc] = arg.UTF8String;
        }
    }

    init_loadCustomJvmFlags();
    NSLog(@"[Init] Found JLI lib");

    margv[++margc] = "-cp";
    margv[++margc] = [NSString stringWithFormat:@"%@/*", librariesPath].UTF8String;
    margv[++margc] = "net.kdt.pojavlaunch.PojavLauncher";

    if (username == nil) {
        margv[++margc] = ".LaunchJAR";
    } else {
        margv[++margc] = username.UTF8String;
    }
    if ([launchTarget isKindOfClass:NSDictionary.class]) {
        margv[++margc] = [launchTarget[@"id"] UTF8String];
    } else {
        margv[++margc] = [launchTarget UTF8String];
    }
    margv[++margc] = [NSString stringWithFormat:@"%dx%d", width, height].UTF8String;

    pJLI_Launch = (JLI_Launch_func *)dlsym(libjli, "JLI_Launch");
          
    if (NULL == pJLI_Launch) {
        NSLog(@"[Init] JLI_Launch = NULL");
        return -2;
    }

    NSLog(@"[Init] Calling JLI_Launch");

    // Cr4shed known issue: exit after crash dump,
    // reset signal handler so that JVM can catch them
    signal(SIGSEGV, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGFPE, SIG_DFL);

    return pJLI_Launch(++margc, margv,
                   0, NULL, // sizeof(const_jargs) / sizeof(char *), const_jargs,
                   0, NULL, // sizeof(const_appclasspath) / sizeof(char *), const_appclasspath,
                   // These values are ignoree in Java 17, so keep it anyways
                   "1.8.0-internal",
                   "1.8",

                   "java", "openjdk",
                   /* (const_jargs != NULL) ? JNI_TRUE : */ JNI_FALSE,
                   JNI_TRUE, JNI_FALSE, JNI_TRUE);
}
