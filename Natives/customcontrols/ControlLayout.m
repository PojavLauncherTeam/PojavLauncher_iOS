#import "ControlButton.h"
#import "ControlLayout.h"
#import "ControlSubButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"
#import "../ios_uikit_bridge.h"
#import "../utils.h"

@interface ControlLayout ()
@end

@implementation ControlLayout

- (void)loadControlLayout:(NSMutableDictionary *)layoutDictionary {
    self.layoutDictionary = layoutDictionary;

    CGFloat currentScale = [self.layoutDictionary[@"scaledAt"] floatValue];
    CGFloat savedScale = [getPreference(@"button_scale") floatValue];
    loadControlObject(self, self.layoutDictionary);

    self.layoutDictionary[@"scaledAt"] = @(savedScale);
}

- (void)loadControlFile:(NSString *)name {
    [self removeAllButtons];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/controlmap/%@", getenv("POJAV_HOME"), name];

    self.layoutDictionary = parseJSONFromFile(controlFilePath);
    if (self.layoutDictionary[@"error"] != nil) {
        showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Could not open %@: %@", controlFilePath, [self.layoutDictionary[@"error"] localizedDescription]]);
        return;
    }
    [self loadControlLayout:self.layoutDictionary];
}

- (void)removeAllButtons {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.layoutDictionary removeAllObjects];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(actionMenuExit:) ||
        action == @selector(actionMenuSave:) ||
        action == @selector(actionMenuLoad:) ||
        action == @selector(actionMenuSetDef:) ||
        action == @selector(actionMenuAddButton:) ||
        action == @selector(actionMenuAddDrawer:) ||
        action == @selector(actionMenuAddSubButton:) ||
        action == @selector(actionMenuBtnCopy:) ||
        action == @selector(actionMenuBtnDelete:) ||
        action == @selector(actionMenuBtnEdit:) ||
        action == @selector(actionMenuBtnSafeArea:);
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if (result == self && !isControlModifiable) {
        return nil;
    }
    return result;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    for (UIView *view in self.subviews) {
        if (![view isKindOfClass:ControlButton.class] ||
          ([view isKindOfClass:ControlSubButton.class] &&
          ![((ControlSubButton *)view).parentDrawer.drawerData[@"orientation"] isEqualToString:@"FREE"])) {
            continue;
        }
        [(ControlButton *)view update];
    }
}

@end
