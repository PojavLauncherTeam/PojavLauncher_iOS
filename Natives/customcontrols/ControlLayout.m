#import "ControlButton.h"
#import "ControlLayout.h"
#import "ControlSubButton.h"
#import "../utils.h"

@interface ControlLayout ()
@end

@implementation ControlLayout
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
