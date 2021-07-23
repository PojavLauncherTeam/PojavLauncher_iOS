#import <UIKit/UIKit.h>

/**
 * Custom controls have similar format as Android.
 *
 * Android       - iOS:
 * ControlButton - same
 * ControlData   - NSDictionary
 */

@interface ControlButton : UIButton {
}

@property (nonatomic, strong) NSMutableDictionary* properties;

+ (id)initWithProperties:(NSMutableDictionary *)propArray;
+ (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency;

@end
