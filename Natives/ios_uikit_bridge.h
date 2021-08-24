#pragma once
#import <UIKit/UIKit.h>
#include "jni.h"

void showDialog(UIViewController *viewController, NSString* title, NSString* message);
jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc);
void UIKit_updateProgress(float progress, const char* message);
void UIKit_launchJarFile(const char* filepath);
void UIKit_launchMinecraftSurfaceVC();
