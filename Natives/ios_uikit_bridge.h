#pragma once
#import <UIKit/UIKit.h>
#include "jni.h"

#define CLIPBOARD_COPY 2000
#define CLIPBOARD_PASTE 2001

UIViewController* tmpRootVC;

void showDialog(NSString* title, NSString* message);
UIAlertController* createLoadingAlert(NSString* message);
jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc);
void UIKit_updateProgress(float progress, const char* message);
void UIKit_launchMinecraftSurfaceVC();
void UIKit_returnToSplitView();
void launchInitialViewController(UIWindow *window);
