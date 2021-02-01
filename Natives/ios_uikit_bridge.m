#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "LauncherViewController.h"
#import "SurfaceViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

void UIKit_updateProgress(float progress, char* message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        install_progress_bar.progress = progress;
        install_progress_text.text = [NSString stringWithUTF8String:message];
    });
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
