/*
 * V3 input bridge implementation.
 *
 * Status:
 * - Active development
 * - Works with some bugs:
 *  + Modded versions gives broken stuff..
 */

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SurfaceViewController.h"

#include <assert.h>
#include <dlfcn.h>
#include <libgen.h>
#include <stdlib.h>
#include <stdatomic.h>

#include "jni.h"
#include "glfw_keycodes.h"
#include "ios_uikit_bridge.h"
#include "utils.h"

#include "JavaLauncher.h"

jint (*orig_ProcessImpl_forkAndExec)(JNIEnv *env, jobject process, jint mode, jbyteArray helperpath, jbyteArray prog, jbyteArray argBlock, jint argc, jbyteArray envBlock, jint envc, jbyteArray dir, jintArray std_fds, jboolean redirectErrorStream);
jlong (*orig_ProcessHandleImpl_isAlive0)(JNIEnv *env, jclass clazz, jlong jpid);

NSString* processPath(NSString* path) {
    if ([path hasPrefix:@"file:"]) {
        path = [path substringFromIndex:5].stringByRemovingPercentEncoding;
    }
    path = path.stringByResolvingSymlinksInPath;

    NSString *prefix = @"file";
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"shareddocuments://"]] &&
      ![path hasPrefix:@"/var/mobile/Documents"]) {
        // Prefer opening in Files if containerized
        prefix = @"shareddocuments";
    } else if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"filza://"]]) {
        // Open in Filza if installed
        prefix = @"filza";
    } else if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"santander://"]]) {
        // Open in Santander if installed
        prefix = @"santander";
    }

    return [NSString stringWithFormat:@"%@://%@", prefix, path];
}

void openURLGlobal(NSString *path) {
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([path hasPrefix:@"http"]) {
            openLink(UIWindow.mainWindow.rootViewController, [NSURL URLWithString:path]);
            dispatch_group_leave(group);
            return;
        }
        NSString *realPath = processPath(path);
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:realPath] options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"Opened \"%@\"", realPath);
            } else {
                NSLog(@"Failed to open \"%@\"", realPath);
            }
            dispatch_group_leave(group);
        }];
    });

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

/**
 * Hooked version of java.lang.UNIXProcess.forkAndExec()
 * which is used to handle the "open" command.
 */
jint
hooked_ProcessImpl_forkAndExec(JNIEnv *env, jobject process, jint mode, jbyteArray helperpath, jbyteArray prog, jbyteArray argBlock, jint argc, jbyteArray envBlock, jint envc, jbyteArray dir, jintArray std_fds, jboolean redirectErrorStream) {
    char *pProg = (char *)((*env)->GetByteArrayElements(env, prog, NULL));

    // Here we only handle the "open" command
    if (strcmp(basename(pProg), "open")) {
        (*env)->ReleaseByteArrayElements(env, prog, (jbyte *)pProg, 0);
        return orig_ProcessImpl_forkAndExec(env, process, mode, helperpath, prog, argBlock, argc, envBlock, envc, dir, std_fds, redirectErrorStream);
    }

    char *path = (char *)((*env)->GetByteArrayElements(env, argBlock, NULL));
    openURLGlobal(@(path));

    (*env)->ReleaseByteArrayElements(env, prog, (jbyte *)pProg, 0);
    (*env)->ReleaseByteArrayElements(env, argBlock, (jbyte *)path, 0);
    return 0;
}

/**
 * Hooked version of java.lang.ProcessHandleImpl.isAlive0()
 * which is used to ignore "Operation not permitted"
 */
jlong hooked_ProcessHandleImpl_isAlive0(JNIEnv *env, jclass clazz, jlong jpid) {
    jlong result = orig_ProcessHandleImpl_isAlive0(env, clazz, jpid);
    if ((*env)->ExceptionOccurred(env)) {
        (*env)->ExceptionClear(env);
    }
    return result;
}

// Part of awt_bridge
void CTCClipboard_nQuerySystemClipboard(JNIEnv *env, jclass clazz) {
    if(method_SystemClipboardDataReceived == NULL) {
        class_CTCClipboard = (*env)->NewGlobalRef(env, clazz);
        method_SystemClipboardDataReceived = (*env)->GetStaticMethodID(env, clazz, "systemClipboardDataReceived", "(Ljava/lang/String;Ljava/lang/String;)V");
    }
    // From Java_net_kdt_pojavlaunch_AWTInputBridge_nativeClipboardReceived
    // Note: we cannot use main_queue here as it will cause deadlock
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        JNIEnv *env;
        (*runtimeJavaVMPtr)->AttachCurrentThread(runtimeJavaVMPtr, &env, NULL);
        const char* mimeChars = "text/plain";
        (*env)->CallStaticVoidMethod(env, class_CTCClipboard, method_SystemClipboardDataReceived,
            UIKit_accessClipboard(env, CLIPBOARD_PASTE, NULL),
            (*env)->NewStringUTF(env, mimeChars));
        (*runtimeJavaVMPtr)->DetachCurrentThread(runtimeJavaVMPtr);
    });
}

void CTCClipboard_nPutClipboardData(JNIEnv* env, jclass clazz, jstring clipboardData, jstring clipboardDataMime) {
    // TODO: handle non-text data(?)
    UIKit_accessClipboard(env, CLIPBOARD_COPY, clipboardData);
}

void CTCDesktopPeer_openGlobal(JNIEnv *env, jclass clazz, jstring path) {
    const char* stringChars = (*env)->GetStringUTFChars(env, path, NULL);
    openURLGlobal(@(stringChars));
    (*env)->ReleaseStringUTFChars(env, path, stringChars);
}

void registerOpenHandler(JNIEnv *env) {
    jclass cls;

    // Hook forkAndExec
    orig_ProcessImpl_forkAndExec = dlsym(RTLD_DEFAULT, "Java_java_lang_UNIXProcess_forkAndExec");
    if (!orig_ProcessImpl_forkAndExec) {
        orig_ProcessImpl_forkAndExec = dlsym(RTLD_DEFAULT, "Java_java_lang_ProcessImpl_forkAndExec");
        cls = (*env)->FindClass(env, "java/lang/ProcessImpl");
    } else {
        cls = (*env)->FindClass(env, "java/lang/UNIXProcess");
    }
    JNINativeMethod forkAndExecMethod[] = {
        {"forkAndExec", "(I[B[B[BI[BI[B[IZ)I", (void *)&hooked_ProcessImpl_forkAndExec}
    };
    (*env)->RegisterNatives(env, cls, forkAndExecMethod, 1);

    // (Java 17 only) Hook isAlive0
    cls = (*env)->FindClass(env, "java/lang/ProcessHandleImpl");
    if ((*env)->ExceptionOccurred(env)) {
        // Java 8
        (*env)->ExceptionClear(env);
    } else {
        orig_ProcessHandleImpl_isAlive0 = dlsym(RTLD_DEFAULT, "Java_java_lang_ProcessHandleImpl_isAlive0");
        JNINativeMethod isAlive0Method[] = {
            {"isAlive0", "(J)J", (void *)&hooked_ProcessHandleImpl_isAlive0}
        };
        (*env)->RegisterNatives(env, cls, isAlive0Method, 1);
    }

    // Register CTCClipboard natives
    cls = (*env)->FindClass(env, "net/java/openjdk/cacio/ctc/CTCClipboard");
    if ((*env)->ExceptionOccurred(env)) {
        // Java 17
        (*env)->ExceptionClear(env);
        cls = (*env)->FindClass(env, "com/github/caciocavallosilano/cacio/ctc/CTCClipboard");
    }
    JNINativeMethod clipboardMethods[] = {
        {"nQuerySystemClipboard", "()V", (void *)&CTCClipboard_nQuerySystemClipboard},
        {"nPutClipboardData", "(Ljava/lang/String;Ljava/lang/String;)V", (void *)&CTCClipboard_nPutClipboardData}
    };
    (*env)->RegisterNatives(env, cls, clipboardMethods, 2);

    // Register CTCDesktopPeer natives
    cls = (*env)->FindClass(env, "net/java/openjdk/cacio/ctc/CTCDesktopPeer");
    if ((*env)->ExceptionOccurred(env)) {
        // Java 17, not available
        //(*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        return;
    }
    JNINativeMethod peerOpenMethods[] = {
        {"openFile", "(Ljava/lang/String;)V", (void *)&CTCDesktopPeer_openGlobal},
        {"openUri", "(Ljava/lang/String;)V", (void *)&CTCDesktopPeer_openGlobal}
    };
    (*env)->RegisterNatives(env, cls, peerOpenMethods, 2);
}

// JNI_OnLoad
void JNI_OnLoadGLFW() {
    vmGlfwClass = (*runtimeJNIEnvPtr)->NewGlobalRef(runtimeJNIEnvPtr, (*runtimeJNIEnvPtr)->FindClass(runtimeJNIEnvPtr, "org/lwjgl/glfw/GLFW"));
    method_internalWindowSizeChanged = (*runtimeJNIEnvPtr)->GetStaticMethodID(runtimeJNIEnvPtr, vmGlfwClass, "internalWindowSizeChanged", "(JII)V");
    jfieldID field_keyDownBuffer = (*runtimeJNIEnvPtr)->GetStaticFieldID(runtimeJNIEnvPtr, vmGlfwClass, "keyDownBuffer", "Ljava/nio/ByteBuffer;");
    jobject keyDownBufferJ = (*runtimeJNIEnvPtr)->GetStaticObjectField(runtimeJNIEnvPtr, vmGlfwClass, field_keyDownBuffer);
    keyDownBuffer = (*runtimeJNIEnvPtr)->GetDirectBufferAddress(runtimeJNIEnvPtr, keyDownBufferJ);
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    runtimeJavaVMPtr = vm;

    JNIEnv *env;
    (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, (void **)&env, JNI_VERSION_1_4);
    registerOpenHandler(env);
    if (!getenv("POJAV_SKIP_JNI_GLFW")) {
        runtimeJNIEnvPtr = env;
        JNI_OnLoadGLFW();
    }

    return JNI_VERSION_1_4;
}

// Should be?
void JNI_OnUnload(JavaVM* vm, void* reserved) {
    runtimeJNIEnvPtr = NULL;
}

#define ADD_CALLBACK_WWIN(NAME) \
JNIEXPORT jlong JNICALL Java_org_lwjgl_glfw_GLFW_nglfwSet##NAME##Callback(JNIEnv * env, jclass cls, jlong window, jlong callbackptr) { \
    void** oldCallback = (void**) &GLFW_invoke_##NAME; \
    GLFW_invoke_##NAME = (GLFW_invoke_##NAME##_func*) (uintptr_t) callbackptr; \
    return (jlong) (uintptr_t) *oldCallback; \
}

ADD_CALLBACK_WWIN(Char)
ADD_CALLBACK_WWIN(CharMods)
ADD_CALLBACK_WWIN(CursorEnter)
ADD_CALLBACK_WWIN(CursorPos)
ADD_CALLBACK_WWIN(FramebufferSize)
ADD_CALLBACK_WWIN(Key)
ADD_CALLBACK_WWIN(MouseButton)
ADD_CALLBACK_WWIN(Scroll)
ADD_CALLBACK_WWIN(WindowPos)
ADD_CALLBACK_WWIN(WindowSize)

#undef ADD_CALLBACK_WWIN

void handleFramebufferSizeJava(void* window, int w, int h) {
    if(GLFW_invoke_CursorEnter)GLFW_invoke_CursorEnter(window, 1);
    if(GLFW_invoke_WindowPos)GLFW_invoke_WindowPos(window, 0, 0);
    (*runtimeJNIEnvPtr)->CallStaticVoidMethod(runtimeJNIEnvPtr, vmGlfwClass, method_internalWindowSizeChanged, (long)window, w, h);
}

void pojavPumpEvents(void* window) {
    CallbackBridge_nativeSetInputReady(YES);
    //__android_log_print(ANDROID_LOG_INFO, "input_bridge_v3", "pojavPumpevents %d", eventCounter);
    size_t counter = atomic_load_explicit(&eventCounter, memory_order_acquire);
    if((cLastX != cursorX || cLastY != cursorY) && GLFW_invoke_CursorPos) {
        cLastX = cursorX;
        cLastY = cursorY;
        if (isUseStackQueueCall)
            GLFW_invoke_CursorPos(window, cursorX, cursorY);
    }
    for(size_t i = 0; i < counter; i++) {
        GLFWInputEvent event = events[i];
        switch(event.type) {
            case EVENT_TYPE_CHAR:
                if(GLFW_invoke_Char) GLFW_invoke_Char(window, event.i1);
                break;
            case EVENT_TYPE_CHAR_MODS:
                if(GLFW_invoke_CharMods) GLFW_invoke_CharMods(window, event.i1, event.i2);
                break;
            case EVENT_TYPE_KEY:
                if(GLFW_invoke_Key) GLFW_invoke_Key(window, event.i1, event.i2, event.i3, event.i4);
                break;
            case EVENT_TYPE_MOUSE_BUTTON:
                if(GLFW_invoke_MouseButton) GLFW_invoke_MouseButton(window, event.i1, event.i2, event.i3);
                break;
            case EVENT_TYPE_SCROLL:
                if(GLFW_invoke_Scroll) GLFW_invoke_Scroll(window, event.f1, event.f2);
                break;
            case EVENT_TYPE_FRAMEBUFFER_SIZE:
                handleFramebufferSizeJava(window, event.i1, event.i2);
                if(GLFW_invoke_FramebufferSize) GLFW_invoke_FramebufferSize(window, event.i1, event.i2);
                break;
            case EVENT_TYPE_WINDOW_SIZE:
                handleFramebufferSizeJava(window, event.i1, event.i2);
                if(GLFW_invoke_WindowSize) GLFW_invoke_WindowSize(window, event.i1, event.i2);
                break;
        }
    }
    atomic_store_explicit(&eventCounter, counter, memory_order_release);
}
void pojavRewindEvents() {
    atomic_store_explicit(&eventCounter, 0, memory_order_release);
}

JNIEXPORT void JNICALL
Java_org_lwjgl_glfw_GLFW_nglfwGetCursorPos(JNIEnv *env, jclass clazz, jlong window, jobject xpos,
                                          jobject ypos) {
    *(double*)(*env)->GetDirectBufferAddress(env, xpos) = cursorX;
    *(double*)(*env)->GetDirectBufferAddress(env, ypos) = cursorY;
}

JNIEXPORT void JNICALL
Java_org_lwjgl_glfw_GLFW_nglfwGetCursorPosA(JNIEnv *env, jclass clazz, jlong window,
                                            jdoubleArray xpos, jdoubleArray ypos) {
    (*env)->SetDoubleArrayRegion(env, xpos, 0,1, &cursorX);
    (*env)->SetDoubleArrayRegion(env, ypos, 0,1, &cursorY);
}

JNIEXPORT void JNICALL
Java_org_lwjgl_glfw_GLFW_glfwSetCursorPos(JNIEnv *env, jclass clazz, jlong window, jdouble xpos,
                                          jdouble ypos) {
    cLastX = cursorX = xpos;
    cLastY = cursorY = ypos;
}

void sendData(short type, int i1, int i2, short i3, short i4) {
    size_t counter = atomic_load_explicit(&eventCounter, memory_order_acquire);
    if (counter < 7999) {
        GLFWInputEvent *event = &events[counter++];
        event->type = type;
        event->i1 = i1;
        event->i2 = i2;
        event->i3 = i3;
        event->i4 = i4;
    }
    atomic_store_explicit(&eventCounter, counter, memory_order_release);
}

void sendDataFloat(short type, float i1, float i2, short i3, short i4) {
    size_t counter = atomic_load_explicit(&eventCounter, memory_order_acquire);
    if (counter < 7999) {
        GLFWInputEvent *event = &events[counter++];
        event->type = type;
        event->f1 = i1;
        event->f2 = i2;
        event->i3 = i3;
        event->i4 = i4;
    }
    atomic_store_explicit(&eventCounter, counter, memory_order_release);
}

void closeGLFWWindow() {
    NSLog(@"Closing GLFW window");

    /*
    jclass glfwClazz = (*runtimeJNIEnvPtr)->FindClass(runtimeJNIEnvPtr, "org/lwjgl/glfw/GLFW");
    assert(glfwClazz != NULL);
    jmethodID glfwMethod = (*runtimeJNIEnvPtr)->GetStaticMethodID(runtimeJNIEnvPtr, glfwMethod, "glfwSetWindowShouldClose", "(JZ)V");
    assert(glfwMethod != NULL);
    
    (*runtimeJNIEnvPtr)->CallStaticVoidMethod(
        runtimeJNIEnvPtr,
        glfwClazz, glfwMethod,
        (jlong) showingWindow, JNI_TRUE
    );
    */
    exit(-1);
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
    int barY = physicalHeight - barHeight;
    if (y < barY) return -1;

    int barWidth = mcscale(180);
    int barX = (physicalWidth / 2) - (barWidth / 2);
    if (x < barX || x >= barX + barWidth) return -1;

    return hotbarKeys[(int) MathUtils_map(x, barX, barX + barWidth, 0, 9)];
}

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_updateMCGuiScale(JNIEnv* env, jclass clazz, jint scale) {
    guiScale = scale;
}

JNIEXPORT jstring JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeClipboard(JNIEnv* env, jclass clazz, jint action, jstring copySrc) {
    NSDebugLog(@"Debug: Clipboard access is going on\n");
    return UIKit_accessClipboard(env, action, copySrc);
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSetGrabbing(JNIEnv* env, jclass clazz, jboolean grabbing, jfloat xset, jfloat yset) {
    isGrabbing = grabbing;

    dispatch_async(dispatch_get_main_queue(), ^{
        SurfaceViewController *vc = ((SurfaceViewController *)UIWindow.mainWindow.rootViewController);
        [vc updateGrabState];
    });
}

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeIsGrabbing(JNIEnv* env, jclass clazz) {
    return isGrabbing;
}

void CallbackBridge_nativeSetInputReady(BOOL inputReady) {
    isInputReady = inputReady;
    if (inputReady) {
        if (GLFW_invoke_FramebufferSize) {
            GLFW_invoke_FramebufferSize((void*) showingWindow, windowWidth, windowHeight);
        }
        if (GLFW_invoke_WindowSize) {
            GLFW_invoke_FramebufferSize((void*) showingWindow, windowWidth, windowHeight);
        }
    }
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
void CallbackBridge_nativeSendCursorPos(char event, CGFloat x, CGFloat y) {
    if (!GLFW_invoke_CursorPos || !isInputReady) return;

    switch (event) {
        case ACTION_DOWN:
        case ACTION_UP:
            if (!isGrabbing) {
                cursorX = x;
                cursorY = y;
            }
            break;

        case ACTION_MOVE:
            if (isGrabbing) {
                cursorX += x - cLastX;
                cursorY += y - cLastY;
            } else {
                cursorX = x;
                cursorY = y;
            }
            break;

        case ACTION_MOVE_MOTION:
            cursorX += x;
            cursorY += y;
            break;
    }

    if (!isUseStackQueueCall) {
        GLFW_invoke_CursorPos((void*) showingWindow, (double) cursorX, (double) cursorY);
    }
}

char getKeyModifiers(int key, int action) {
    static char currMods;
    char mod;
    switch (key) {
        case GLFW_KEY_LEFT_SHIFT:
            mod = GLFW_MOD_SHIFT;
            break;
        case GLFW_KEY_LEFT_CONTROL:
            mod = GLFW_MOD_CONTROL;
            break;
        case GLFW_KEY_LEFT_ALT:
            mod = GLFW_MOD_ALT;
            break;
        case GLFW_KEY_CAPS_LOCK:
            mod = GLFW_MOD_CAPS_LOCK;
            break;
        case GLFW_KEY_NUM_LOCK:
            mod = GLFW_MOD_NUM_LOCK;
            break;
        default:
            return currMods;
    }
    if (action) {
        currMods |= mod;
    } else {
        currMods &= ~mod;
    }
    return currMods;
}

void CallbackBridge_nativeSendKey(int key, int scancode, int action, int mods) {
    if (GLFW_invoke_Key && isInputReady) {
        keyDownBuffer[MAX(0, key-31)]=(jbyte)action;
        if (mods == 0) {
            mods = getKeyModifiers(key, action);
        }

        if (isUseStackQueueCall) {
            sendData(EVENT_TYPE_KEY, key, scancode, action, mods);
        } else {
            GLFW_invoke_Key((void*) showingWindow, key, scancode, action, mods);
        }
    }

    // On macOS, Minecraft expects the Command key
    if (key == GLFW_KEY_LEFT_CONTROL) {
        CallbackBridge_nativeSendKey(GLFW_KEY_LEFT_SUPER, 0, action, mods);
    } else if (key == GLFW_KEY_RIGHT_CONTROL) {
        CallbackBridge_nativeSendKey(GLFW_KEY_RIGHT_SUPER, 0, action, mods);
    }
}

void CallbackBridge_nativeSendMouseButton(int button, int action, int mods) {
    if (isInputReady) {
        if (button == -1) {
        } else if (GLFW_invoke_MouseButton) {
            if (mods == 0) {
                mods = getKeyModifiers(0, action);
            }

            if (isUseStackQueueCall) {
                sendData(EVENT_TYPE_MOUSE_BUTTON, button, action, mods, 0);
            } else {
                GLFW_invoke_MouseButton((void*) showingWindow, button, action, mods);
            }
        }
    }
}

void CallbackBridge_nativeSendScreenSize(int width, int height) {
    windowWidth = width;
    windowHeight = height;
    
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
            sendDataFloat(EVENT_TYPE_SCROLL, xoffset, yoffset, 0, 0);
        } else {
            GLFW_invoke_Scroll((void*) showingWindow, (double) xoffset, (double) yoffset);
        }
    }
}

JNIEXPORT void JNICALL Java_org_lwjgl_glfw_GLFW_nglfwSetShowingWindow(JNIEnv* env, jclass clazz, jlong window) {
    showingWindow = (long) window;
}

void CallbackBridge_pauseGameIfNeed() {
    if (isGrabbing) {
        CallbackBridge_nativeSendKey(GLFW_KEY_ESCAPE, 0, 1, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_ESCAPE, 0, 0, 0);
    }
}
