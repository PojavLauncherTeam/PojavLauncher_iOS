#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LauncherPreferences.h"

void swizzle(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, swizzledAction));
}

__attribute__((constructor)) void hookConstructor(void) {
    swizzle(UIDevice.class, @selector(userInterfaceIdiom), @selector(hook_userInterfaceIdiom));
    swizzle(UIToolbar.class, @selector(sizeThatFits:), @selector(hook_sizeThatFits:));
    swizzle(UIView.class, @selector(didMoveToSuperview), @selector(hook_didMoveToSuperview));
    swizzle(UIView.class, @selector(setFrame:), @selector(hook_setFrame:));
}

@implementation UIDevice(hook)

- (UIUserInterfaceIdiom)hook_userInterfaceIdiom {
    id value = getPreference(@"debug_ipad_ui");
    if (value == nil) {
        return self.hook_userInterfaceIdiom;
    }
    return [value boolValue] ? UIUserInterfaceIdiomPad : UIUserInterfaceIdiomPhone;
}

@end

@implementation UIToolbar(hook)

- (CGSize)hook_sizeThatFits:(CGSize)size {
    // Make the toolbar taller
    CGSize ret = [self hook_sizeThatFits:size];
    ret.height += 50;
    return ret;
}

@end

@implementation UITraitCollection(hook)

- (UIUserInterfaceSizeClass)verticalSizeClass {
    return UIUserInterfaceSizeClassRegular;
}

@end

@implementation UIView(hook)
const NSString *cornerLayerKey = @"cornerLayer";

- (void)updateCornerLayer {
    CAShapeLayer *cornerLayer = objc_getAssociatedObject(self, &cornerLayerKey);
    NSNumber *cornerWidth = @5;
    NSNumber *cornerSpaceW = @(self.frame.size.width-10);
    NSNumber *cornerSpaceH = @(self.frame.size.height-10);
    cornerLayer.lineDashPattern = @[cornerWidth,cornerSpaceW,cornerWidth,@0,cornerWidth,cornerSpaceH,cornerWidth,@0,cornerWidth,cornerSpaceW,cornerWidth,@0,cornerWidth,cornerSpaceH,cornerWidth];
    cornerLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)].CGPath;
    if ([getPreference(@"debug_show_layout_overlap") boolValue]) {
        cornerLayer.fillColor = [UIColor.yellowColor colorWithAlphaComponent:0.1].CGColor;
    } else {
        cornerLayer.fillColor = nil;
    }
}

- (void)hook_didMoveToSuperview {
    if ([getPreference(@"debug_show_layout_bounds") boolValue]) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = UIColor.redColor.CGColor;
        if (self.layer.sublayers.count == 0) {
            CAShapeLayer *cornerLayer = [CAShapeLayer layer];
            cornerLayer.strokeColor = UIColor.blueColor.CGColor;
            cornerLayer.lineWidth = 1;
            [self.layer addSublayer:cornerLayer];
            objc_setAssociatedObject(self, &cornerLayerKey, cornerLayer, OBJC_ASSOCIATION_ASSIGN);
            [self updateCornerLayer];
        }
    }
    [self hook_didMoveToSuperview];
}

- (void)hook_setFrame:(CGRect)frame {
    [self hook_setFrame:frame];
    [self updateCornerLayer];
}

@end

@implementation UIWindow(hook)

// Simulate safe area on iPhones without notch
/*
- (UIEdgeInsets)safeAreaInsets {
    return UIEdgeInsetsMake(0, 44, 21, 44);
}
*/

- (UIViewController *)visibleViewController {
    UIViewController *current = self.rootViewController;
    while (current.presentedViewController) {
        if ([current.presentedViewController isKindOfClass:UIAlertController.class] || [current.presentedViewController isKindOfClass:NSClassFromString(@"UIInputWindowController")]) {
            break;
        }
        current = current.presentedViewController;
    }
    if ([current isKindOfClass:UINavigationController.class]) {
        return [(UINavigationController *)self.rootViewController visibleViewController];
    } else {
        return current;
    }
}

@end


// This forces the navigation bar to keep its height (44dp) in landscape
@implementation UINavigationBar(forceFullHeightInLandscape)
- (BOOL)forceFullHeightInLandscape {
    return YES;
    //UIScreen.mainScreen.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}
@end

UIWindow* currentWindow() {
    id delegate = UIApplication.sharedApplication.delegate;
    if (@available(iOS 13.0, *)) {
        delegate = UIApplication.sharedApplication.connectedScenes.anyObject.delegate;
    }
    return [delegate window];
}

UIViewController* currentVC() {
    return currentWindow().visibleViewController;
}
