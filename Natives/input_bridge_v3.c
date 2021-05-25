/*
 * V3 input bridge implementation.
 *
 * Status:
 * - Active development
 * - Works with some bugs:
 *  + Modded versions gives broken stuff..
 *
 * TODO:
 * - Implements glfwSetCursorPos() to handle grab camera pos correctly.
 */
 
#include "jni.h"
#include <assert.h>
#include <stdlib.h>

#include "glfw_keycodes.h"
#include "ios_uikit_bridge.h"

#include "log.h"
#include "utils.h"

#include "JavaLauncher.h"

typedef void GLFW_invoke_Char_func(void* window, unsigned int codepoint);
typedef void GLFW_invoke_CharMods_func(void* window, unsigned int codepoint, int mods);
typedef void GLFW_invoke_CursorEnter_func(void* window, int entered);
typedef void GLFW_invoke_CursorPos_func(void* window, double xpos, double ypos);
typedef void GLFW_invoke_FramebufferSize_func(void* window, int width, int height);
typedef void GLFW_invoke_Key_func(void* window, int key, int scancode, int action, int mods);
typedef void GLFW_invoke_MouseButton_func(void* window, int button, int action, int mods);
typedef void GLFW_invoke_Scroll_func(void* window, double xoffset, double yoffset);
typedef void GLFW_invoke_WindowSize_func(void* window, int width, int height);
typedef void GLFW_invoke_WindowPos_func(void* window, int x, int y);

int grabCursorX, grabCursorY, lastCursorX, lastCursorY;

jclass inputBridgeClass_ANDROID, inputBridgeClass_JRE;
jmethodID inputBridgeMethod_ANDROID, inputBridgeMethod_JRE;

jclass uikitBridgeClass;
jmethodID uikitBridgeTouchMethod;

// JNI_OnLoad
jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    debug("libpojavexec loaded from vm=%p\n", vm);
    runtimeJavaVMPtr = vm;
    (*vm)->GetEnv(vm, (void**) &runtimeJNIEnvPtr_JRE, JNI_VERSION_1_4);
    
    isGrabbing = JNI_FALSE;
    
    return JNI_VERSION_1_4;
}

// Should be?
void JNI_OnUnload(JavaVM* vm, void* reserved) {
/*
    if (dalvikJavaVMPtr == vm) {
    } else {
    }
    
    DetachCurrentThread(vm);
*/

    runtimeJNIEnvPtr_JRE = NULL;
}

#define ADD_CALLBACK_WWIN(NAME) \
GLFW_invoke_##NAME##_func* GLFW_invoke_##NAME; \
JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nglfwSet##NAME##Callback(JNIEnv * env, jclass cls, jlong window, jlong callbackptr) { \
    void** oldCallback = (void**) &GLFW_invoke_##NAME; \
    GLFW_invoke_##NAME = (GLFW_invoke_##NAME##_func*) (uintptr_t) callbackptr; \
    return (jlong) (uintptr_t) *oldCallback; \
}

ADD_CALLBACK_WWIN(Char);
ADD_CALLBACK_WWIN(CharMods);
ADD_CALLBACK_WWIN(CursorEnter);
ADD_CALLBACK_WWIN(CursorPos);
ADD_CALLBACK_WWIN(FramebufferSize);
ADD_CALLBACK_WWIN(Key);
ADD_CALLBACK_WWIN(MouseButton);
ADD_CALLBACK_WWIN(Scroll);
ADD_CALLBACK_WWIN(WindowSize);
ADD_CALLBACK_WWIN(WindowPos);

#undef ADD_CALLBACK_WWIN

jboolean attachThread(bool isAndroid, JNIEnv** secondJNIEnvPtr) {
#ifdef DEBUG
    debug("Debug: Attaching %s thread to %s, javavm.isNull=%d\n", isAndroid ? "Android" : "JRE", isAndroid ? "JRE" : "Android", (isAndroid ? runtimeJavaVMPtr : dalvikJavaVMPtr) == NULL);
#endif

    if (*secondJNIEnvPtr != NULL || (!isUseStackQueueCall)) return JNI_TRUE;

    if (isAndroid && runtimeJavaVMPtr) {
        (*runtimeJavaVMPtr)->AttachCurrentThread(runtimeJavaVMPtr, secondJNIEnvPtr, NULL);
        return JNI_TRUE;
    } else if (!isAndroid && dalvikJavaVMPtr) {
        (*dalvikJavaVMPtr)->AttachCurrentThread(dalvikJavaVMPtr, secondJNIEnvPtr, NULL);
        return JNI_TRUE;
    }
    
    return JNI_FALSE;
}

void getJavaInputBridge(jclass* clazz, jmethodID* method) {
#ifdef DEBUG
    debug("Debug: Initializing input bridge, method.isNull=%d, jnienv.isNull=%d\n", *method == NULL, runtimeJNIEnvPtr_ANDROID == NULL);
#endif
    if (*method == NULL && runtimeJNIEnvPtr_ANDROID != NULL) {
        *clazz = (*runtimeJNIEnvPtr_ANDROID)->FindClass(runtimeJNIEnvPtr_ANDROID, "org/lwjgl/glfw/CallbackBridge");
        assert(*clazz != NULL);
        *method = (*runtimeJNIEnvPtr_ANDROID)->GetStaticMethodID(runtimeJNIEnvPtr_ANDROID, *clazz, "receiveCallback", "(IIIII)V");
        assert(*method != NULL);
    }
}

void sendData(int type, int i1, int i2, int i3, int i4) {
    if (runtimeJNIEnvPtr_ANDROID == NULL) {
        (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, (void**) &runtimeJNIEnvPtr_ANDROID, JNI_VERSION_1_4);
        getJavaInputBridge(&inputBridgeClass_ANDROID, &inputBridgeMethod_ANDROID);
    }

#ifdef DEBUG
    debug("Debug: Send data, jnienv.isNull=%d\n", runtimeJNIEnvPtr_ANDROID == NULL);
#endif
    if (runtimeJNIEnvPtr_ANDROID == NULL) {
        debug("BUG: Input is ready but thread is not attached yet.");
        return;
    }
    (*runtimeJNIEnvPtr_ANDROID)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_ANDROID,
        inputBridgeClass_ANDROID,
        inputBridgeMethod_ANDROID,
        type,
        i1, i2, i3, i4
    );
}

void closeGLFWWindow() {
    /*
    jclass glfwClazz = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "org/lwjgl/glfw/GLFW");
    assert(glfwClazz != NULL);
    jmethodID glfwMethod = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, glfwMethod, "glfwSetWindowShouldClose", "(JZ)V");
    assert(glfwMethod != NULL);
    
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        glfwClazz, glfwMethod,
        (jlong) showingWindow, JNI_TRUE
    );
    */
    exit(-1);
}

void callback_LauncherViewController_installMinecraft() {
    // Because UI init after JVM init, this should not be null
    assert(runtimeJNIEnvPtr_JRE != NULL);
    
    if (!uikitBridgeClass) {
        uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
        assert(uikitBridgeClass != NULL);
    }
    
    jmethodID method = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_LauncherViewController_installMinecraft", "()V");
    assert(method != NULL);
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, method
    );
}

void callback_SurfaceViewController_launchMinecraft(int width, int height) {
    debug("Received SurfaceViewController callback, width=%d, height=%d\n", width, height);

    // Because UI init after JVM init, this should not be null
    assert(runtimeJNIEnvPtr_JRE != NULL);
    
    if (!uikitBridgeClass) {
        uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
        assert(uikitBridgeClass != NULL);
    }
    
    jmethodID method = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_SurfaceViewController_launchMinecraft", "(II)V");
    assert(method != NULL);
    
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, method,
        width, height
    );
}

void callback_SurfaceViewController_onTouch(int event, int x, int y) {
    if (!uikitBridgeClass) {
        uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
        assert(uikitBridgeClass != NULL);
    }
    
    if (!uikitBridgeTouchMethod) {
        uikitBridgeTouchMethod = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_SurfaceViewController_onTouch", "(III)V");
        assert(uikitBridgeTouchMethod != NULL);
    }
    
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, uikitBridgeTouchMethod,
        event, x, y
    );
}

const int hotbarKeys[9] = {
    GLFW_KEY_1, GLFW_KEY_2, GLFW_KEY_3,
    GLFW_KEY_4, GLFW_KEY_5, GLFW_KEY_6,
    GLFW_KEY_7, GLFW_KEY_8, GLFW_KEY_9
};
int guiScale = 1, scaleFactor = 1;
int mcscale(int input) {
    return (int)((guiScale * input)/scaleFactor);
}
int callback_SurfaceViewController_touchHotbar(int x, int y) {
    if (isGrabbing == JNI_FALSE) {
        return -1;
    }
    
    int barHeight = mcscale(20);
    int barWidth = mcscale(180);
    int barX = (savedWidth / 2) - (barWidth / 2);
    int barY = savedHeight - barHeight;
    if (x < barX || x >= barX + barWidth || y < barY || y >= barY + barHeight) {
        return -1;
    }
    return hotbarKeys[((x - barX) / mcscale(180 / 9)) % 9];
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_updateMCGuiScale(JNIEnv* env, jclass clazz, jint scale) {
    guiScale = scale;
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_setButtonSkippable(JNIEnv* env, jclass clazz) {
    UIKit_setButtonSkippable();
}

JNIEXPORT jboolean JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_updateProgress(JNIEnv* env, jclass clazz, jfloat progress, jstring message) {
	const char *message_c = (*env)->GetStringUTFChars(env, message, 0);
	jboolean skipDownloadAssets = UIKit_updateProgress(progress, message_c);
	(*env)->ReleaseStringUTFChars(env, message, message_c);
	return skipDownloadAssets;
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_launchMinecraftSurface(JNIEnv* env, jclass clazz, jboolean isUseStackQueueBool) {
    isUseStackQueueCall = (int) isUseStackQueueBool;
    UIKit_launchMinecraftSurfaceVC();
}
/*
JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_runOnUIThread(JNIEnv* env, jclass clazz, jobject callback) {
    UIKit_runOnUIThread(callback);
}
*/
JNIEXPORT jint JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_launchUI(JNIEnv* env, jclass clazz, jobjectArray args) {
	int argc = (*env)->GetArrayLength(env, args);
    char **argv = convert_to_char_array(env, args);
    return launchUI(argc, argv);
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeAttachThreadToOther(JNIEnv* env, jclass clazz, jboolean isAndroid, jboolean isUseStackQueueBool) {
#ifdef DEBUG
    LOGD("Debug: JNI attaching thread, isUseStackQueue=%d\n", isUseStackQueue);
#endif

    jboolean result;

    isUseStackQueueCall = (int) isUseStackQueueBool;
    if (isAndroid) {
        result = attachThread(true, &runtimeJNIEnvPtr_ANDROID);
    } else {
        result = attachThread(false, &dalvikJNIEnvPtr_JRE);
        // getJavaInputBridge(&inputBridgeClass_JRE, &inputBridgeMethod_JRE);
    }
    
    if (isUseStackQueueCall && isAndroid && result) {
        isPrepareGrabPos = true;
    }
        getJavaInputBridge(&inputBridgeClass_ANDROID, &inputBridgeMethod_ANDROID);
    
    return result;
}

JNIEXPORT jstring JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeClipboard(JNIEnv* env, jclass clazz, jint action, jstring copySrc) {
    DEBUG_LOGD("Debug: Clipboard access is going on\n");
    return UIKit_accessClipboard(env, action, copySrc);
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSetInputReady(JNIEnv* env, jclass clazz, jboolean inputReady) {
#ifdef DEBUG
    LOGD("Debug: Changing input state, isReady=%d, isUseStackQueueCall=%d\n", inputReady, isUseStackQueueCall);
#endif
    isInputReady = inputReady;
    return isUseStackQueueCall;
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSetGrabbing(JNIEnv* env, jclass clazz, jboolean grabbing, jint xset, jint yset) {
    isGrabbing = grabbing;
    if (isGrabbing == JNI_TRUE) {
        grabCursorX = xset; // savedWidth / 2;
        grabCursorY = yset; // savedHeight / 2;
        isPrepareGrabPos = true;
    }
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeIsGrabbing(JNIEnv* env, jclass clazz) {
    return isGrabbing;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendChar(JNIEnv* env, jclass clazz, jchar codepoint /* jint codepoint */) {
    if (GLFW_invoke_Char && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_CHAR, codepoint, 0, 0, 0);
        } else {
            GLFW_invoke_Char((void*) showingWindow, (unsigned int) codepoint);
            // return lwjgl2_triggerCharEvent(codepoint);
        }
        return JNI_TRUE;
    }
    return JNI_FALSE;
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(JNIEnv* env, jclass clazz, jchar codepoint, jint mods) {
    if (GLFW_invoke_CharMods && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_CHAR_MODS, (unsigned int) codepoint, mods, 0, 0);
        } else {
            GLFW_invoke_CharMods((void*) showingWindow, codepoint, mods);
        }
        return JNI_TRUE;
    }
    return JNI_FALSE;
}
/*
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorEnter(JNIEnv* env, jclass clazz, jint entered) {
    if (GLFW_invoke_CursorEnter && isInputReady) {
        GLFW_invoke_CursorEnter(showingWindow, entered);
    }
}
*/
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorPos(JNIEnv* env, jclass clazz, jint x, jint y) {
    if (GLFW_invoke_CursorPos && isInputReady) {
        if (!isCursorEntered) {
            if (GLFW_invoke_CursorEnter) {
                isCursorEntered = true;
                if (isUseStackQueueCall) {
                    sendData(EVENT_TYPE_CURSOR_ENTER, 1, 0, 0, 0);
                } else {
                    GLFW_invoke_CursorEnter((void*) showingWindow, 1);
                }
            } else if (isGrabbing) {
                // Some Minecraft versions does not use GLFWCursorEnterCallback
                // This is a smart check, as Minecraft will not in grab mode if already not.
                isCursorEntered = true;
            }
        }
        
        if (isGrabbing) {
            if (!isPrepareGrabPos) {
                grabCursorX += x - lastCursorX;
                grabCursorY += y - lastCursorY;
            }
            
            lastCursorX = x;
            lastCursorY = y;
            
            if (isPrepareGrabPos) {
                isPrepareGrabPos = false;
                return;
            }
        }
        
        if (!isUseStackQueueCall) {
            GLFW_invoke_CursorPos((void*) showingWindow, (double) (x), (double) (y));
        } else {
            sendData(EVENT_TYPE_CURSOR_POS, (isGrabbing ? grabCursorX : x), (isGrabbing ? grabCursorY : y), 0, 0);
        }
        
        lastCursorX = x;
        lastCursorY = y;
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(JNIEnv* env, jclass clazz, jint key, jint scancode, jint action, jint mods) {
    if (GLFW_invoke_Key && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_KEY, key, scancode, action, mods);
        } else {
            GLFW_invoke_Key((void*) showingWindow, key, scancode, action, mods);
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendKeycode(JNIEnv* env, jclass clazz, jint keycode, jchar keychar, jint scancode, jint action, jint mods) {
    if (isInputReady) {
        Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(env, clazz, keycode, scancode, action, mods);
        if (!Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(env, clazz, keychar, mods)) {
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendChar(env, clazz, keychar);
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(JNIEnv* env, jclass clazz, jint button, jint action, jint mods) {
    if (isInputReady) {
        if (button == -1) {
            // Notify to prepare set new grab pos
            isPrepareGrabPos = true;
        } else if (GLFW_invoke_MouseButton) {
            if (isUseStackQueueCall) {
                sendData(EVENT_TYPE_MOUSE_BUTTON, button, action, mods, 0);
            } else {
                GLFW_invoke_MouseButton((void*) showingWindow, button, action, mods);
            }
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendScreenSize(JNIEnv* env, jclass clazz, jint width, jint height) {
    savedWidth = width;
    savedHeight = height;
    
    if (isInputReady) {
        if (GLFW_invoke_FramebufferSize) {
            if (isUseStackQueueCall) {
                sendData(EVENT_TYPE_FRAMEBUFFER_SIZE, width, height, 0, 0);
            } else {
                GLFW_invoke_FramebufferSize((void*) showingWindow, width, height);
            }
        }
        
        if (GLFW_invoke_WindowSize) {
            if (isUseStackQueueCall) {
                sendData(EVENT_TYPE_WINDOW_SIZE, width, height, 0, 0);
            } else {
                GLFW_invoke_WindowSize((void*) showingWindow, width, height);
            }
        }
    }
    
    // return (isInputReady && (GLFW_invoke_FramebufferSize || GLFW_invoke_WindowSize));
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendScroll(JNIEnv* env, jclass clazz, jdouble xoffset, jdouble yoffset) {
    if (GLFW_invoke_Scroll && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_SCROLL, xoffset, yoffset, 0, 0);
        } else {
            GLFW_invoke_Scroll((void*) showingWindow, (double) xoffset, (double) yoffset);
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendWindowPos(JNIEnv* env, jclass clazz, jint x, jint y) {
    if (GLFW_invoke_WindowPos && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_WINDOW_POS, x, y, 0, 0);
        } else {
            GLFW_invoke_WindowPos((void*) showingWindow, x, y);
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_GLFW_nglfwSetShowingWindow(JNIEnv* env, jclass clazz, jlong window) {
    showingWindow = (long) window;
}

