#pragma once

#import <UIKit/UIKit.h>

#include <stdbool.h>
#include "jni.h"

// Configuration macros
#if CONFIG_RELEASE == 1
# define CONFIG_TYPE "release"
#else
# define CONFIG_TYPE "debug"
#endif

#ifndef CONFIG_BRANCH
# define CONFIG_BRANCH "unspecified"
#endif

#ifndef CONFIG_COMMIT
# define CONFIG_COMMIT "unspecified"
#endif

// Control button actions
#define ACTION_DOWN 0
#define ACTION_UP 1
#define ACTION_MOVE 2
#define ACTION_MOVE_MOTION 3

#define BUTTON1_DOWN_MASK 1 << 10 // left btn
#define BUTTON2_DOWN_MASK 1 << 11 // mid btn
#define BUTTON3_DOWN_MASK 1 << 12 // right btn

// GLFW event types
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

#define GLFW_FOCUSED 0x00020001
#define GLFW_VISIBLE 0x00020004

#define RENDERER_NAME_GL4ES "libgl4es_114.dylib"
#define RENDERER_NAME_MTL_ANGLE "libtinygl4angle.dylib"
#define RENDERER_NAME_VK_ZINK "libOSMesaOverride.dylib"

#define SPECIALBTN_KEYBOARD -1
#define SPECIALBTN_TOGGLECTRL -2
#define SPECIALBTN_MOUSEPRI -3
#define SPECIALBTN_MOUSESEC -4
#define SPECIALBTN_VIRTUALMOUSE -5
#define SPECIALBTN_MOUSEMID -6
#define SPECIALBTN_SCROLLUP -7
#define SPECIALBTN_SCROLLDOWN -8

JavaVM* runtimeJavaVMPtr;
JNIEnv* runtimeJNIEnvPtr;
//__weak UIViewController *viewController;

#define CS_DEBUGGED 0x10000000
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);
BOOL isJITEnabled();

void* gbuffer; // OSMesa framebuffer
long showingWindow;
int windowWidth, windowHeight;
int physicalWidth, physicalHeight;
bool isInputReady, isCursorEntered, isPrepareGrabPos, isUseStackQueueCall;
jboolean isGrabbing;
BOOL virtualMouseEnabled;

float resolutionScale;
BOOL isControlModifiable;

// Init functions
void init_hookFunctions();
void init_setupMultiDir();

UIWindow* currentWindow();
UIViewController* currentVC();

NSMutableDictionary* parseJSONFromFile(NSString *path);
NSError* saveJSONToFile(NSDictionary *dict, NSString *path);

static inline CGFloat clamp(CGFloat x, CGFloat lower, CGFloat upper) {
    return fmin(upper, fmax(x, lower));
}
CGFloat MathUtils_dist(CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2);
CGFloat MathUtils_map(CGFloat x, CGFloat in_min, CGFloat in_max, CGFloat out_min, CGFloat out_max);
CGFloat dpToPx(CGFloat dp);
CGFloat pxToDp(CGFloat px);
void setButtonPointerInteraction(UIButton *button);
void setViewBackgroundColor(UIView* view);
void _CGDataProviderReleaseBytePointerCallback(void *info,const void *pointer);

jboolean attachThread(bool isAndroid, JNIEnv** secondJNIEnvPtr);

void sendData(int type, CGFloat i1, CGFloat i2, int i3, int i4);

void closeGLFWWindow();
void callback_LauncherViewController_installMinecraft();
void callback_SurfaceViewController_launchMinecraft(int width, int height);
void callback_SurfaceViewController_onTouch(int event, CGFloat x, CGFloat y);
int callback_SurfaceViewController_touchHotbar(CGFloat x, CGFloat y);

BOOL CallbackBridge_nativeSendChar(jchar codepoint /* jint codepoint */);
BOOL CallbackBridge_nativeSendCharMods(jchar codepoint, int mods);
void CallbackBridge_nativeSendCursorPos(CGFloat x, CGFloat y);
void CallbackBridge_nativeSendKey(int key, int scancode, int action, int mods);
void CallbackBridge_nativeSendKeycode(int keycode, char keychar, int scancode, int action, int mods);
void CallbackBridge_nativeSendMouseButton(int button, int action, int mods);
void CallbackBridge_nativeSendScreenSize(int width, int height);
void CallbackBridge_nativeSendScroll(CGFloat xoffset, CGFloat yoffset);
void CallbackBridge_nativeSendWindowPos(jint x, jint y);
void CallbackBridge_sendKeycode(int keycode, jchar keychar, int scancode, int modifiers, BOOL isDown);
void CallbackBridge_setWindowAttrib(int attrib, int value);
