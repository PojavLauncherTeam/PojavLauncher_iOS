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
    CGFloat savedScale = getPrefFloat(@"control.button_scale");
    loadControlObject(self, self.layoutDictionary);

    self.layoutDictionary[@"scaledAt"] = @(savedScale);
}

- (void)loadControlFile:(NSString *)name {
    [self removeAllButtons];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/controlmap/%@", getenv("POJAV_HOME"), name];

    self.layoutDictionary = parseJSONFromFile(controlFilePath);
    if (self.layoutDictionary[@"NSErrorObject"] != nil) {
        showDialog(localize(@"Error", nil), [NSString stringWithFormat:@"Could not open %@: %@", controlFilePath, [self.layoutDictionary[@"NSErrorObject"] localizedDescription]]);
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
        if (![view isKindOfClass:ControlButton.class]) {
            continue;
        }
        [(ControlButton *)view update];
    }

    CGFloat savedScale = getPrefFloat(@"control.button_scale");
    self.layoutDictionary[@"scaledAt"] = @(savedScale);
}

// https://nsantoine.dev/posts/CALayerCaptureHiding
- (void)hideViewFromCapture:(BOOL)hide {
    if ([self.layer respondsToSelector:@selector(disableUpdateMask)]) {
        NSUInteger hideFlag = (1 << 1) | (1 << 4);
        self.layer.disableUpdateMask = hide ? hideFlag : 0;
    }
}

@end
