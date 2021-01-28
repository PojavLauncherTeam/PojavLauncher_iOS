#pragma once

#ifndef USE_EGL

#import "MGLKit.h"
#include "jni.h"

MGLContext *glContext;
MGLKViewController *viewController;

jboolean makeSharedContext();
jboolean clearCurrentContext();
void swapBuffers();

#endif
