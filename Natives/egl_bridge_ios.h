#pragma once

#include "jni.h"

void *createContext();
void *getCurrentContext();
jboolean makeCurrentContext(void *context);
jboolean clearCurrentContext();
void flushBuffer();
