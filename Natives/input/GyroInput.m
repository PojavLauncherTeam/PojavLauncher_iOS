#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import "GyroInput.h"
#import "../SurfaceViewController.h"
#import "../utils.h"

@implementation GyroInput

static CGFloat lastXValue, lastYValue, lastFrameTime;
static CGFloat gyroSensitivity;
static int gyroInvertX;
static CMMotionManager* cmInstance;

+ (void)updateSensitivity:(int)sensitivity invertXAxis:(BOOL)invertX {
    if (cmInstance == nil) {
        cmInstance = [[CMMotionManager alloc] init];
    }
    gyroSensitivity = sensitivity / 100.0;
    if (sensitivity > 0) {
        gyroInvertX = invertX ? 1 : -1;
        [cmInstance startGyroUpdates];
    } else {
        [cmInstance stopGyroUpdates];
    }
}

+ (void)tick {
    if (!isGrabbing || gyroSensitivity == 0) return;

    // Compute delta since last tick time
    CGFloat frameTime = CACurrentMediaTime();
    CGFloat factor = gyroSensitivity;
    if (lastFrameTime != 0) {
        CGFloat deltaTimeScale = (frameTime - lastFrameTime) / (1.0/60.0); // Scale of 1 = 60Hz
        factor *= deltaTimeScale;
    }

    // 100% sensitivity -> 1:1 ratio between real world and ingame camera
    lastXValue = cmInstance.gyroData.rotationRate.x / (M_PI*360) * windowWidth * factor * gyroInvertX;
    lastYValue = cmInstance.gyroData.rotationRate.y / (M_PI*180) * windowHeight * factor;

    SurfaceViewController *vc = (id)(currentWindow().rootViewController);
    [vc sendTouchPoint:CGPointMake(lastXValue, lastYValue) withEvent:ACTION_MOVE_MOTION];

    lastFrameTime = frameTime;
}

@end
