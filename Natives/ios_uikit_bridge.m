#import <UIKit/UIKit.h>

#import "AppDelegate.h"
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
        LauncherViewController *rootController = (LauncherViewController*)[[(AppDelegate*) [[UIApplication sharedApplication]delegate] window] rootViewController];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MinecraftSurface" bundle:nil];
        SurfaceViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MinecraftSurfaceVC"];
        [rootController presentViewController:vc animated:YES completion:nil];
    });
}
