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

typedef void gl4esInitialize_func();

// Called from JNI_OnLoad of liblwjgl_opengl
void pojav_openGLOnLoad() {
	
}
void pojav_openGLOnUnload() {

}

void terminateEgl() {
    printf("EGLBridge: Terminating\n");
    // clearCurrentContext(CURR_GL_CONTEXT);
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_saveGLContext(JNIEnv* env, jclass clazz) {
    CURR_GL_CONTEXT = createContext();
    // getCurrentContext();
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    return (jlong) (uintptr_t) CURR_GL_CONTEXT;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglMakeCurrent(JNIEnv* env, jclass clazz, jlong window) {
    jboolean ret = makeCurrentContext(CURR_GL_CONTEXT);
    
    void *libGL = dlopen("libGL.dylib", RTLD_GLOBAL);
    gl4esInitialize_func *gl4esInitialize = (gl4esInitialize_func*) dlsym(libGL, "gl4es_initialize");
    gl4esInitialize();
    
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
	
	printf("FIXME: swap interval at runtime is not supported on iOS!");
	
	return JNI_FALSE;
}

