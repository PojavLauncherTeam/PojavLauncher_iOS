#import <UIKit/UIKit.h>
#import "ControlButton.h"
#import "ControlSubButton.h"

@class ControlSubButton;

@interface ControlDrawer : ControlButton {
}

@property(nonatomic, strong) NSMutableDictionary* drawerData;
@property(nonatomic, strong) NSMutableArray* buttons;
@property(nonatomic, assign) BOOL areButtonsVisible;

+ (id)buttonWithData:(NSMutableDictionary *)drawerData;
- (void)addButtonProp:(NSMutableDictionary *)properties;
- (void)addButton:(ControlSubButton *)button;
- (void)restoreButtonVisibility;
- (void)syncButtons;

@end
