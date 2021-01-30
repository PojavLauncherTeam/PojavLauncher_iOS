#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "LauncherViewController.h"
#import "SurfaceViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

void UIKit_runOnUIThread(jobject callback) {
    dispatch_async(dispatch_get_main_queue(), ^{
        JNIEnv *env;
        (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, &env, JNI_VERSION_1_4);
        jclass clazz = (*env)->GetObjectClass(env, callback);
        jmethodID method = (*env)->GetMethodID(env, clazz, "onCallback", "()V");
        (*env)->CallVoidMethod(
            env, callback, method
        );
    });
}

void UIKit_updateProgress(float progress, char* message) {
    install_progress_bar.progress = progress;
    install_progress_text.text = [NSString stringWithUTF8String:message];
}

void UIKit_launchMinecraftSurfaceVC() {
    LauncherViewController *rootController = (LauncherViewController*)[[(AppDelegate*) [[UIApplication sharedApplication]delegate] window] rootViewController];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MinecraftSurface" bundle:nil];
    SurfaceViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MinecraftSurfaceVC"];
    [rootController presentViewController:vc animated:YES completion:nil];
}
