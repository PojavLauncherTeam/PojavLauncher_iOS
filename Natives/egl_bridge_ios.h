#pragma once

#ifndef USE_EGL

#import "MGLKit.h"
#include "jni.h"

MGLContext *glContext;

jboolean makeSharedContext();
jboolean clearCurrentContext();

#endif
