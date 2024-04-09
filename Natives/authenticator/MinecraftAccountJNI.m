#import "BaseAuthenticator.h"
#include "jni.h"

JNIEXPORT jstring JNICALL Java_net_kdt_pojavlaunch_value_MinecraftAccount_getAccessTokenFromKeychain(JNIEnv *env, jclass clazz, jstring xuid) {
    // This function should only be called once
    static BOOL called = NO;
    if (called) {
        abort();
    }
    called = YES;

    const char *xuidC = (*env)->GetStringUTFChars(env, xuid, 0);
    NSString *accessToken = [NSClassFromString(@"MicrosoftAuthenticator") tokenDataOfProfile:@(xuidC)][@"accessToken"];
    (*env)->ReleaseStringUTFChars(env, xuid, xuidC);
    return (*env)->NewStringUTF(env, accessToken.UTF8String);
}
