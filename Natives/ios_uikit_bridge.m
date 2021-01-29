#import <UIKit/UIKit.h>

#include "ios_uikit_bridge.h"
#include "utils.h"

void UIKit_runOnUIThread(jobject callback) {
    dispatch_async(dispatch_get_main_queue(), ^{
        JNIEnv *env;
        (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, &env, JNI_VERSION_1_4);
        jclass clazz = (*env)->GetObjectClass(env, callback);
        jmethodID method = (*env)->GetStaticMethodID(env, clazz, "onCallback", "()V");
        (*env)->CallStaticVoidMethod(
            env, callback, method
        );
    });
}
