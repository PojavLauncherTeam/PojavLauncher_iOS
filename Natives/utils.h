#ifndef _BINARY_UTILS_H_
#define _BINARY_UTILS_H_

#include <stdbool.h>
#include "jni.h"

#define ACTION_DOWN 0
#define ACTION_UP 1
#define ACTION_MOVE 2

void* CURR_GL_CONTEXT;
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

void closeGLFWWindow();
void callback_AppDelegate_didFinishLaunching(int width, int height);
void callback_ViewController_onTouch(int event, int x, int y);

#endif // _BINARY_UTILS_H_

