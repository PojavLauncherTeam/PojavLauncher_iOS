
#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "LauncherViewController.h"
#import "SurfaceViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

#define CLIPBOARD_COPY 2000
#define CLIPBOARD_PASTE 2001
// Maybe CLIPBOARD_OPENURL then?

jclass class_CTCScreen;
jmethodID method_GetRGB;

jclass class_CTCAndroidInput;
jmethodID method_ReceiveInput;

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

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_showError(JNIEnv* env, jclass clazz, jstring title, jstring message, jboolean exitIfOk) {
    const char *title_c = (*env)->GetStringUTFChars(env, title, 0);
    const char *message_c = (*env)->GetStringUTFChars(env, message, 0);
    NSString *title_o = @(title_c);
    NSString *message_o = @(message_c);
    (*env)->ReleaseStringUTFChars(env, title, title_c);
    (*env)->ReleaseStringUTFChars(env, message, message_c);

dispatch_async(dispatch_get_main_queue(), ^{

    UIAlertController* alert = [UIAlertController
        alertControllerWithTitle:title_o message:message_o
        preferredStyle:UIAlertControllerStyleAlert];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *atrStr = [[NSMutableAttributedString alloc] initWithString:message_o attributes:@{NSParagraphStyleAttributeName:style,NSFontAttributeName:[UIFont systemFontOfSize:13.0]}];

    [alert setValue:atrStr forKey:@"attributedMessage"];

    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            if (exitIfOk == JNI_TRUE) {
                exit(-1);
            }
        }];
    [alert addAction:okAction];
    
    UIAlertAction* copyAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            UIPasteboard.generalPasteboard.string = message_o;
            if (exitIfOk == JNI_TRUE) {
                exit(-1);
            }
        }];
    [alert addAction:copyAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
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

void UIKit_updateProgress(float progress, const char* message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        install_progress_bar.progress = progress;
        install_progress_text.text = [[NSString alloc] initWithUTF8String:message];
        // @(message);
    });
}

void UIKit_launchJarFile(const char* filepath) {
    jclass uikitBridgeClass = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/kdt/pojavlaunch/uikit/UIKit");
    assert(uikitBridgeClass != NULL);

    jstring filepathStr = (*runtimeJNIEnvPtr_JRE)->NewStringUTF(runtimeJNIEnvPtr_JRE, filepath);
    jmethodID method = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, uikitBridgeClass, "callback_JavaGUIViewController_launchJarFile", "(Ljava/lang/String;II)V");
    assert(method != NULL);

    (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
        runtimeJNIEnvPtr_JRE,
        uikitBridgeClass, method,
        filepathStr,
        savedWidth, savedHeight
    );
    (*runtimeJNIEnvPtr_JRE)->DeleteLocalRef(runtimeJNIEnvPtr_JRE, filepathStr);
}

void UIKit_launchMinecraftSurfaceVC() {
#if 1 // debug
    NSLog(@"DBG: are we on main thread = %d", [NSThread isMainThread]);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"DBG: INSIDE main queue: are we on main thread = %d", [NSThread isMainThread]);
        UIViewController *rootController = UIApplication.sharedApplication.windows.lastObject.rootViewController;
        NSLog(@"DBG: Got rootController = %p", rootController);
        SurfaceViewController *vc = [[SurfaceViewController alloc] init];
        NSLog(@"DBG: Got Surface VC = %p", vc);
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        NSLog(@"DBG: set present style");
        [rootController presentViewController:vc animated:YES completion:nil];
        NSLog(@"DBG: presented vc");
        // rootController.childForScreenEdgesDeferringSystemGestures = vc;
    });
#else
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootController = UIApplication.sharedApplication.windows.lastObject.rootViewController;
        SurfaceViewController *vc = [[SurfaceViewController alloc] init];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [rootController presentViewController:vc animated:YES completion:nil];
        // rootController.childForScreenEdgesDeferringSystemGestures = vc;
    });
#endif
}
