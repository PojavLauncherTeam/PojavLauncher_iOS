#include "jni.h"
#include <assert.h>
#include <dlfcn.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "egl_bridge_ios.h"

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
struct PotatoBridge potatoBridge;
EGLConfig config;

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

#ifdef USE_EGL
    eglMakeCurrent(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
#else
    clearCurrentContext();
#endif

/*
    eglDestroySurface(potatoBridge.eglDisplay, potatoBridge.eglSurface);
    eglDestroyContext(potatoBridge.eglDisplay, potatoBridge.eglContext);
    eglTerminate(potatoBridge.eglDisplay);
    eglReleaseThread();
*/
    potatoBridge.eglContext = EGL_NO_CONTEXT;
    potatoBridge.eglDisplay = EGL_NO_DISPLAY;
    potatoBridge.eglSurface = EGL_NO_SURFACE;
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    return eglGetCurrentContext();
}

static const EGLint ctx_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
};
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    isInputReady = 1;
    
/*
    if (potatoBridge.eglDisplay == NULL || potatoBridge.eglDisplay == EGL_NO_DISPLAY) {
        potatoBridge.eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        if (potatoBridge.eglDisplay == EGL_NO_DISPLAY) {
            printf("EGLBridge: Error eglGetDefaultDisplay() failed: %p\n", eglGetError());
            return JNI_FALSE;
        }
    }

    printf("EGLBridge: Initializing\n");
    // printf("EGLBridge: ANativeWindow pointer = %p\n", potatoBridge.androidWindow);
    //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
    if (!eglInitialize(potatoBridge.eglDisplay, NULL, NULL)) {
        printf("EGLBridge: Error eglInitialize() failed\n");
        return JNI_FALSE;
    }

    static const EGLint attribs[] = {
            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            // Minecraft required on initial 24
            EGL_DEPTH_SIZE, 16,
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
            EGL_NONE
    };

    EGLint num_configs;
    EGLint vid;

    if (!eglChooseConfig(potatoBridge.eglDisplay, attribs, &config, 1, &num_configs)) {
        printf("EGLBridge: Error couldn't get an EGL visual config\n");
        return JNI_FALSE;
    }

    assert(config);
    assert(num_configs > 0);

    if (!eglGetConfigAttrib(potatoBridge.eglDisplay, config, EGL_NATIVE_VISUAL_ID, &vid)) {
        printf("EGLBridge: Error eglGetConfigAttrib() failed\n");
        return JNI_FALSE;
    }

    eglBindAPI(EGL_OPENGL_ES_API);

    potatoBridge.eglSurface = eglCreateWindowSurface(potatoBridge.eglDisplay, config, potatoBridge.androidWindow, NULL);

    if (!potatoBridge.eglSurface) {
        printf("EGLBridge: Error eglCreateWindowSurface failed: %p\n", eglGetError());
        //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
        return JNI_FALSE;
    }

    // sanity checks
    {
        EGLint val;
        assert(eglGetConfigAttrib(potatoBridge.eglDisplay, config, EGL_SURFACE_TYPE, &val));
        assert(val & EGL_WINDOW_BIT);
    }
*/

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
    if (window != 0x1) {
        debug("Making current on window %p", window);
        EGLBoolean success; 
#ifdef USE_EGL
        success = eglMakeCurrent(
            potatoBridge.eglDisplay,
            potatoBridge.eglSurface,
            potatoBridge.eglSurface,
            (EGLContext *) window
        );
#else
        success = makeSharedContext();
#endif 

        if (success == EGL_FALSE) {
            debug("Error: eglMakeCurrent() failed: %p", eglGetError());
        }

        debug("EGLBridge: Trigger an initial swapBuffers");
        swapBuffers();

        // Test
#ifdef GLES_TEST
        glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        eglSwapBuffers(potatoBridge.eglDisplay, potatoBridge.eglSurface);
        debug("First frame error: %p", eglGetError());
#endif
        if (success == EGL_TRUE) {
            GL4ES_HANDLE = dlopen(getenv("POJAV_OPENGL_LIBNAME"), RTLD_GLOBAL);
            debug("libGL=%p", GL4ES_HANDLE);
    
            gl4esInitialize_func *gl4esInitialize = (gl4esInitialize_func*) dlsym(GL4ES_HANDLE, "initialize_gl4es");
            // debug("initialize_gl4es = %p", gl4esInitialize);
    
            // gl4esSwapBuffers = (gl4esSwapBuffers_func*) dlsym(GL4ES_HANDLE, "gl4es_SwapBuffers_currentContext");
    
            gl4esInitialize();
            debug("GL4ES init success");
        }

        // idk this should convert or just `return success;`...
        return success == EGL_TRUE ? JNI_TRUE : JNI_FALSE;
    } else {
        (*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
        //return JNI_TRUE;
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglDetachOnCurrentThread(JNIEnv *env, jclass clazz) {
#ifdef USE_EGL
    eglMakeCurrent(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
#else
    clearCurrentContext();
#endif
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglCreateContext(JNIEnv *env, jclass clazz, jlong contextSrc) {
    EGLContext* ctx;
    if (contextSrc == 0) {
#ifdef USE_EGL
        EGLint numConfigs;
        EGLBoolean result;
        result = eglGetConfigs(potatoBridge.eglDisplay, NULL, 0,  &numConfigs);
	     assert(result != EGL_FALSE);
        EGLConfig configs[numConfigs];
        result = eglGetConfigs(potatoBridge.eglDisplay, configs, numConfigs, &numConfigs);
	     assert(result != EGL_FALSE );
        config = configs[0];

        ctx = eglCreateContext(potatoBridge.eglDisplay, config,(void*)potatoBridge.eglContext, ctx_attribs);

        debug("Created CTX pointer=%p, shareCtx=%p, error=%p", ctx, potatoBridge.eglContext, eglGetError());
#else
        ctx = potatoBridge.eglContext;
        debug("Using CTX pointer=%p, shareCtx=NULL", ctx);
#endif
    } else {
        ctx = eglCreateContext(potatoBridge.eglDisplay,config,(void*)contextSrc,ctx_attribs);
        debug("Created CTX pointer=%p, shareCtx=%p, error=%p", ctx, contextSrc, eglGetError());
    }
    //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
    return (long)ctx;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglTerminate(JNIEnv* env, jclass clazz) {
    isInputReady = 0;
    terminateEgl();
    return JNI_TRUE;
}

bool stopMakeCurrent;
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapBuffers(JNIEnv *env, jclass clazz) {
    if (stopMakeCurrent) {
        return JNI_FALSE;
    }

    // swapBuffers();
    jboolean result = (jboolean) eglSwapBuffers(potatoBridge.eglDisplay, eglGetCurrentSurface(EGL_DRAW));

    if (!result) {
        EGLint error = eglGetError();
        debug("eglSwapBuffers error: %p", error);
        if (error == EGL_BAD_SURFACE) {
            stopMakeCurrent = true;
            closeGLFWWindow();
        }
    }

    return result;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapInterval(JNIEnv *env, jclass clazz, jint interval) {
	  return eglSwapInterval(potatoBridge.eglDisplay, interval);
}
