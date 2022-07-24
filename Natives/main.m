#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "customcontrols/CustomControlsUtils.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"

#include <libgen.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>
#include "JavaLauncher.h"
#include "log.h"
#include "utils.h"

#if CONFIG_RELEASE == 1
# define CONFIG_TYPE "release"
#else
# define CONFIG_TYPE "debug"
#endif

#ifndef CONFIG_COMMIT
# define CONFIG_COMMIT unspecified
#endif

#define fm NSFileManager.defaultManager

void init_logDeviceAndVer(char *argument) {
    struct utsname systemInfo;
    uname(&systemInfo);
    // Hardware + software
    const char *deviceHardware = systemInfo.machine;
    const char *deviceSoftware = [[[UIDevice currentDevice] systemVersion] cStringUsingEncoding:NSUTF8StringEncoding];

    // Jailbreak
    const char *jbStrap;
    if (strncmp(argument, "/Applications", 13) == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/.procursus_strapped"]) {
            jbStrap = "Procursus";
        } else {
            jbStrap = "Other";
        }
        regLog("[Pre-Init] %s with iOS %s (%s)", deviceHardware, deviceSoftware, jbStrap);
    } else {
        regLog("[Pre-Init] %s with iOS %s", deviceHardware, deviceSoftware);
    }

    // PojavLauncher version
    regLog("[Pre-Init] PojavLauncher version: %s - %s", CONFIG_TYPE, CONFIG_COMMIT);

    setenv("POJAV_DETECTEDHW", deviceHardware, 1);
    setenv("POJAV_DETECTEDSW", deviceSoftware, 1);
    if (strncmp(argument, "/Applications", 13) == 0) {
        setenv("POJAV_DETECTEDJB", jbStrap, 1);
    }
}

void init_migrateDirIfNecessary() {
    NSString *completeFile = @"/var/mobile/Documents/.pojavlauncher/migration_complete";
    NSString *oldDir = @"/var/mobile/Documents/.pojavlauncher";
    if ([fm fileExistsAtPath:oldDir] && ![fm fileExistsAtPath:completeFile]) {
        NSString *newDir = @"/usr/share/pojavlauncher";
        if (@available(iOS 15, *)) {
            newDir = @"/private/preboot/procursus/usr/share/pojavlauncher";
        }

        [fm moveItemAtPath:oldDir toPath:newDir error:nil];
        [fm createSymbolicLinkAtPath:oldDir withDestinationPath:newDir error:nil];

        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"init.migrateDir", nil), newDir];
        [message writeToFile:completeFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
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

void init_redirectStdio() {
    regLog("[Pre-init] Starting logging STDIO to latestlog.txt\n");

    NSString *currName = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"latestlog.txt"];
    NSString *oldName = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"latestlog.old.txt"];
    [fm removeItemAtPath:oldName error:nil];
    [fm moveItemAtPath:currName toPath:oldName error:nil];

    [fm createFileAtPath:currName contents:nil attributes:nil];
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:currName];

    if (!file) {
        NSLog(@"[Pre-init] Error: failed to open %@", currName);
        assert(0 && "Failed to open latestlog.txt. Check oslog for more details.");
    }

    setvbuf(stdout, 0, _IOLBF, 0); // make stdout line-buffered
    setvbuf(stderr, 0, _IONBF, 0); // make stderr unbuffered

    /* create the pipe and redirect stdout and stderr */
    static int pfd[2];
    pipe(pfd);
    dup2(pfd[1], 1);
    dup2(pfd[1], 2);

    /* create the logging thread */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static BOOL filteredSessionID;
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
            [file writeData:[NSData dataWithBytes:buf length:rsize]];
            [file synchronizeFile];
        }
        [file closeFile];
    });
}

void init_setupCustomControls() {
    NSString *controlPath = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"controlmap"];
    [fm createDirectoryAtPath:controlPath withIntermediateDirectories:NO attributes:nil error:nil];
    generateAndSaveDefaultControl();
}

void init_setupLauncherProfiles() {
    NSString *file = [@(getenv("POJAV_GAME_DIR")) stringByAppendingPathComponent:@"launcher_profiles.json"];
    if (![fm fileExistsAtPath:file]) {
        NSDictionary *dict = @{
            @"profiles": @{
                @"(Default)": @{
                    @"name": @"(Default)",
                    @"lastVersionId": @"Unknown"
                }
            },
            @"selectedProfile": @"(Default)"
        };
        saveJSONToFile(dict, file);
    }
}

void init_setupMultiDir() {
    NSString *multidir = getPreference(@"game_directory");
    if (multidir.length == 0) {
        multidir = @"default";
        setPreference(@"game_directory", multidir);
        NSLog(@"[Pre-init] MULTI_DIR environment variable was not set. Defaulting to %@ for future use.\n", multidir);
    } else {
        NSLog(@"[Pre-init] Restored preference: MULTI_DIR is set to %@\n", multidir);
    }

    NSString *lasmPath = [NSString stringWithFormat:@"%s/Library/Application Support/minecraft", getenv("POJAV_HOME")]; //libr
    NSString *multidirPath = [NSString stringWithFormat:@"%s/instances/%@", getenv("POJAV_HOME"), multidir];

    [fm createDirectoryAtPath:multidirPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm removeItemAtPath:lasmPath error:nil];
    [fm createDirectoryAtPath:lasmPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createSymbolicLinkAtPath:lasmPath withDestinationPath:multidirPath error:nil];
    setenv("POJAV_GAME_DIR", lasmPath.UTF8String, 1);

    if (0 == access("/var/mobile/Documents/minecraft", F_OK)) {
        [fm moveItemAtPath:@"/var/mobile/Documents/minecraft" toPath:multidir error:nil];
        regLog("[Pre-init] Migrated old minecraft folder to new location.");
    }

    if (0 == access("/var/mobile/Documents/Library", F_OK)) {
        remove("/var/mobile/Documents/Library");
    }

    [fm changeCurrentDirectoryPath:lasmPath];
}

int main(int argc, char * argv[]) {
    if (pJLI_Launch) {
        return pJLI_Launch(argc, argv,
                   0, NULL, // sizeof(const_jargs) / sizeof(char *), const_jargs,
                   0, NULL, // sizeof(const_appclasspath) / sizeof(char *), const_appclasspath,
                   // PojavLancher: fixme: are these wrong?
                   "1.8.0-internal",
                   "1.8",

                   "java", "openjdk",
                   /* (const_jargs != NULL) ? JNI_TRUE : */ JNI_FALSE,
                   JNI_TRUE, JNI_FALSE, JNI_TRUE);
    }

    init_migrateDirIfNecessary();

    setenv("BUNDLE_PATH", dirname(argv[0]), 1);

    // Are we running on a jailbroken environment?
    if (strncmp(argv[0], "/Applications", 13) == 0) {
        setenv("HOME", "/usr/share", 1);
        setenv("OLD_POJAV_HOME", "/var/mobile/Documents/.pojavlauncher", 1);
        setenv("POJAV_HOME", "/usr/share/pojavlauncher", 1);
    } else {
        setenv("POJAV_HOME", [NSString stringWithFormat:@"%s/Documents", getenv("HOME")].UTF8String, 1);

        init_hookFunctions();
    }

    [fm createDirectoryAtPath:@(getenv("POJAV_HOME")) withIntermediateDirectories:NO attributes:nil error:nil];

    init_redirectStdio();
    init_logDeviceAndVer(argv[0]);

    loadPreferences();
    init_setupMultiDir();
    init_setupLauncherProfiles();

    init_setupCustomControls();

    init_migrateToPlist("selected_version", "config_ver.txt");
    init_migrateToPlist("java_args", "overrideargs.txt");

    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
