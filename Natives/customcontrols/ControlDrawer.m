#import "ControlDrawer.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"
#import "../utils.h"

#define DOWN 0
#define LEFT 1
#define UP 2
#define RIGHT 3

@implementation ControlDrawer

+ (id)buttonWithData:(NSMutableDictionary *)drawerData {
    ControlDrawer *instance = [self buttonWithProperties:drawerData[@"properties"]];
    instance.buttons = [[NSMutableArray alloc] init];
    instance.drawerData = drawerData;

    return instance;
}

- (ControlSubButton *)addButton:(ControlSubButton *)button {
    [self.buttons addObject:button];
    button.parentDrawer = self;
    button.hidden = !isControlModifiable;
    return button;
}

- (void)restoreButtonVisibility {
    for (ControlButton *button in self.buttons) {
        button.hidden = !self.areButtonsVisible;
    }
}

- (void)switchButtonVisibility {
    self.areButtonsVisible = !self.areButtonsVisible;
    [self restoreButtonVisibility];
}

// NOTE: Unlike Android's impl, this method uses dp instead of px (no call to dpToPx)
- (void)alignButtons {
    NSString *orientation = (NSString *)self.drawerData[@"orientation"];
    if ([orientation isEqualToString:@"FREE"]) {
        return;
    }

    for (int i = 0; i < self.buttons.count; i++) {
        ControlButton *button = self.buttons[i];
        if ([orientation isEqualToString:@"RIGHT"]) {
            button.properties[@"dynamicX"] = [self generateDynamicX:self.frame.origin.x + ([self.properties[@"width"] floatValue] + 2.0) * (i+1)];
            button.properties[@"dynamicY"] = [self generateDynamicY:self.frame.origin.y];
        } else if ([orientation isEqualToString:@"LEFT"]) {
            button.properties[@"dynamicX"] = [self generateDynamicX:self.frame.origin.x - ([self.properties[@"width"] floatValue] + 2.0) * (i+1)];
            button.properties[@"dynamicY"] = [self generateDynamicY:self.frame.origin.y];
        } else if ([orientation isEqualToString:@"UP"]) {
            button.properties[@"dynamicY"] = [self generateDynamicY:self.frame.origin.y - ([self.properties[@"height"] floatValue] + 2.0) * (i+1)];
            button.properties[@"dynamicX"] = [self generateDynamicX:self.frame.origin.x];
        } else if ([orientation isEqualToString:@"DOWN"]) {
            button.properties[@"dynamicY"] = [self generateDynamicY:self.frame.origin.y + ([self.properties[@"height"] floatValue] + 2.0) * (i+1)];
            button.properties[@"dynamicX"] = [self generateDynamicX:self.frame.origin.x];
        } else {
            NSLog(@"DEBUG: %s: Unsupported button orientation %@", __FILE__, orientation);
        }
        [button update];
    }
}

- (void)resizeButtons {
    for (ControlButton *button in self.buttons) {
        button.properties[@"width"] = self.properties[@"width"];
        button.properties[@"height"] = self.properties[@"height"];
        [button update];
    }
}

- (void)syncButtons {
    [self alignButtons];
    [self resizeButtons];
}

- (void)update {
    [super update];
    [self syncButtons];
}

- (BOOL)containsChild:(ControlButton *)button {
    return [self.buttons containsObject:button];
}

- (void)preProcessProperties {
    [super preProcessProperties];
    self.properties[@"isHideable"] = @(YES);
}

/*
- (void)setHidden:(BOOL)hidden {
    super
}
*/

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (!isControlModifiable) {
        [self switchButtonVisibility];
    }
}

- (BOOL)canSnap:(ControlButton *)button {
    return [super canSnap:button] && ![self containsChild:button];
}

- (void)snapAndAlignX:(CGFloat)x Y:(CGFloat)y {
    [super snapAndAlignX:x Y:y];
    [self alignButtons];
}

@end
