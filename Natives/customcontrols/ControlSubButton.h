#import <UIKit/UIKit.h>
#import "ControlDrawer.h"

@class ControlDrawer;

@interface ControlSubButton : ControlButton {
}

@property(nonatomic, weak) ControlDrawer* parentDrawer;

@end
