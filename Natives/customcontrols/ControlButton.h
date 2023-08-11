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

@property BOOL canBeHidden, displayInGame, displayInMenu, isToggleOn;
@property(nonatomic) NSMutableDictionary* properties;
@property(nonatomic) UIColor* savedBackgroundColor;

+ (id)buttonWithProperties:(NSMutableDictionary *)propArray;

- (CGFloat)calculateDynamicPos:(NSString *)string;
- (BOOL)canSnap:(ControlButton *)button;
- (NSString *)generateDynamicX:(CGFloat)x;
- (NSString *)generateDynamicY:(CGFloat)y;
- (void)snapAndAlignX:(CGFloat)x Y:(CGFloat)y;
- (void)preProcessProperties;
- (void)update;

@end
