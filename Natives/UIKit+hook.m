#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LauncherPreferences.h"
#import "UIKit+hook.h"
#import "utils.h"

void swizzle(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, swizzledAction));
}

void swizzleClass(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getClassMethod(class, originalAction), class_getClassMethod(class, swizzledAction));
}

void init_hookUIKitConstructor(void) {
    swizzle(UIDevice.class, @selector(userInterfaceIdiom), @selector(hook_userInterfaceIdiom));
    swizzle(UIView.class, @selector(didMoveToSuperview), @selector(hook_didMoveToSuperview));
    swizzle(UIView.class, @selector(setFrame:), @selector(hook_setFrame:));

    if (realUIIdiom == UIUserInterfaceIdiomTV) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            // If you are about to test iPadOS idiom on tvOS, there's no better way for this
            class_setSuperclass(NSClassFromString(@"UITableConstants_Pad"), NSClassFromString(@"UITableConstants_TV"));
        }
        swizzle(UINavigationController.class, @selector(toolbar), @selector(hook_toolbar));
        swizzle(UINavigationController.class, @selector(setToolbar:), @selector(hook_setToolbar:));
        swizzleClass(UISwitch.class, @selector(visualElementForTraitCollection:), @selector(hook_visualElementForTraitCollection:));
   }
}

@implementation UIDevice(hook)

- (UIUserInterfaceIdiom)hook_userInterfaceIdiom {
    if ([getPreference(@"debug_ipad_ui") boolValue]) {
        return UIUserInterfaceIdiomPad;
    } else if (self.hook_userInterfaceIdiom == UIUserInterfaceIdiomTV) {
        return self.hook_userInterfaceIdiom;
    } else {
        return UIUserInterfaceIdiomPhone;
    }
}

@end

// Patch: unimplemented get/set UIToolbar functions on tvOS
@implementation UINavigationController(hook)
const NSString *toolbarKey = @"toolbar";

- (UIToolbar *)hook_toolbar {
    UIToolbar *toolbar = objc_getAssociatedObject(self, &toolbarKey);
    if (toolbar == nil) {
        toolbar = [[UIToolbar alloc] initWithFrame:
            CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height - 100,
            self.view.bounds.size.width, 100)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        if (@available(iOS 13.0, *)) {
            toolbar.backgroundColor = UIColor.systemBackgroundColor;
        }
        objc_setAssociatedObject(self, &toolbarKey, toolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self performSelector:@selector(_configureToolbar)];
    }
    return toolbar;
}

- (void)hook_setToolbar:(UIToolbar *)toolbar {
    objc_setAssociatedObject(self, &toolbarKey, toolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

// Patch: UISwitch crashes if platform == tvOS
@implementation UISwitch(hook)
+ (id)hook_visualElementForTraitCollection:(UITraitCollection *)collection {
    if (collection.userInterfaceIdiom == UIUserInterfaceIdiomTV) {
        UITraitCollection *override = [UITraitCollection traitCollectionWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];
        UITraitCollection *new = [UITraitCollection traitCollectionWithTraitsFromCollections:@[collection, override]];
        return [self hook_visualElementForTraitCollection:new];
    }
    return [self hook_visualElementForTraitCollection:collection];
}
@end

@implementation UITraitCollection(hook)

- (UIUserInterfaceSizeClass)horizontalSizeClass {
    return UIUserInterfaceSizeClassRegular;
}

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
    if (debugBoundsEnabled) {
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
    if (self.frame.size.width < self.frame.size.height) {
        return UIEdgeInsetsMake(44, 0, 44, 0);
    } else {
        return UIEdgeInsetsMake(0, 44, 21, 44);
    }
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

UIWindow* currentWindowInScene(BOOL external) {
    id delegate = UIApplication.sharedApplication.delegate;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes.allObjects) {
            delegate = scene.delegate;
            if (external != (scene.session.role == UIWindowSceneSessionRoleApplication)) {
                break;
            }
        }
    }
    return [delegate window];
}

UIWindow* currentWindow() {
    return currentWindowInScene(0);
}

UIViewController* currentVC() {
    return currentWindow().visibleViewController;
}
