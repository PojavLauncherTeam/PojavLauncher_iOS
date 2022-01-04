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

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SurfaceViewController.h"

#include <assert.h>
#include <stdlib.h>

#include "jni.h"
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

CGFloat grabCursorX, grabCursorY, lastCursorX, lastCursorY;

jclass inputBridgeClass_ANDROID, inputBridgeClass_JRE;
jmethodID inputBridgeMethod_ANDROID, inputBridgeMethod_JRE;

jclass uikitBridgeClass;
jmethodID uikitBridgeTouchMethod;

// JNI_OnLoad
jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    runtimeJavaVMPtr = vm;
    (*vm)->GetEnv(vm, (void**) &runtimeJNIEnvPtr_JRE, JNI_VERSION_1_4);
    
    isGrabbing = JNI_FALSE;
    
    return JNI_VERSION_1_4;
}

// Should be?
void JNI_OnUnload(JavaVM* vm, void* reserved) {
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

void getJavaInputBridge(jclass* clazz, jmethodID* method) {
#ifdef DEBUG
    debug("Debug: Initializing input bridge, method.isNull=%d, jnienv.isNull=%d\n", *method == NULL, runtimeJNIEnvPtr_ANDROID == NULL);
#endif
    if (*method == NULL && runtimeJNIEnvPtr_ANDROID != NULL) {
        *clazz = (*runtimeJNIEnvPtr_ANDROID)->FindClass(runtimeJNIEnvPtr_ANDROID, "org/lwjgl/glfw/CallbackBridge");
        assert(*clazz != NULL);
        *method = (*runtimeJNIEnvPtr_ANDROID)->GetStaticMethodID(runtimeJNIEnvPtr_ANDROID, *clazz, "receiveCallback", "(IFFII)V");
        assert(*method != NULL);
    }
}

void sendData(int type, CGFloat i1, CGFloat i2, int i3, int i4) {
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
    // FIXME: should we send double instead of float?
    (*runtimeJNIEnvPtr_ANDROID)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_ANDROID,
        inputBridgeClass_ANDROID,
        inputBridgeMethod_ANDROID,
        type,
        (jfloat)i1, (jfloat)i2, i3, i4
    );
}

void closeGLFWWindow() {
    NSLog(@"Closing GLFW window");

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

void callback_LauncherViewController_installMinecraft(char* versionPath) {
    // Because UI init after JVM init, this should not be null
    assert(runtimeJNIEnvPtr_JRE != NULL);
    
    if (!uikitBridgeClass) {
        uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
        assert(uikitBridgeClass != NULL);
    }

    jstring versionPathStr = (*runtimeJNIEnvPtr_JRE)->NewStringUTF(runtimeJNIEnvPtr_JRE, versionPath);

    jmethodID method = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_LauncherViewController_installMinecraft", "(Ljava/lang/String;)V");
    assert(method != NULL);
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, method,
        versionPathStr  
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

    jstring rendererLibStr = (*runtimeJNIEnvPtr_JRE)->NewStringUTF(runtimeJNIEnvPtr_JRE, getenv("RENDERER"));

    jmethodID method = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_SurfaceViewController_launchMinecraft", "(IILjava/lang/String;)V");
    assert(method != NULL);
    
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, method,
        width, height,
        rendererLibStr
    );
}

void callback_SurfaceViewController_onTouch(int event, CGFloat x, CGFloat y) {
    if (!uikitBridgeClass) {
        uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
        assert(uikitBridgeClass != NULL);
    }
    
    if (!uikitBridgeTouchMethod) {
        uikitBridgeTouchMethod = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_SurfaceViewController_onTouch", "(IFF)V");
        assert(uikitBridgeTouchMethod != NULL);
    }
    
    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, uikitBridgeTouchMethod,
        event, (jfloat)x, (jfloat)y
    );
}

const int hotbarKeys[9] = {
    GLFW_KEY_1, GLFW_KEY_2, GLFW_KEY_3,
    GLFW_KEY_4, GLFW_KEY_5, GLFW_KEY_6,
    GLFW_KEY_7, GLFW_KEY_8, GLFW_KEY_9
};
int guiScale = 1;
int mcscale(CGFloat input) {
    return (int)((guiScale * input)/resolutionScale);
}
int callback_SurfaceViewController_touchHotbar(CGFloat x, CGFloat y) {
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
    return hotbarKeys[(int) MathUtils_map(x, barX, barX + barWidth, 0, 9)];
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_updateMCGuiScale(JNIEnv* env, jclass clazz, jint scale) {
    guiScale = scale;
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_updateProgress(JNIEnv* env, jclass clazz, jfloat progress, jstring message) {
	const char *message_c = (*env)->GetStringUTFChars(env, message, 0);
	UIKit_updateProgress(progress, message_c);
	(*env)->ReleaseStringUTFChars(env, message, message_c);
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
JNIEXPORT jint JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_launchUI(JNIEnv* env, jclass clazz) {
    @autoreleasepool {
        return UIApplicationMain(1, (char *[]){ getenv("EXEC_PATH") }, nil, NSStringFromClass([AppDelegate class]));
    }
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

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSetGrabbing(JNIEnv* env, jclass clazz, jboolean grabbing, jfloat xset, jfloat yset) {
    isGrabbing = grabbing;
    if (isGrabbing == JNI_TRUE) {
        grabCursorX = xset; // savedWidth / 2;
        grabCursorY = yset; // savedHeight / 2;
        isPrepareGrabPos = true;

        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        virtualMouseFrame.origin.x = screenBounds.size.width / 2;
        virtualMouseFrame.origin.y = screenBounds.size.height / 2;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *surfaceView = ((SurfaceViewController *)viewController).surfaceView;
        if (isGrabbing == JNI_TRUE) {
            CGFloat screenScale = [[UIScreen mainScreen] scale] * resolutionScale;
            callback_SurfaceViewController_onTouch(ACTION_DOWN, lastVirtualMousePoint.x * screenScale, lastVirtualMousePoint.y * screenScale);
            ((SurfaceViewController *)viewController).mousePointerView.frame = virtualMouseFrame;
            [surfaceView removeGestureRecognizer:((SurfaceViewController *)viewController).scrollPanGesture];
        } else {
            [surfaceView addGestureRecognizer:((SurfaceViewController *)viewController).scrollPanGesture];
        }
        ((SurfaceViewController *)viewController).mousePointerView.hidden = isGrabbing || !virtualMouseEnabled;
    });
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeIsGrabbing(JNIEnv* env, jclass clazz) {
    return isGrabbing;
}

BOOL CallbackBridge_nativeSendChar(jchar codepoint /* jint codepoint */) {
    if (GLFW_invoke_Char && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_CHAR, codepoint, 0, 0, 0);
        } else {
            GLFW_invoke_Char((void*) showingWindow, (unsigned int) codepoint);
            // return lwjgl2_triggerCharEvent(codepoint);
        }
        return YES;
    }
    return NO;
}

BOOL CallbackBridge_nativeSendCharMods(jchar codepoint, int mods) {
    if (GLFW_invoke_CharMods && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_CHAR_MODS, (unsigned int) codepoint, mods, 0, 0);
        } else {
            GLFW_invoke_CharMods((void*) showingWindow, codepoint, mods);
        }
        return YES;
    }
    return NO;
}
/*
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorEnter(JNIEnv* env, jclass clazz, jint entered) {
    if (GLFW_invoke_CursorEnter && isInputReady) {
        GLFW_invoke_CursorEnter(showingWindow, entered);
    }
}
*/
void CallbackBridge_nativeSendCursorPos(CGFloat x, CGFloat y) {
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

void CallbackBridge_nativeSendKey(int key, int scancode, int action, int mods) {
    if (GLFW_invoke_Key && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_KEY, key, scancode, action, mods);
        } else {
            GLFW_invoke_Key((void*) showingWindow, key, scancode, action, mods);
        }
    }
}

void CallbackBridge_nativeSendKeycode(int keycode, char keychar, int scancode, int action, int mods) {
    if (isInputReady) {
        CallbackBridge_nativeSendKey(keycode, scancode, action, mods);
        if (!CallbackBridge_nativeSendCharMods(keychar, mods)) {
            CallbackBridge_nativeSendChar(keychar);
        }
    }
}

void CallbackBridge_nativeSendMouseButton(int button, int action, int mods) {
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

void CallbackBridge_nativeSendScreenSize(int width, int height) {
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

void CallbackBridge_nativeSendScroll(CGFloat xoffset, CGFloat yoffset) {
    if (GLFW_invoke_Scroll && isInputReady) {
        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_SCROLL, xoffset, yoffset, 0, 0);
        } else {
            GLFW_invoke_Scroll((void*) showingWindow, (double) xoffset, (double) yoffset);
        }
    }
}

void CallbackBridge_nativeSendWindowPos(int x, int y) {
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

void CallbackBridge_sendKeycode(int keycode, jchar keychar, int scancode, int modifiers, BOOL isDown) {
    if(keycode != 0)  CallbackBridge_nativeSendKey(keycode,scancode,isDown ? 1 : 0, modifiers);
    if(isDown && keychar != '\0') {
        CallbackBridge_nativeSendCharMods(keychar, modifiers);
        CallbackBridge_nativeSendChar(keychar);
    }
}
