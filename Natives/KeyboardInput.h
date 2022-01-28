#import <UIKit/UIKit.h>

NSMutableDictionary* keycodeTable;

@interface KeyboardInput : NSObject

+ (void)initKeycodeTable;
+ (BOOL)sendKeyEvent:(UIKey *)key down:(BOOL)isDown API_AVAILABLE(ios(13.4));

@end
