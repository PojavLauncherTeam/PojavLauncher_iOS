#pragma once

#ifndef USE_EGL

#import <UIKit/UIKit.h>
#include "jni.h"

// MGLContext *glContext;
UIViewController *viewController;

void initSurface();
void swapBuffers();

#endif
