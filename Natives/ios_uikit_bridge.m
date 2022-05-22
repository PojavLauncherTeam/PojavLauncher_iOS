#import "authenticator/BaseAuthenticator.h"
#import "AppDelegate.h"
#import "BKSSystemService.h"
#import "SceneDelegate.h"
#import "LoginViewController.h"
#import "LauncherPreferences.h"
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
    //text.dataDetectorTypes = UIDataDetectorTypeLink;
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
    setPreference(@"internal_launch_on_boot", getPreference(@"restart_before_launch"));
    setPreference(@"internal_selected_account", BaseAuthenticator.current.authData[@"username"]);
    setPreference(@"internal_useStackQueue", @(isUseStackQueueCall ? YES : NO));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([getPreference(@"restart_before_launch") boolValue]) {
            NSURL *url = [NSURL URLWithString:@"pojavlauncher://"];
            BKSSystemService *service = [[NSClassFromString(@"BKSSystemService") alloc] init];
            unsigned int port = [service createClientPort];
            [service openURL:url application:@"net.kdt.pojavlauncher" options:nil clientPort:port withResult:nil];

            // exiting too fast will cause it to fail (race condition?)
            //  [FBSystemService][0xbb88] Caller "PojavLauncher:pid" has a sandbox that does not allow opening URL's.
            //  The request was denied by service delegate (SBMainWorkspace) for reason: Security ("Sandbox check failed for process (PojavLauncher:pid) openURL not allowed").
            // therefore, sleep for 1ms before exit
            usleep(1000);
            exit(0);
        } else {
            SurfaceViewController *vc = [[SurfaceViewController alloc] init];
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [viewController.navigationController pushViewController:vc animated:YES];
        }
    });
}

void launchInitialViewController(UIWindow *window) {
    if ([getPreference(@"internal_launch_on_boot") boolValue]) {
        window.rootViewController = [[SurfaceViewController alloc] init];
    } else {
        LoginViewController *vc = [[LoginViewController alloc] init];
        window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    }
}
