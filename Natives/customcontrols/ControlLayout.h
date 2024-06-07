#import <UIKit/UIKit.h>

@interface CALayer(private)
@property(atomic, assign) NSUInteger disableUpdateMask;
@end

@interface ControlLayout : UIView

@property(nonatomic) NSMutableDictionary *layoutDictionary;

- (void)loadControlLayout:(NSMutableDictionary *)layoutDictionary;
- (void)loadControlFile:(NSString *)path;
- (void)removeAllButtons;
- (void)hideViewFromCapture:(BOOL)hide;

@end
