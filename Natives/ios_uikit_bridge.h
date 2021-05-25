#pragma once
#import <UIKit/UIKit.h>
#include "jni.h"

void showDialog(UIViewController *viewController, NSString* title, NSString* message);
jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc);
jboolean UIKit_updateProgress(float progress, const char* message);
void UIKit_launchMinecraftSurfaceVC();
void UIKit_setButtonSkippable();
