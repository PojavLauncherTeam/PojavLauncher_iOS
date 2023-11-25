//
// Created by maks on 24.09.2022.
//

#ifndef POJAVLAUNCHER_ENVIRON_H
#define POJAVLAUNCHER_ENVIRON_H

#include <stdatomic.h>
#include "jni.h"

typedef struct {
    short type;
    union {
        int i1;
        float f1;
    };
    union {
        int i2;
        float f2;
    };
    short i3;
    short i4;
} GLFWInputEvent;

typedef void GLFW_invoke_Char_func(void* window, unsigned int codepoint);
typedef void GLFW_invoke_CharMods_func(void* window, unsigned int codepoint, int mods);
typedef void GLFW_invoke_CursorEnter_func(void* window, int entered);
typedef void GLFW_invoke_CursorPos_func(void* window, double xpos, double ypos);
typedef void GLFW_invoke_FramebufferSize_func(void* window, int width, int height);
typedef void GLFW_invoke_Key_func(void* window, int key, int scancode, int action, int mods);
typedef void GLFW_invoke_MouseButton_func(void* window, int button, int action, int mods);
typedef void GLFW_invoke_Scroll_func(void* window, double xoffset, double yoffset);
typedef void GLFW_invoke_WindowPos_func(void* window, int x, int y);
typedef void GLFW_invoke_WindowSize_func(void* window, int width, int height);

jclass class_CTCClipboard;
jmethodID method_SystemClipboardDataReceived;

//struct pojav_environ_s {
    //render_window_t* mainWindowBundle;
    //BOOL force_vsync;
    atomic_size_t eventCounter;
    GLFWInputEvent events[8000];
    double cursorX, cursorY, cLastX, cLastY;
    //jmethodID method_accessAndroidClipboard;
    //jmethodID method_onGrabStateChanged;
    //jmethodID method_glfwSetWindowAttrib;
    jmethodID method_internalWindowSizeChanged;
    jclass bridgeClazz;
    jclass vmGlfwClass;
    jboolean isGrabbing;
    jbyte* keyDownBuffer;
    JavaVM* runtimeJavaVMPtr;
    JNIEnv* runtimeJNIEnvPtr;
    //JavaVM* dalvikJavaVMPtr;
    //JNIEnv* dalvikJNIEnvPtr_ANDROID;
    long showingWindow;
    bool isInputReady, isCursorEntered, isUseStackQueueCall;
    //int savedWidth, savedHeight;
    int windowWidth, windowHeight;
    int physicalWidth, physicalHeight;
#define ADD_CALLBACK_WWIN(NAME) \
    GLFW_invoke_##NAME##_func* GLFW_invoke_##NAME;
    ADD_CALLBACK_WWIN(Char);
    ADD_CALLBACK_WWIN(CharMods);
    ADD_CALLBACK_WWIN(CursorEnter);
    ADD_CALLBACK_WWIN(CursorPos);
    ADD_CALLBACK_WWIN(FramebufferSize);
    ADD_CALLBACK_WWIN(Key);
    ADD_CALLBACK_WWIN(MouseButton);
    ADD_CALLBACK_WWIN(Scroll);
    ADD_CALLBACK_WWIN(WindowPos);
    ADD_CALLBACK_WWIN(WindowSize);

#undef ADD_CALLBACK_WWIN
//};

float resolutionScale;
BOOL virtualMouseEnabled, isControlModifiable;

#endif //POJAVLAUNCHER_ENVIRON_H
