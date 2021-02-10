#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "LauncherViewController.h"
#import "SurfaceViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

jboolean skipDownloadAssets;

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_showError(JNIEnv* env_unused, jclass clazz, jstring title, jstring message, jboolean exitIfOk) {
dispatch_async(dispatch_get_main_queue(), ^{
    JNIEnv *env;
    (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, (void**) &env, JNI_VERSION_1_4);
    const char* title_c = (*env)->GetStringUTFChars(env, title, 0);
    const char* message_c = (*env)->GetStringUTFChars(env, message, 0);

    UIViewController *viewController = nil;
    if (@available(iOS 13.0, *)) {
        viewController = UIApplication.sharedApplication.windows.lastObject.rootViewController;
    } else {
        viewController = [[(AppDelegate*) [[UIApplication sharedApplication]delegate] window] rootViewController];
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@(title_c)
        message:@(message_c)
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            if (exitIfOk == JNI_TRUE) {
                exit(-1);
            }
        }];

    [alert addAction:defaultAction];
    [viewController presentViewController:alert animated:YES completion:nil];
    
    (*env)->ReleaseStringUTFChars(env, title, title_c);
    (*env)->ReleaseStringUTFChars(env, message, message_c);
});
}

jboolean UIKit_updateProgress(float progress, const char* message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        install_progress_bar.progress = progress;
        install_progress_text.text = [NSString stringWithUTF8String:message];
    });
    return skipDownloadAssets;
}

void UIKit_skipDownloadAssets() {
    [install_button setEnabled:NO];
    skipDownloadAssets = JNI_TRUE;
}

void UIKit_setButtonSkippable() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [install_button setEnabled:YES];
        [install_button setTitle:@"Skip" forState:UIControlStateNormal];
        [install_button addTarget:install_button action:@selector(UIKit_skipDownloadAssets) forControlEvents:UIControlEventTouchUpInside];
    });

    skipDownloadAssets = JNI_FALSE;
}

void UIKit_launchMinecraftSurfaceVC() {
    dispatch_async(dispatch_get_main_queue(), ^{
        LauncherViewController *rootController = nil;
        if (@available(iOS 13.0, *)) {
            rootController = UIApplication.sharedApplication.windows.lastObject.rootViewController;
        } else {
            rootController =(LauncherViewController*) [[(AppDelegate*) [[UIApplication sharedApplication]delegate] window] rootViewController];
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MinecraftSurface" bundle:nil];
        SurfaceViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MinecraftSurfaceVC"];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [rootController presentViewController:vc animated:YES completion:nil];
    });
}
