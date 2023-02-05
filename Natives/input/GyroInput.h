#import <Foundation/Foundation.h>

@interface GyroInput : NSObject

+ (void)updateOrientation;
+ (void)updateSensitivity:(int)sensitivity invertXAxis:(BOOL)invertX;
+ (void)tick;

@end
