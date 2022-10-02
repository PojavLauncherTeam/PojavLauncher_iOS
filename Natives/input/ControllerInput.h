#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

@interface ControllerInput : NSObject

+ (void)initKeycodeTable;
+ (void)registerControllerCallbacks:(GCController *)controller;
+ (void)unregisterControllerCallbacks:(GCController *)controller;
+ (void)tick;

@end
