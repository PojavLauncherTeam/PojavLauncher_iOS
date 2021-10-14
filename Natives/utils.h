#pragma once

#import "MGLKit.h"
#include <stdbool.h>
#include "jni.h"

#define ACTION_DOWN 0
#define ACTION_UP 1
#define ACTION_MOVE 2

#define BUTTON1_DOWN_MASK 1 << 10 // left btn
#define BUTTON2_DOWN_MASK 1 << 11 // mid btn
#define BUTTON3_DOWN_MASK 1 << 12 // right btn

#define EVENT_TYPE_CHAR 1000
#define EVENT_TYPE_CHAR_MODS 1001
#define EVENT_TYPE_CURSOR_ENTER 1002
#define EVENT_TYPE_CURSOR_POS 1003
#define EVENT_TYPE_FRAMEBUFFER_SIZE 1004
#define EVENT_TYPE_KEY 1005
#define EVENT_TYPE_MOUSE_BUTTON 1006
#define EVENT_TYPE_SCROLL 1007
#define EVENT_TYPE_WINDOW_POS 1008
#define EVENT_TYPE_WINDOW_SIZE 1009

#define SPECIALBTN_KEYBOARD -1
#define SPECIALBTN_TOGGLECTRL -2
#define SPECIALBTN_MOUSEPRI -3
#define SPECIALBTN_MOUSESEC -4
#define SPECIALBTN_VIRTUALMOUSE -5
#define SPECIALBTN_MOUSEMID -6
#define SPECIALBTN_SCROLLUP -7
#define SPECIALBTN_SCROLLDOWN -8

static float resolutionScale = 1.0;
BOOL isControlModifiable;

UIViewController *viewController;

void* gbuffer; // OSMesa framebuffer

JavaVM* runtimeJavaVMPtr;
JNIEnv* runtimeJNIEnvPtr_ANDROID;
JNIEnv* runtimeJNIEnvPtr_JRE;

//JNIEnv* dalvikJNIEnvPtr_ANDROID;
//JNIEnv* dalvikJNIEnvPtr_JRE;

long showingWindow;

bool isInputReady, isCursorEntered, isPrepareGrabPos, isUseStackQueueCall;

jboolean isGrabbing;

int savedWidth, savedHeight;

BOOL virtualMouseEnabled;

CGFloat MathUtils_dist(CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2);
CGFloat dpToPx(CGFloat dp);
CGFloat pxToDp(CGFloat px);
void _CGDataProviderReleaseBytePointerCallback(void *info,const void *pointer);

jboolean attachThread(bool isAndroid, JNIEnv** secondJNIEnvPtr);
char** convert_to_char_array(JNIEnv *env, jobjectArray jstringArray);
jobjectArray convert_from_char_array(JNIEnv *env, char **charArray, int num_rows);
void free_char_array(JNIEnv *env, jobjectArray jstringArray, char **charArray);
jstring convertStringJVM(JNIEnv* srcEnv, JNIEnv* dstEnv, jstring srcStr);

void sendData(int type, int i1, int i2, int i3, int i4);

void closeGLFWWindow();
void callback_LauncherViewController_installMinecraft();
void callback_SurfaceViewController_launchMinecraft(int width, int height);
void callback_SurfaceViewController_onTouch(int event, int x, int y);
int callback_SurfaceViewController_touchHotbar(int x, int y);

JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendChar(JNIEnv* env, jclass clazz, jchar codepoint /* jint codepoint */);
JNIEXPORT jboolean JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(JNIEnv* env, jclass clazz, jchar codepoint, jint mods);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorPos(JNIEnv* env, jclass clazz, jint x, jint y);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(JNIEnv* env, jclass clazz, jint key, jint scancode, jint action, jint mods);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendKeycode(JNIEnv* env, jclass clazz, jint keycode, jchar keychar, jint scancode, jint action, jint mods);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(JNIEnv* env, jclass clazz, jint button, jint action, jint mods);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendScreenSize(JNIEnv* env, jclass clazz, jint width, jint height);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendScroll(JNIEnv* env, jclass clazz, jdouble xoffset, jdouble yoffset);
JNIEXPORT void JNICALL Java_org_lwjgl_glfw_CallbackBridge_nativeSendWindowPos(JNIEnv* env, jclass clazz, jint x, jint y);


