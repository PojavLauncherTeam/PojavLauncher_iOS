
#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "LauncherViewController.h"
#import "SurfaceViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

#define CLIPBOARD_COPY 2000
#define CLIPBOARD_PASTE 2001
// Maybe CLIPBOARD_OPENURL then?

jboolean skipDownloadAssets;

void internal_showDialog(UIViewController *viewController, NSString* title, NSString* message) {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
        message:message
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {}];
    [alert addAction:okAction];

    [viewController presentViewController:alert animated:YES completion:nil];
}

void showDialog(UIViewController *viewController, NSString* title, NSString* message) {
    if ([NSThread isMainThread] == YES) {
        internal_showDialog(viewController, title, message);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            internal_showDialog(viewController, title, message);
        });
    }
}

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
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *atrStr = [[NSMutableAttributedString alloc] initWithString:@(message_c) attributes:@{NSParagraphStyleAttributeName:style,NSFontAttributeName:[UIFont systemFontOfSize:13.0]}];

    [alert setValue:atrStr forKey:@"attributedMessage"];

    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            (*env)->ReleaseStringUTFChars(env, message, message_c);
            if (exitIfOk == JNI_TRUE) {
                exit(-1);
            }
        }];
    [alert addAction:okAction];
    
    UIAlertAction* copyAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            UIPasteboard.generalPasteboard.string = @(message_c);
            (*env)->ReleaseStringUTFChars(env, message, message_c);
            if (exitIfOk == JNI_TRUE) {
                exit(-1);
            }
        }];
    [alert addAction:copyAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
    
    (*env)->ReleaseStringUTFChars(env, title, title_c);
});
}

jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc) {
    if (action == CLIPBOARD_PASTE) {
        // paste request
        if (UIPasteboard.generalPasteboard.hasStrings) {
            return (*env)->NewStringUTF(env, [UIPasteboard.generalPasteboard.string UTF8String]);
        } else {
            return (*env)->NewStringUTF(env, "");
        }
    } else if (action == CLIPBOARD_COPY) {
        // copy request
        const char* copySrcC = (*env)->GetStringUTFChars(env, copySrc, 0);
        UIPasteboard.generalPasteboard.string = @(copySrcC);
	    (*env)->ReleaseStringUTFChars(env, copySrc, copySrcC);
        return NULL;
    } else {
        // unknown request
        NSLog(@"Warning: unknown clipboard action: %x", action);
        return NULL;
    }
}

jboolean UIKit_updateProgress(float progress, const char* message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        install_progress_bar.progress = progress;
        install_progress_text.text = [[NSString alloc] initWithUTF8String:message];
        // @(message);
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
        UIViewController *rootController = nil;
        if (@available(iOS 13.0, *)) {
            rootController = UIApplication.sharedApplication.windows.lastObject.rootViewController;
        } else {
            rootController =(UIViewController*) [[(AppDelegate*) [[UIApplication sharedApplication]delegate] window] rootViewController];
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MinecraftSurface" bundle:nil];
        SurfaceViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MinecraftSurfaceVC"];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [rootController presentViewController:vc animated:YES completion:nil];
        // rootController.childForScreenEdgesDeferringSystemGestures = vc;
    });
}
