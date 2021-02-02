#ifndef _BINARY_UTILS_H_
#define _BINARY_UTILS_H_

#include <stdbool.h>
#include "jni.h"

#define ACTION_DOWN 0
#define ACTION_UP 1
#define ACTION_MOVE 2

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

void* GL4ES_HANDLE;

JavaVM* runtimeJavaVMPtr;
JNIEnv* runtimeJNIEnvPtr_ANDROID;
JNIEnv* runtimeJNIEnvPtr_JRE;

JavaVM* dalvikJavaVMPtr;
JNIEnv* dalvikJNIEnvPtr_ANDROID;
JNIEnv* dalvikJNIEnvPtr_JRE;

long showingWindow;

bool isInputReady, isCursorEntered, isPrepareGrabPos, isUseStackQueueCall;

int savedWidth, savedHeight;

jboolean attachThread(bool isAndroid, JNIEnv** secondJNIEnvPtr);
char** convert_to_char_array(JNIEnv *env, jobjectArray jstringArray);
jobjectArray convert_from_char_array(JNIEnv *env, char **charArray, int num_rows);
void free_char_array(JNIEnv *env, jobjectArray jstringArray, const char **charArray);

void sendData(int type, int i1, int i2, int i3, int i4);

void closeGLFWWindow();
void callback_LauncherViewController_installMinecraft();
void callback_SurfaceViewController_launchMinecraft(int width, int height);
void callback_SurfaceViewController_onTouch(int event, int x, int y);

#endif // _BINARY_UTILS_H_

