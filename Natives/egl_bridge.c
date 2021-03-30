#include "jni.h"
#include <assert.h>
#include <dlfcn.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include <sys/time.h>

#include "egl_bridge_ios.h"
#include "uikit_winsys.h"

#include "EGL/egl.h"
#include "GL/osmesa.h"

#include "utils.h"

#include "log.h"


// gl4esSwapBuffers_func *gl4esSwapBuffers;

// Called from JNI_OnLoad of liblwjgl_opengl
void pojav_openGLOnLoad() {
	
}
void pojav_openGLOnUnload() {

}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_setenv(JNIEnv *env, jclass clazz, jstring name, jstring value, jboolean overwrite) {
    char const *name_c = (*env)->GetStringUTFChars(env, name, NULL);
    char const *value_c = (*env)->GetStringUTFChars(env, value, NULL);

    setenv(name_c, value_c, overwrite);

    (*env)->ReleaseStringUTFChars(env, name, name_c);
    (*env)->ReleaseStringUTFChars(env, value, value_c);
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_saveGLContext(JNIEnv* env, jclass clazz) {
    // eglMakeCurrent(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
}

void terminateEgl() {
    debug("EGLBridge: Terminating");
}

struct pipe_screen;

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    isInputReady = 1;
    
    initSurface();

/*
    _glapi_check_multithread();
    
    struct pipe_screen *screen = zink_create_screen(NULL);
    debug("Zink created screen: %p", screen);
    
    // screen->context_create(screen, NULL, 0);
    struct pipe_context *context = zink_context_create(screen, NULL, 0);
    debug("Zink created context: %p", context);

    _glapi_set_context((void *) context);
    _glapi_set_dispatch(context->CurrentServerDispatch);
    debug("Zink context is set: %p", _glapi_get_context());
*/
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglMakeCurrent(JNIEnv* env, jclass clazz, jlong window) {
    if (window != 0) {
        OSMesaContext osmesa_context = (OSMesaContext) window;

        // Inject our winsys into it
/*
        struct sw_winsys **winsys = &((struct st_manager*)osmesa_context->stctx->st_context_private)->screen->winsys;
        free(*winsys);
        *winsys = uikit_sw_create();
*/

        main_buffer = calloc(4, (size_t) (savedWidth * savedHeight));
        GLboolean result = OSMesaMakeCurrent(osmesa_context, main_buffer, GL_UNSIGNED_BYTE, savedWidth, savedHeight);

        OSMesaPixelStore(OSMESA_ROW_LENGTH, savedWidth);
        OSMesaPixelStore(OSMESA_Y_UP, 0);

        return result == GL_TRUE;

/*
    struct pipe_screen *screen = zink_create_screen(NULL);
    debug("Zink created screen: %p", screen);
    
    // screen->context_create(screen, NULL, 0);
    struct pipe_context *context = zink_context_create(screen, NULL, 0);
    debug("Zink created context: %p", context);
    
    osmesa_context->stctx->pipe = context;
    // get st_manager
    ((struct st_manager*)osmesa_context->stctx->st_context_private)->screen = screen;
*/
    // return (jlong) osmesa_context;
    
    // setenv("GALLIUM_DRIVER", "zink", 1);
    }
    return JNI_FALSE;
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglDetachOnCurrentThread(JNIEnv *env, jclass clazz) {
    OSMesaDestroyContext(OSMesaGetCurrentContext());
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    return (jlong) OSMesaGetCurrentContext();
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglCreateContext(JNIEnv *env, jclass clazz, jlong contextSrc) {
    /*
     * Important notes:
     * + MoltenVK extensions only supports GL 2.1 :(
     * + Don't set minor version, it will gives no context.
     * + Don't set to OSMESA_CORE_PROFILE, it will gives no context in most cases.
     */
    int attribList[20] = {
        OSMESA_FORMAT, OSMESA_RGBA,
        OSMESA_ACCUM_BITS, 8 + 8 + 8 + 8,
        OSMESA_DEPTH_BITS, 24,
        OSMESA_PROFILE, OSMESA_COMPAT_PROFILE,
        // OSMESA_CONTEXT_MAJOR_VERSION, 2,
        // OSMESA_CONTEXT_MINOR_VERSION, 1,
        0
    };

    return (jlong) OSMesaCreateContextAttribs(attribList, (OSMesaContext) contextSrc);
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglTerminate(JNIEnv* env, jclass clazz) {
    isInputReady = 0;
    terminateEgl();
    return JNI_TRUE;
}

bool stopMakeCurrent;
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapBuffers(JNIEnv *env, jclass clazz) {
/*
    struct timeval te; 
    gettimeofday(&te, NULL);
    long long millisecondsFirst = te.tv_sec*1000LL + te.tv_usec/1000;
    
    glFinish();
    
    gettimeofday(&te, NULL);
    long long millisecondsSecond = te.tv_sec*1000LL + te.tv_usec/1000;
    
    debug("glFinish() took %dms", (int) (millisecondsSecond - millisecondsFirst));
*/
    
    swapBuffers();
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapInterval(JNIEnv *env, jclass clazz, jint interval) {
	 return JNI_TRUE;
    //eglSwapInterval(potatoBridge.eglDisplay, interval);
}
