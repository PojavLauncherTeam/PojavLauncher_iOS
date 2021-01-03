#pragma once

#include "jni.h"

void *createContext();
void *getCurrentContext();
void *initCurrentContext();
jboolean makeCurrentContext(void *context);
jboolean makeCurrentContextShared(void *context);
jboolean clearCurrentContext();
void flushBuffer();
