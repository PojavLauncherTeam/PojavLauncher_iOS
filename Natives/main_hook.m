#import <Foundation/Foundation.h>
#import "SurfaceViewController.h"
#import "utils.h"

#include "external/fishhook/fishhook.h"

void (*orig_abort)();
static void* (*orig_dlopen)(const char* path, int mode);
static void (*orig_exit)(int code);
static int (*orig_open)(const char *path, int oflag, ...);

void handle_fatal_exit(int code) {
    if (NSThread.isMainThread || !SurfaceViewController.isRunning) {
        return;
    }

    [SurfaceViewController handleExitCode:code];

    if (fatalExitGroup != nil) {
        // Likely other threads are crashing, put them to sleep
        sleep(INT_MAX);
    }
    fatalExitGroup = dispatch_group_create();
    dispatch_group_enter(fatalExitGroup);
    dispatch_group_wait(fatalExitGroup, DISPATCH_TIME_FOREVER);
}

void hooked_abort() {
    NSLog(@"abort() called");
    handle_fatal_exit(SIGABRT);
    orig_abort();
}

void* hooked_dlopen(const char* path, int mode) {
    if (path && [@(path) hasSuffix:@"/libawt_xawt.dylib"]) {
        return orig_dlopen([NSString stringWithFormat:@"%s/Frameworks/libawt_xawt.dylib", getenv("BUNDLE_PATH")].UTF8String, mode);
    }

    return orig_dlopen(path, mode);
}

void hooked_exit(int code) {
    NSLog(@"exit(%d) called", code);
    if (code == 0) {
        orig_exit(code);
        return;
    }
    handle_fatal_exit(code);

    if (runtimeJavaVMPtr != NULL) {
        (*runtimeJavaVMPtr)->DestroyJavaVM(runtimeJavaVMPtr);
    }

    orig_exit(code);
}

int hooked_open(const char *path, int oflag, ...) {
    va_list args;
    va_start(args, oflag);
    mode_t mode = va_arg(args, int);
    va_end(args);
    if (path && !strcmp(path, "/etc/resolv.conf")) {
        return orig_open([NSString stringWithFormat:@"%s/resolv.conf", getenv("POJAV_HOME")].UTF8String, oflag, mode);
    }

    return orig_open(path, oflag, mode);
}

void init_hookFunctions() {
    if (getenv("POJAV_PREFER_EXTERNAL_JRE")) {
        // In this environment, libawt_xawt is not available/X11 only.
        // hook dlopen to use our libawt_xawt
        rebind_symbols((struct rebinding[1]){{"dlopen", hooked_dlopen, (void *)&orig_dlopen}}, 1);
    }
    rebind_symbols((struct rebinding[3]){
        {"abort", hooked_abort, (void *)&orig_abort},
        {"exit", hooked_exit, (void *)&orig_exit},
        {"open", hooked_open, (void *)&orig_open}
    }, 3);
}
