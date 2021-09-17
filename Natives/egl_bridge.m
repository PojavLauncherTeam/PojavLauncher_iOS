#include "jni.h"
#include <assert.h>
#include <dlfcn.h>

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "EGL/egl.h"
#include "EGL/eglext.h"
#include "GL/osmesa.h"
#include "GLES2/gl2.h"

#include "egl_bridge.h"
#include "osmesa_internal.h"

#include "log.h"
#include "utils.h"
// region OSMESA internals


// endregion OSMESA internals
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
pid_t mainThreadID;
struct PotatoBridge potatoBridge;

/* OSMesa functions */
GLboolean (*OSMesaMakeCurrent_p) (OSMesaContext ctx, void *buffer, GLenum type,
                                  GLsizei width, GLsizei height);
OSMesaContext (*OSMesaGetCurrentContext_p) (void);
OSMesaContext  (*OSMesaCreateContext_p) (GLenum format, OSMesaContext sharelist);
void (*OSMesaDestroyContext_p) (OSMesaContext ctx);
void (*OSMesaPixelStore_p) ( GLint pname, GLint value );
GLubyte* (*glGetString_p) (GLenum name);
void (*glFinish_p) (void);
void (*glClearColor_p) (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
void (*glClear_p) (GLbitfield mask);

/*EGL functions */
EGLBoolean (*eglMakeCurrent_p) (EGLDisplay dpy, EGLSurface draw, EGLSurface read, EGLContext ctx);
EGLBoolean (*eglDestroyContext_p) (EGLDisplay dpy, EGLContext ctx);
EGLBoolean (*eglDestroySurface_p) (EGLDisplay dpy, EGLSurface surface);
EGLBoolean (*eglTerminate_p) (EGLDisplay dpy);
EGLBoolean (*eglReleaseThread_p) (void);
EGLContext (*eglGetCurrentContext_p) (void);
EGLDisplay (*eglGetPlatformDisplay_p) (EGLenum platform, void *native_display, const EGLint *attrib_list);
EGLBoolean (*eglInitialize_p) (EGLDisplay dpy, EGLint *major, EGLint *minor);
EGLBoolean (*eglChooseConfig_p) (EGLDisplay dpy, const EGLint *attrib_list, EGLConfig *configs, EGLint config_size, EGLint *num_config);
EGLBoolean (*eglGetConfigAttrib_p) (EGLDisplay dpy, EGLConfig config, EGLint attribute, EGLint *value);
EGLBoolean (*eglBindAPI_p) (EGLenum api);
EGLSurface (*eglCreateWindowSurface_p) (EGLDisplay dpy, EGLConfig config, NativeWindowType window, const EGLint *attrib_list);
EGLBoolean (*eglSwapBuffers_p) (EGLDisplay dpy, EGLSurface draw);
EGLint (*eglGetError_p) (void);
EGLContext (*eglCreateContext_p) (EGLDisplay dpy, EGLConfig config, EGLContext share_list, const EGLint *attrib_list);
EGLBoolean (*eglSwapInterval_p) (EGLDisplay dpy, EGLint interval);
EGLSurface (*eglGetCurrentSurface_p) (EGLint readdraw);
#define RENDERER_MTL_ANGLE 1
#define RENDERER_VK_ZINK 2

int config_renderer;

typedef void gl4esInitialize_func();
// typedef void gl4esSwapBuffers_func();
// gl4esSwapBuffers_func *gl4esSwapBuffers;
typedef jint RegalMakeCurrent_func(EGLContext context);

// Called from JNI_OnLoad of liblwjgl_opengl, TODO: check if unused
void pojav_openGLOnLoad() {
}
void pojav_openGLOnUnload() {
}

pid_t gettid() {
    return (pid_t) pthread_mach_thread_np(pthread_self());
}


JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_setenv(JNIEnv *env, jclass clazz, jstring name, jstring value, jboolean overwrite) {
    char const *name_c = (*env)->GetStringUTFChars(env, name, NULL);
    char const *value_c = (*env)->GetStringUTFChars(env, value, NULL);

    setenv(name_c, value_c, overwrite);

    (*env)->ReleaseStringUTFChars(env, name, name_c);
    (*env)->ReleaseStringUTFChars(env, value, value_c);
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_utils_JREUtils_saveGLContext(JNIEnv* env, jclass clazz) {
    // @deprecated, remove later
}

void terminateEgl() {
    debug("EGLBridge: Terminating");

    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            eglMakeCurrent_p(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            eglDestroySurface_p(potatoBridge.eglDisplay, potatoBridge.eglSurface);
            eglDestroyContext_p(potatoBridge.eglDisplay, potatoBridge.eglContext);
            eglTerminate_p(potatoBridge.eglDisplay);
            eglReleaseThread_p();
    
            potatoBridge.eglContext = EGL_NO_CONTEXT;
            potatoBridge.eglDisplay = EGL_NO_DISPLAY;
            potatoBridge.eglSurface = EGL_NO_SURFACE;
        } break;
        
        case RENDERER_VK_ZINK: {
            // Nothing to do here
        } break;
    }
}

JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglGetCurrentContext(JNIEnv* env, jclass clazz) {
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE:
            return (jlong) eglGetCurrentContext_p();

        case RENDERER_VK_ZINK:
            return (jlong) OSMesaGetCurrentContext_p();

        default: return (jlong) 0;
    }
}

void loadSymbols() {
    char fileName[2048];
    switch (config_renderer) {
        case RENDERER_VK_ZINK:
            sprintf((char *)fileName, "%s/Frameworks/libOSMesa.8.dylib.framework/libOSMesa.8.dylib", getenv("BUNDLE_PATH"));
            break;
        case RENDERER_MTL_ANGLE:
            sprintf((char *)fileName, "%s/Frameworks/MetalANGLE.framework/MetalANGLE", getenv("BUNDLE_PATH"));
            break;
    }
    void* dl_handle = dlopen(fileName,RTLD_NOW|RTLD_GLOBAL|RTLD_NODELETE);

    if(dl_handle == NULL) {
        NSLog(@"DlLoader: unable to load: %s", dlerror());
        return;
    }
    switch(config_renderer) {
        case RENDERER_VK_ZINK:
            OSMesaMakeCurrent_p = dlsym(dl_handle,"OSMesaMakeCurrent");
            OSMesaGetCurrentContext_p = dlsym(dl_handle,"OSMesaGetCurrentContext");
            OSMesaCreateContext_p = dlsym(dl_handle, "OSMesaCreateContext");
            OSMesaDestroyContext_p = dlsym(dl_handle, "OSMesaDestroyContext");
            OSMesaPixelStore_p = dlsym(dl_handle,"OSMesaPixelStore");
            glGetString_p = dlsym(dl_handle,"glGetString");
            glClearColor_p = dlsym(dl_handle, "glClearColor");
            glClear_p = dlsym(dl_handle,"glClear");
            glFinish_p = dlsym(dl_handle,"glFinish");
            break;
        case RENDERER_MTL_ANGLE:
            eglBindAPI_p = dlsym(dl_handle,"eglBindAPI");
            eglChooseConfig_p = dlsym(dl_handle, "eglChooseConfig");
            eglCreateContext_p = dlsym(dl_handle, "eglCreateContext");
            eglCreateWindowSurface_p = dlsym(dl_handle, "eglCreateWindowSurface");
            eglDestroyContext_p = dlsym(dl_handle, "eglDestroyContext");
            eglDestroySurface_p = dlsym(dl_handle, "eglDestroySurface");
            eglGetConfigAttrib_p = dlsym(dl_handle, "eglGetConfigAttrib");
            eglGetCurrentContext_p = dlsym(dl_handle, "eglGetCurrentContext");
            eglGetError_p = dlsym(dl_handle, "eglGetError");
            eglGetPlatformDisplay_p = dlsym(dl_handle, "eglGetPlatformDisplay");
            eglInitialize_p = dlsym(dl_handle, "eglInitialize");
            eglMakeCurrent_p = dlsym(dl_handle, "eglMakeCurrent");
            eglSwapBuffers_p = dlsym(dl_handle, "eglSwapBuffers");
            eglReleaseThread_p = dlsym(dl_handle, "eglReleaseThread");
            eglSwapInterval_p = dlsym(dl_handle, "eglSwapInterval");
            eglTerminate_p = dlsym(dl_handle, "eglTerminate");
            eglGetCurrentSurface_p = dlsym(dl_handle,"eglGetCurrentSurface");
            break;
    }
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglInit(JNIEnv* env, jclass clazz) {
    isInputReady = 1;
    mainThreadID = gettid();

    //const char *renderer = getenv("POJAV_RENDERER");
    //if (strncmp("opengles", renderer, 8) == 0) {
    NSString *renderer = @(getenv("RENDERER"));
    if ([renderer hasPrefix:@"libgl4es"] || [renderer hasPrefix:@"libtinygl4angle"]) {
        config_renderer = RENDERER_MTL_ANGLE;
        loadSymbols();
        if (potatoBridge.eglDisplay == EGL_NO_DISPLAY) {
            potatoBridge.eglDisplay = eglGetPlatformDisplay_p(EGL_PLATFORM_ANGLE_ANGLE, (void *)EGL_DEFAULT_DISPLAY, NULL);
            if (potatoBridge.eglDisplay == EGL_NO_DISPLAY) {
                NSLog(@"EGLBridge: Error eglGetDefaultDisplay() failed: 0x%x", eglGetError_p());
                return JNI_FALSE;
            }
        }

        NSLog(@"EGLBridge: Initializing");
        // printf("EGLBridge: ANativeWindow pointer = %p\n", potatoBridge.androidWindow);
        //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
        if (!eglInitialize_p(potatoBridge.eglDisplay, NULL, NULL)) {
            NSLog(@"EGLBridge: Error eglInitialize() failed: 0x%x", eglGetError_p());
            return JNI_FALSE;
        }

        static const EGLint attribs[] = {
                EGL_RED_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_BLUE_SIZE, 8,
                EGL_ALPHA_SIZE, 8,
                // Minecraft required on initial 24
                EGL_DEPTH_SIZE, 24,
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
                EGL_NONE
        };

        EGLint num_configs;
        EGLint vid;

        if (!eglChooseConfig_p(potatoBridge.eglDisplay, attribs, &config, 1, &num_configs)) {
            NSLog(@"EGLBridge: Error couldn't get an EGL visual config: 0x%x", eglGetError_p());
            return JNI_FALSE;
        }

        assert(config);
        assert(num_configs > 0);

        if (!eglGetConfigAttrib_p(potatoBridge.eglDisplay, config, EGL_NATIVE_VISUAL_ID, &vid)) {
            NSLog(@"EGLBridge: Error eglGetConfigAttrib() failed: 0x%x", eglGetError_p());
            return JNI_FALSE;
        }

        //ANativeWindow_setBuffersGeometry(potatoBridge.androidWindow, 0, 0, vid);

        if (!eglBindAPI_p(EGL_OPENGL_API)) {
            NSLog(@"EGLBridge: Failed to bind EGL_OPENGL_API, fallbacking to EGL_OPENGL_ES_API, error=0x%x", eglGetError_p());
            eglBindAPI_p(EGL_OPENGL_ES_API);
        }

        potatoBridge.eglSurface = eglCreateWindowSurface_p(potatoBridge.eglDisplay, config, (__bridge EGLNativeWindowType) ((SurfaceViewController *)viewController).surfaceView.layer, NULL);
        NSLog(@"Layer %@", ((SurfaceViewController *)viewController).surfaceView.layer);

        if (!potatoBridge.eglSurface) {
            NSLog(@"EGLBridge: Error eglCreateWindowSurface failed: 0x%x", eglGetError_p());
            //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
            return JNI_FALSE;
        }

        NSLog(@"EGLBridge: Initialized!");
        NSLog(@"EGLBridge: ThreadID=%d", gettid());
        NSLog(@"EGLBridge: EGLDisplay=%p, EGLSurface=%p",
/* window==0 ? EGL_NO_CONTEXT : */
               potatoBridge.eglDisplay,
               potatoBridge.eglSurface
        );
        return JNI_TRUE;
    // } else if (strcmp(renderer, "vulkan_zink") == 0) {
    } else if ([renderer hasPrefix:@"libOSMesa"]) {
        config_renderer = RENDERER_VK_ZINK;
        
        setenv("GALLIUM_DRIVER","zink",1);
        loadSymbols();
        if(OSMesaCreateContext_p == NULL) {
            NSLog(@"OSMDroid: %s",dlerror());
            return JNI_FALSE;
        }
        
        NSLog(@"OSMDroid: width=%i;height=%i, reserving %i bytes for frame buffer", savedWidth, savedHeight,
             savedWidth * 4 * savedHeight);
        gbuffer = malloc(savedWidth * 4 * savedHeight+1);
        if (gbuffer) {
            NSLog(@"OSMDroid: created frame buffer");
            return JNI_TRUE;
        } else {
            NSLog(@"OSMDroid: can't generate frame buffer");
            return JNI_FALSE;
        }
    }
    
    return JNI_FALSE;
}

int32_t stride;
bool stopSwapBuffers;
void flipFrame() {
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            if (!eglSwapBuffers_p(potatoBridge.eglDisplay, potatoBridge.eglSurface)) {
                if (eglGetError_p() == EGL_BAD_SURFACE) {
                    stopSwapBuffers = true;
                    closeGLFWWindow();
                }
            }
        } break;
        
        case RENDERER_VK_ZINK: {
            glFinish_p();
            dispatch_async(dispatch_get_main_queue(), ^{
                [((SurfaceViewController *)viewController).surfaceView displayLayer];
            });
        } break;
    }
}
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapBuffers(JNIEnv *env, jclass clazz) {
    if (stopSwapBuffers) {
        return JNI_FALSE;
    }
    flipFrame();
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglMakeCurrent(JNIEnv* env, jclass clazz, jlong window) {
    //if(OSMesaGetCurrentContext_p() != NULL) {
    //    printf("OSMDroid: skipped context reset\n");
    //    return JNI_TRUE;
    //}
    
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            EGLContext *currCtx = eglGetCurrentContext_p();
            NSLog(@"EGLBridge: Comparing: thr=%d, this=0x%llx, curr=%p", gettid(), window, currCtx);
            if (currCtx == NULL || window == 0) {
        /*if (window != 0x0 && potatoBridge.eglContextOld != NULL && potatoBridge.eglContextOld != (void *) window) {
            // Create new pbuffer per thread
            // TODO get window size for 2nd+ window!
            int surfaceWidth, surfaceHeight;
            eglQuerySurface(potatoBridge.eglDisplay, potatoBridge.eglSurface, EGL_WIDTH, &surfaceWidth);
            eglQuerySurface(potatoBridge.eglDisplay, potatoBridge.eglSurface, EGL_HEIGHT, &surfaceHeight);
            int surfaceAttr[] = {
                EGL_WIDTH, surfaceWidth,
                EGL_HEIGHT, surfaceHeight,
                EGL_NONE
            };
            potatoBridge.eglSurface = eglCreatePbufferSurface(potatoBridge.eglDisplay, config, surfaceAttr);
            printf("EGLBridge: created pbuffer surface %p for context %p\n", potatoBridge.eglSurface, window);
        }*/
        //potatoBridge.eglContextOld = (void *) window;
        // eglMakeCurrent(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
                NSLog(@"EGLBridge: Making current on window 0x%llx on thread %d", window, gettid());
                EGLBoolean success = eglMakeCurrent_p(
                    potatoBridge.eglDisplay,
                    window==0 ? (EGLSurface *) 0 : potatoBridge.eglSurface,
                    window==0 ? (EGLSurface *) 0 : potatoBridge.eglSurface,
                    /* window==0 ? EGL_NO_CONTEXT : */ (EGLContext *) window
                );
                if (success == EGL_FALSE) {
                    NSLog(@"EGLBridge: Error: eglMakeCurrent() failed: 0x%x", eglGetError_p());
                } else {
                    NSLog(@"EGLBridge: eglMakeCurrent() succeed!");
                }

                // Test
#ifdef GLES_TEST
                glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
                glClear(GL_COLOR_BUFFER_BIT);
                eglSwapBuffers(potatoBridge.eglDisplay, potatoBridge.eglSurface);
                NSLog(@"First frame error: 0x%x", eglGetError());
#endif
                if (success == EGL_TRUE) {
                    void *gl4es_handle = dlopen(getenv("RENDERER"), RTLD_GLOBAL);
                    debug("%s=%p, error=%s", getenv("RENDERER"), gl4es_handle, dlerror());

                    gl4esInitialize_func *gl4esInitialize = (gl4esInitialize_func*) dlsym(gl4es_handle, "initialize_gl4es");
                    // debug("initialize_gl4es = %p", gl4esInitialize);
                    if (gl4esInitialize) {
                        gl4esInitialize();
                    } else {
                        debug("%s", dlerror());
                    }
                    debug("Renderer init success");
                }

                // idk this should convert or just `return success;`...
                return success == EGL_TRUE ? JNI_TRUE : JNI_FALSE;
            } else {
                // (*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
                return JNI_FALSE;
            }
        }
        
        case RENDERER_VK_ZINK: {
            NSLog(@"OSMDroid: making current");
            GLboolean result = OSMesaMakeCurrent_p((OSMesaContext)window,gbuffer,GL_UNSIGNED_BYTE,savedWidth,savedHeight);
            //ANativeWindow_lock(potatoBridge.androidWindow,&buf,NULL);
            OSMesaPixelStore_p(OSMESA_ROW_LENGTH, savedWidth);
            //ANativeWindow_unlockAndPost(potatoBridge.androidWindow);

            OSMesaPixelStore_p(OSMESA_Y_UP,0);
            NSLog(@"OSMDroid: vendor: %s",glGetString_p(GL_VENDOR));
            NSLog(@"OSMDroid: renderer: %s",glGetString_p(GL_RENDERER));
            NSLog(@"OSMDroid: extensions: %s",glGetString_p(GL_EXTENSIONS));
            glClear_p(GL_COLOR_BUFFER_BIT);
            glClearColor_p(0.4f, 0.4f, 0.4f, 1.0f);
            flipFrame();
            return result;
        }
    }

    return JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_org_lwjgl_glfw_GLFW_nativeEglDetachOnCurrentThread(JNIEnv *env, jclass clazz) {
    //Obstruct the context on the current thread
    
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            eglMakeCurrent_p(potatoBridge.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        } break;
        
        case RENDERER_VK_ZINK: {
            // Nothing to do here
        } break;
    }
}

JNIEXPORT jlong JNICALL
Java_org_lwjgl_glfw_GLFW_nativeEglCreateContext(JNIEnv *env, jclass clazz, jlong contextSrc) {
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            const EGLint ctx_attribs[] = {
                EGL_CONTEXT_CLIENT_VERSION, 3,
                EGL_NONE
            };
            EGLContext* ctx = eglCreateContext_p(potatoBridge.eglDisplay, config, (void*)contextSrc, ctx_attribs);

            potatoBridge.eglContext = ctx;
    
            NSLog(@"EGLBridge: Created CTX pointer = %p",ctx);
            //(*env)->ThrowNew(env,(*env)->FindClass(env,"java/lang/Exception"),"Trace exception");
            return (long)ctx;
        }
        
        case RENDERER_VK_ZINK: {
            NSLog(@"OSMDroid: generating context");
            void* ctx = OSMesaCreateContext_p(OSMESA_RGBA, (OSMesaContext)contextSrc);
            NSLog(@"OSMDroid: context=%p",ctx);
            return (jlong)ctx;
        }
    }

    return 0l;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglTerminate(JNIEnv* env, jclass clazz) {
    isInputReady = 0;
    terminateEgl();
    return JNI_TRUE;
}

JNIEXPORT void JNICALL Java_org_lwjgl_opengl_GL_nativeRegalMakeCurrent(JNIEnv *env, jclass clazz) {
    //NSLog(@"Regal: making current");
    
    //RegalMakeCurrent_func *RegalMakeCurrent = (RegalMakeCurrent_func *) dlsym(RTLD_DEFAULT, "RegalMakeCurrent");
    //assert(RegalMakeCurrent);
    //RegalMakeCurrent(potatoBridge.eglContext);

    NSLog(@"Regal removed");
    abort();
}

JNIEXPORT jlong JNICALL
Java_org_lwjgl_opengl_GL_getGraphicsBufferAddr(JNIEnv *env, jobject thiz) {
    return (jlong)&gbuffer;
}
JNIEXPORT jintArray JNICALL
Java_org_lwjgl_opengl_GL_getNativeWidthHeight(JNIEnv *env, jobject thiz) {
    jintArray ret = (*env)->NewIntArray(env,2);
    jint arr[] = {savedWidth, savedHeight};
    (*env)->SetIntArrayRegion(env,ret,0,2,arr);
    return ret;
}
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_GLFW_nativeEglSwapInterval(JNIEnv *env, jclass clazz, jint interval) {
    switch (config_renderer) {
        case RENDERER_MTL_ANGLE: {
            return eglSwapInterval_p(potatoBridge.eglDisplay, interval);
        } break;
        
        case RENDERER_VK_ZINK: {
            NSLog(@"eglSwapInterval: NOT IMPLEMENTED YET!");
            // Nothing to do here
        } break;
    }

    return JNI_FALSE;
}
