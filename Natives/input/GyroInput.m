#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import "GyroInput.h"
#import "../SurfaceViewController.h"
#import "../utils.h"

@implementation GyroInput

static CGFloat lastXValue, lastYValue, lastFrameTime;
static CGFloat gyroSensitivity;
static int gyroInvertX;
static BOOL gyroSwapAxis;
static CMMotionManager* cmInstance;

+ (void)updateOrientation {
    UIInterfaceOrientation orientation;
    if (@available(iOS 13.0, *)) {
        orientation = UIApplication.sharedApplication.windows[0].windowScene.interfaceOrientation;
    } else {
        orientation = UIApplication.sharedApplication.statusBarOrientation;
    }
    gyroSwapAxis = UIInterfaceOrientationIsPortrait(orientation);
    // FIXME: camera jumps upon rotating screen
}

+ (void)updateSensitivity:(int)sensitivity invertXAxis:(BOOL)invertX {
    if (cmInstance == nil) {
        cmInstance = [[CMMotionManager alloc] init];
    }
    gyroSensitivity = sensitivity / 100.0;
    if (sensitivity > 0) {
        gyroInvertX = invertX ? 1 : -1;
        [self updateOrientation];
        [cmInstance startDeviceMotionUpdates];
    } else {
        lastXValue = lastYValue = lastFrameTime = 0;
        [cmInstance stopDeviceMotionUpdates];
    }
}

+ (void)tick {
    if (!isGrabbing || gyroSensitivity == 0) {
        lastFrameTime = 0;
        return;
    }

    // Compute delta since last tick time
    CGFloat frameTime = CACurrentMediaTime();
    CGFloat factor = gyroSensitivity;
    if (lastFrameTime != 0) {
        CGFloat deltaTimeScale = (frameTime - lastFrameTime) / (1.0/60.0); // Scale of 1 = 60Hz
        factor *= deltaTimeScale;
    }

    // 100% sensitivity -> 1:1 ratio between real world and ingame camera
    if (gyroSwapAxis) {
        lastXValue = cmInstance.deviceMotion.rotationRate.y / (M_PI*180) * windowWidth * factor * gyroInvertX;
        lastYValue = -cmInstance.deviceMotion.rotationRate.x / (M_PI*360) * windowHeight * factor;
    } else {
        lastXValue = cmInstance.deviceMotion.rotationRate.x / (M_PI*360) * windowWidth * factor * gyroInvertX;
        lastYValue = cmInstance.deviceMotion.rotationRate.y / (M_PI*180) * windowHeight * factor;
    }

    SurfaceViewController *vc = (id)(currentWindow().rootViewController);
    [vc sendTouchPoint:CGPointMake(lastXValue, lastYValue) withEvent:ACTION_MOVE_MOTION];

    lastFrameTime = frameTime;
}

@end
