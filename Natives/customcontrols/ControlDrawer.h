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
- (ControlSubButton *)addButton:(ControlSubButton *)button;
- (void)restoreButtonVisibility;
- (void)syncButtons;

@end
