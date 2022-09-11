#import <Foundation/Foundation.h>

#include "external/fishhook/fishhook.h"

static void* (*orig_dlopen)(const char* path, int mode);
static int (*orig_open)(const char *path, int oflag, ...);

void* hooked_dlopen(const char* path, int mode) {
    if (path && [@(path) hasSuffix:@"/libawt_xawt.dylib"]) {
        return orig_dlopen([NSString stringWithFormat:@"%s/Frameworks/libawt_xawt.dylib", getenv("BUNDLE_PATH")].UTF8String, mode);
    }

    return orig_dlopen(path, mode);
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
    rebind_symbols((struct rebinding[1]){{"open", hooked_open, (void *)&orig_open}}, 1);
}
