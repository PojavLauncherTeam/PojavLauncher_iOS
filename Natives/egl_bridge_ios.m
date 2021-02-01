#ifndef USE_EGL

#import <UIKit/UIKit.h>
#import "MGLKit.h"
#import <dlfcn.h>

#import "AppDelegate.h"
#import "egl_bridge_ios.h"

#import "SurfaceViewController.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"

#if defined (_LP64)
# define jlong_to_ptr(a) ((void*)(a))
# define ptr_to_jlong(a) ((jlong)(a))
#else
# define jlong_to_ptr(a) ((void*)(int)(a))
# define ptr_to_jlong(a) ((jlong)(int)(a))
#endif

void *getCurrentContext() {
    return (__bridge void*) glContext;
}

jboolean makeSharedContext() {
    [MGLContext setCurrentContext:nil];
    if ([MGLContext setCurrentContext:glContext] == YES) {
        // glContext = ctx;
        // glViewport(0, 0, width_c, height_c);
        return JNI_TRUE;
    }

    return JNI_FALSE;
}

jboolean clearCurrentContext() {
    if ([MGLContext setCurrentContext:nil] == YES) {
        return JNI_TRUE;
    }

    return JNI_FALSE;
}

void swapBuffers() {
    [viewController resume];
}

#endif
