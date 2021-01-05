#include "jni.h"
#include <assert.h>
#include <dlfcn.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#ifdef GLES_TEST
#include <GLES2/gl2.h>
#endif

#include "egl_bridge_ios.h"
#include "utils.h"

#include "log.h"

typedef void gl4esInitialize_func();

// Called from JNI_OnLoad of liblwjgl_opengl
void pojav_openGLOnLoad() {
	
}
void pojav_openGLOnUnload() {

}

void terminateEgl() {
    debug("ES2Bridge: Terminating\n");
    // clearCurrentContext(CURR_GL_CONTEXT);
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_setenv(JNIEnv *env, jclass clazz, jstring name, jstring value, jboolean overwrite) {
    char const *name_c = (*env)->GetStringUTFChars(env, name, NULL);
    char const *value_c = (*env)->GetStringUTFChars(env, value, NULL);

    setenv(name_c, value_c, overwrite);

    (*env)->ReleaseStringUTFChars(env, name, name_c);
    (*env)->ReleaseStringUTFChars(env, value, value_c);
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_saveGLContext(JNIEnv* env, jclass clazz) {
    CURR_GL_CONTEXT = getCurrentContext();
    if (CURR_GL_CONTEXT == NULL) {
        debug("OpenGLES context is NULL...");
        assert(CURR_GL_CONTEXT != NULL);
    }
    
    // Clear current GL context to later set on another thread
    // clearCurrentContext();
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    return (jlong) (uintptr_t) CURR_GL_CONTEXT;
}
/*
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    return JNI_TRUE;
}
*/
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglMakeCurrent(JNIEnv* env, jclass clazz, jlong window) {
    debug("ES2Bridge: making current\n");
    
    jboolean ret = makeCurrentContext(CURR_GL_CONTEXT);
    if (!ret) {
        return ret;
    }

    void *libGL = dlopen("libGL.dylib", RTLD_GLOBAL);
    debug("libGL = %p", libGL);
    
    gl4esInitialize_func *gl4esInitialize = (gl4esInitialize_func*) dlsym(libGL, "initialize_gl4es");
    debug("initialize_gl4es = %p", gl4esInitialize);
    
    gl4esInitialize();
    debug("GL4ES init success");

    return ret;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglTerminate(JNIEnv* env, jclass clazz) {
    clearCurrentContext();
    return JNI_TRUE;
}

bool stopMakeCurrent;
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapBuffers(JNIEnv *env, jclass clazz) {
    if (stopMakeCurrent) {
        return JNI_FALSE;
    }
    
    flushBuffer();
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapInterval(JNIEnv *env, jclass clazz, jint interval) {
	// return eglSwapInterval(potatoBridge.eglDisplay, interval);
	// setSwapInterval(CURR_GL_CONTEXT. interval);
	
	debug("FIXME: swap interval at runtime is not supported on iOS!");
	
	return JNI_FALSE;
}

