#import <UIKit/UIKit.h>
#import "ControlButton.h"
#import "ControlSubButton.h"

@class ControlSubButton;

@interface ControlDrawer : ControlButton {
}

@property(nonatomic, strong) NSMutableDictionary* drawerData;
@property(nonatomic, strong) NSMutableArray* buttons;
@property(nonatomic, assign) BOOL areButtonsVisible;

- (void)addButtonProp:(NSMutableDictionary *)properties;
- (void)addButton:(ControlSubButton *)button;

@end
