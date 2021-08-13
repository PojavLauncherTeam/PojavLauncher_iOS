#include "jni.h"
#include <assert.h>
#include <dlfcn.h>

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "egl_bridge.h"

#include "EGL/egl.h"
#include "GLES2/gl2.h"

#include "utils.h"

#include "log.h"

struct PotatoBridge {
	/* EGLContext */ void* eglContextOld;
	/* EGLContext */ void* eglContext;
	/* EGLDisplay */ void* eglDisplay;
	/* EGLSurface */ void* eglSurface;
/*
	void* eglSurfaceRead;
	void* eglSurfaceDraw;
*/
};
EGLConfig config;
mach_port_t mainThreadID;
struct PotatoBridge potatoBridge;

typedef void gl4esInitialize_func();
// typedef void gl4esSwapBuffers_func();

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
    potatoBridge.eglContext = eglGetCurrentContext();
    potatoBridge.eglDisplay = eglGetCurrentDisplay();
    potatoBridge.eglSurface = eglGetCurrentSurface(EGL_DRAW);
    // eglMakeCurrent(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
}

void terminateEgl() {
    debug("EGLBridge: Terminating");

    [MGLContext setCurrentContext:nil];

    potatoBridge.eglContext = EGL_NO_CONTEXT;
    potatoBridge.eglDisplay = EGL_NO_DISPLAY;
    potatoBridge.eglSurface = EGL_NO_SURFACE;
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    return (jlong) eglGetCurrentContext();
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    isInputReady = 1;
    mainThreadID = pthread_mach_thread_np(pthread_self());

    debug("EGLBridge: Initialized!");
    // printf("EGLBridge: ThreadID=%d\n", gettid());
    debug("EGLBridge: EGLDisplay=%p, EGLSurface=%p",
/* window==0 ? EGL_NO_CONTEXT : */
        potatoBridge.eglDisplay,
        potatoBridge.eglSurface
    );
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglMakeCurrent(JNIEnv* env, jclass clazz, jlong window) {
    mach_port_t tid = pthread_mach_thread_np(pthread_self());
    MGLContext *currCtx = MGLContext.currentContext;
    MGLContext *localContext = [[NSThread currentThread] threadDictionary][@"gl_context"];
    EGLBoolean success;

    debug("EGLBridge: Comparing: thr=%d, this=%p, curr=%p", (int)tid, (void *)window, currCtx);
    debug("EGLBridge: Making current on window %p on thread (%d)", (void *)window, (int)tid);
    [MGLContext setCurrentContext:nil];
    if (window != 0) {
        if ((jlong)localContext != window) {
            debug("EGLBridge ERROR: Context mismatch! local=%p, input=%p", localContext, (void *)window);
        }
        success = [MGLContext setCurrentContext:localContext] == YES;
    }

    if (success == EGL_FALSE) {
        debug("Error: eglMakeCurrent() failed: %x", eglGetError());
    }

    debug("EGLBridge: Trigger an initial swapBuffers");
    [viewController.view.subviews[0] display];

    // Test
#ifdef GLES_TEST
    glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    eglSwapBuffers(potatoBridge.eglDisplay, potatoBridge.eglSurface);
    debug("First frame error: %x", eglGetError());
#endif
    if (success == EGL_TRUE && GL4ES_HANDLE == NULL) {
        GL4ES_HANDLE = dlopen(getenv("RENDERER"), RTLD_GLOBAL);
        debug("%s=%p, error=%s", getenv("RENDERER"), GL4ES_HANDLE, dlerror());

        gl4esInitialize_func *gl4esInitialize = (gl4esInitialize_func*) dlsym(GL4ES_HANDLE, "initialize_gl4es");
        // debug("initialize_gl4es = %p", gl4esInitialize);
    
        // gl4esSwapBuffers = (gl4esSwapBuffers_func*) dlsym(GL4ES_HANDLE, "gl4es_SwapBuffers_currentContext");
    
        gl4esInitialize();
        debug("Renderer init success");
    }

    // idk this should convert or just `return success;`...
    return success == EGL_TRUE ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglDetachOnCurrentThread(JNIEnv *env, jclass clazz) {
    [MGLContext setCurrentContext:nil];
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglCreateContext(JNIEnv *env, jclass clazz, jlong contextSrc) {
    MGLContext *localContext;
    mach_port_t tid = pthread_mach_thread_np(pthread_self());
    if (tid != mainThreadID) {
        localContext = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES3 sharegroup:sharegroup];
        debug("EGLBridge: Created CTX pointer=%p, shareCTX=%p, thread=%d", localContext, (void *)contextSrc, (int)tid);
    } else {
        localContext = ((MGLKView *)viewController.view.subviews[0]).context;
    }
    [[NSThread currentThread] threadDictionary][@"gl_context"] = localContext;
    debug("EGLBridge: Created CTX pointer=%p, shareCTX=%p, thread=%d", localContext, (void *)contextSrc, (int)tid);
    return (jlong)localContext;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglTerminate(JNIEnv* env, jclass clazz) {
    isInputReady = 0;
    terminateEgl();
    return JNI_TRUE;
}

bool stopMakeCurrent;
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapBuffers(JNIEnv *env, jclass clazz) {
    jboolean result = (jboolean) eglSwapBuffers(potatoBridge.eglDisplay, eglGetCurrentSurface(EGL_DRAW));

    if (!result) {
        mach_port_t tid = pthread_mach_thread_np(pthread_self());
        EGLint error = eglGetError();
        debug("eglSwapBuffers error=%x, thread=%d isMainThread=%d", error, (int)tid, mainThreadID == tid);
    }

    return result;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapInterval(JNIEnv *env, jclass clazz, jint interval) {
	  return eglSwapInterval(potatoBridge.eglDisplay, interval);
}
