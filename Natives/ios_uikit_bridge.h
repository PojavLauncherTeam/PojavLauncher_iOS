#pragma once
#include "jni.h"

void UIKit_runOnUIThread(jobject callback);
void UIKit_updateProgress(float progress, char* message);
void UIKit_launchMinecraftSurfaceVC();
