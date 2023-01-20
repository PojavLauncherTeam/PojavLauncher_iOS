#import <UIKit/UIKit.h>

@interface ControlLayout : UIView

@property(nonatomic) NSMutableDictionary *layoutDictionary;

- (void)loadControlLayout:(NSMutableDictionary *)layoutDictionary;
- (void)loadControlFile:(NSString *)path;
- (void)removeAllButtons;

@end
