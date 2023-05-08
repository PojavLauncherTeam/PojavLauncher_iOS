#import <UIKit/UIKit.h>

@interface KeyboardInput : NSObject

+ (void)initKeycodeTable;
+ (BOOL)sendKeyEvent:(UIKey *)key down:(BOOL)isDown;

@end
