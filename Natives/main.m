#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <spawn.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "customcontrols/CustomControlsUtils.h"
#import "LauncherPreferences.h"

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
#include "codesign.h"

#define CS_PLATFORM_BINARY 0x4000000
#define PT_TRACE_ME 0
int ptrace(int, pid_t, caddr_t, int);
#define fm NSFileManager.defaultManager
extern char** environ;

void printEntitlementAvailability(NSString *key) {
    NSLog(@"[Pre-Init] - %@: %@", key, getEntitlementValue(key) ? @"YES" : @"NO");
}

bool init_checkForsubstrated() {
    // Please kindly tell pwn20wnd that he sucks
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    do {
        size += size / 10;
        newprocess = realloc(process, size);
        if (!newprocess){
            if (process){
                free(process);
            }
            return nil;
        }
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    if (st == 0){
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            if (nprocess){
                for (int i = nprocess - 1; i >= 0; i--){
                    if(strcmp(process[i].kp_proc.p_comm,"substrated") == 0) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

void init_checkForJailbreak() {
    bool jbDyld = false;
    bool jbFlag = true;
    bool jbProc = init_checkForsubstrated();
    
    int imageCount = _dyld_image_count();
    uint32_t flags = CS_PLATFORM_BINARY;
    
    for (int i=0; i < imageCount; i++) {
        if (strcmp(_dyld_get_image_name(i),"/usr/lib/pspawn_payload-stg2.dylib") == 0) {
            jbDyld = true;
        } else {
            jbDyld = false;
        }
    }
    if (csops(0, CS_OPS_STATUS, &flags, sizeof(flags)) != -1) {
        if ((flags & CS_PLATFORM_BINARY) == 0) {
            jbFlag = false;
        } else {
            jbFlag = true;
        }
    }
    
    if (jbDyld || jbFlag || jbProc) {
        setenv("POJAV_DETECTEDJB", "1", 1);
    }
}

void init_logDeviceAndVer(char *argument) {
    // Hardware + Software
    struct utsname systemInfo;
    uname(&systemInfo);
    const char *deviceHardware = systemInfo.machine;
    const char *deviceSoftware = [[[UIDevice currentDevice] systemVersion] cStringUsingEncoding:NSUTF8StringEncoding];
    
    // PojavLauncher version
    regLog("[Pre-Init] PojavLauncher version: %s, branch: %s, commit: %s", CONFIG_TYPE, CONFIG_BRANCH, CONFIG_COMMIT);

    setenv("POJAV_DETECTEDHW", deviceHardware, 1);
    setenv("POJAV_DETECTEDSW", deviceSoftware, 1);
    
    NSString *tsPath = [NSString stringWithFormat:@"%s/../_TrollStore", getenv("BUNDLE_PATH")];
    const char *type = "Unjailbroken";
    if ([fm fileExistsAtPath:tsPath]) {
        type = "TrollStore";
    } else if (getenv("POJAV_DETECTEDJB")) {
        type = "Jailbroken";
    }
    regLog("[Pre-Init] %s with iOS %s (%s)", deviceHardware, deviceSoftware, type);
    
    NSString *jvmPath = [NSString stringWithFormat:@"%s/jvm", getenv("BUNDLE_PATH")];
    if (![fm fileExistsAtPath:jvmPath]) {
        setenv("POJAV_PREFER_EXTERNAL_JRE", "1", 1);
    }
    
    regLog("[Pre-init] Entitlements availability:");
    printEntitlementAvailability(@"com.apple.developer.kernel.extended-virtual-addressing");
    printEntitlementAvailability(@"com.apple.developer.kernel.increased-memory-limit");
    printEntitlementAvailability(@"com.apple.private.security.no-sandbox");
    printEntitlementAvailability(@"dynamic-codesigning");
}

void init_migrateDirIfNecessary() {
    NSString *oldDir = @"/usr/share/pojavlauncher";
    if ([fm fileExistsAtPath:oldDir]) {
        NSString *newDir = [NSString stringWithFormat:@"%s/Documents", getenv("HOME")];
        [fm moveItemAtPath:oldDir toPath:newDir error:nil];
        [fm removeItemAtPath:oldDir error:nil];
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

void init_setupAccounts() {
    NSString *controlPath = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"accounts"];
    [fm createDirectoryAtPath:controlPath withIntermediateDirectories:NO attributes:nil error:nil];
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

void init_setupResolvConf() {
    // Write known DNS servers to the config
    NSString *path = [NSString stringWithFormat:@"%s/resolv.conf", getenv("POJAV_HOME")];
    if (![fm fileExistsAtPath:path]) {
        [@"nameserver 8.8.8.8\n"
         @"nameserver 8.8.4.4"
        writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

int main(int argc, char * argv[]) {
    if (getppid() != 1) {
        NSLog(@"parent pid is not launchd, calling ptrace(PT_TRACE_ME)");
        // Child process can call to PT_TRACE_ME
        // then both parent and child processes get CS_DEBUGGED
        int ret = ptrace(PT_TRACE_ME, 0, 0, 0);
        return ret;
        // FIXME: how to kill the child process?
    }

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

    init_checkForJailbreak();
    
    init_migrateDirIfNecessary();

    setenv("BUNDLE_PATH", dirname(argv[0]), 1);
    setenv("HOME", [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
        .lastObject.path.stringByDeletingLastPathComponent.UTF8String, 1);
    // WARNING: THIS DIRECTS TO /var/mobile/Documents IF INSTALLED WITH APPSYNC UNIFIED
    setenv("POJAV_HOME", [NSString stringWithFormat:@"%s/Documents", getenv("HOME")].UTF8String, 1);

    [fm createDirectoryAtPath:@(getenv("POJAV_HOME")) withIntermediateDirectories:NO attributes:nil error:nil];

    init_redirectStdio();
    init_logDeviceAndVer(argv[0]);

    init_hookFunctions();

    loadPreferences(NO);
    init_setupResolvConf();
    init_setupMultiDir();
    init_setupLauncherProfiles();
    init_setupAccounts();
    init_setupCustomControls();

    init_migrateToPlist("selected_version", "config_ver.txt");
    init_migrateToPlist("java_args", "overrideargs.txt");

    // If sandbox is disabled, W^X JIT can be enabled by PojavLauncher itself
    if (getEntitlementValue(@"com.apple.private.security.no-sandbox")) {
        NSLog(@"[Pre-init] Sandbox is disabled, trying to enable JIT");
        int pid;
        int ret = posix_spawnp(&pid, argv[0], NULL, NULL, argv, environ);
        if (ret == 0) {
            // posix_spawn is successful, let's check if JIT is enabled
            int retries;
            for (retries = 0; retries < 10; retries++) {
                usleep(10000);
                if (isJITEnabled()) {
                    NSLog(@"[Pre-init] JIT has heen enabled with PT_TRACE_ME");
                    retries = -1;
                    break;
                }
            }
            if (retries != -1) {
                NSLog(@"[Pre-init] Failed to enable JIT: unknown reason");
            }
        } else {
            NSLog(@"[Pre-init] Failed to enable JIT: posix_spawn() failed errno %d", errno);
        }
    }

    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
