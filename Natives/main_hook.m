#import <Foundation/Foundation.h>

#include "external/fishhook/fishhook.h"

static void* (*orig_dlopen)(const char* path, int mode);

void* hooked_dlopen(const char* path, int mode) {
    // Load our libawt_xawt
    if (path && [@(path) hasSuffix:@"/libawt_xawt.dylib"]) {
        return orig_dlopen([NSString stringWithFormat:@"%s/Frameworks/libawt_xawt.dylib", getenv("BUNDLE_PATH")].UTF8String, mode);
    }

    return orig_dlopen(path, mode);

}

void init_hookFunctions() {
    int retval = rebind_symbols((struct rebinding[1]){
        {"dlopen", hooked_dlopen, (void *)&orig_dlopen},
    }, 1);
    NSLog(@"hook retval = %d", retval);
}
