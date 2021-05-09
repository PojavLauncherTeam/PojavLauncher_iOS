#import <UIKit/UIKit.h>

/**
 * Custom controls have same format as Android.
 *
 * Android       - iOS:
 * ControlButton - same
 * ControlData   - NSArray with JSON components
 */

@interface ControlButton : UIButton {
}

@property (nonatomic, retain) NSMutableDictionary* properties;

+ (id)initWithProperties:(NSMutableDictionary *)propArray;
+ (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency;

@end
