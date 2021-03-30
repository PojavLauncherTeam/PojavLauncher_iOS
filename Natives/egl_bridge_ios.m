#ifndef USE_EGL

#import <UIKit/UIKit.h>
#import <dlfcn.h>

#import "AppDelegate.h"
#import "egl_bridge_ios.h"

#import "SurfaceViewController.h"

#include "GL/gl.h"

#include "utils.h"

#if defined (_LP64)
# define jlong_to_ptr(a) ((void*)(a))
# define ptr_to_jlong(a) ((jlong)(a))
#else
# define jlong_to_ptr(a) ((void*)(int)(a))
# define ptr_to_jlong(a) ((jlong)(int)(a))
#endif

/*
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
*/

void initSurface() {
/*
    void **zink_swapchain_window = (void **) dlsym(RTLD_DEFAULT, "zink_swapchain_window");
    assert(zink_swapchain_window);
    *zink_swapchain_window = (__bridge void*) globalSurfaceView.layer;
*/
}

void swapBuffers() {
    glFinish();
    // glReadPixels(0, 0, savedWidth, savedHeight, GL_RGBA, GL_UNSIGNED_BYTE, main_buffer);

dispatch_async(dispatch_get_main_queue(), ^{
/*
    NSData *imageData = [NSData dataWithBytesNoCopy:main_buffer length:savedWidth*savedHeight*4 freeWhenDone:YES];
    UIImage *image = [UIImage imageWithData:imageData];
    // [UIImagePNGRepresentation(image) writeToFile:@"/var/mobile/Documents/minecraft/test.png" atomically:YES];
    globalSurfaceView.image = image;
*/

    [globalSurfaceView displayLayer:globalSurfaceView.layer];
});
}

#endif
