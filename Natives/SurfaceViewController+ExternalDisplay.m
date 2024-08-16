#import "SceneExternalDelegate.h"
#import "SurfaceViewController.h"
#import "utils.h"

@implementation SurfaceViewController(ExternalDisplay)

- (void)switchToExternalDisplay {
    [self.surfaceView removeFromSuperview];
    [self.mousePointerView removeFromSuperview];

    UILabel *noteLabel = [[UILabel alloc] initWithFrame:self.view.frame];
    noteLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    noteLabel.numberOfLines = 0;
    noteLabel.textAlignment = NSTextAlignmentCenter;
    noteLabel.textColor = UIColor.whiteColor;
    noteLabel.text = localize(@"game.note.airplay", nil);
    [self.touchView addSubview:noteLabel]; 

    UIWindow *secondWindow = UIWindow.externalWindow;
    secondWindow.rootViewController = [[UIViewController alloc] init];
    [secondWindow.rootViewController.view addSubview:self.surfaceView]; 
    [secondWindow.rootViewController.view addSubview:self.mousePointerView];

    secondWindow.hidden = NO;
    [self updateSavedResolution];
}

- (void)switchToInternalDisplay {
    [self.surfaceView removeFromSuperview];
    [self.mousePointerView removeFromSuperview];

    UIWindow *secondWindow = UIWindow.externalWindow;
    secondWindow.hidden = YES;

    [self.touchView.subviews[0] removeFromSuperview];
    [self.touchView addSubview:self.surfaceView]; 
    [self.touchView addSubview:self.mousePointerView];
    [self updateSavedResolution];
}

@end
