#pragma once
#import <UIKit/UIKit.h>
#include "jni.h"

UIViewController* tmpRootVC;

void showDialog(NSString* title, NSString* message);
UIAlertController* createLoadingAlert(NSString* message);
jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc);
void UIKit_updateProgress(float progress, const char* message);
void UIKit_launchMinecraftSurfaceVC();
void UIKit_returnToSplitView();
void launchInitialViewController(UIWindow *window);
