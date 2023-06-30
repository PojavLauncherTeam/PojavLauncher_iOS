#import <UIKit/UIKit.h>

#define realUIIdiom UIDevice.currentDevice.hook_userInterfaceIdiom

@interface UIDevice(hook)
- (UIUserInterfaceIdiom)hook_userInterfaceIdiom;
@end

// private functions
@interface UIContextMenuInteraction(private)
- (void)_presentMenuAtLocation:(CGPoint)location;
@end
@interface _UIContextMenuStyle : NSObject <NSCopying>
@property(nonatomic) NSInteger preferredLayout;
+ (instancetype)defaultStyle;
@end

@interface UIImage(private)
- (UIImage *)_imageWithSize:(CGSize)size;
@end
