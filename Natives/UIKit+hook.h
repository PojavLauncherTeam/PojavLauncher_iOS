#import <UIKit/UIKit.h>

#define realUIIdiom UIDevice.currentDevice.hook_userInterfaceIdiom

@interface UIDevice(hook)
- (UIUserInterfaceIdiom)hook_userInterfaceIdiom;
@end
