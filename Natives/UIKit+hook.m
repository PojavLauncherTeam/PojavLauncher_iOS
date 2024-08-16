#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LauncherPreferences.h"
#import "UIKit+hook.h"
#import "utils.h"

__weak UIWindow *mainWindow, *externalWindow;

void swizzle(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, swizzledAction));
}

void swizzleClass(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getClassMethod(class, originalAction), class_getClassMethod(class, swizzledAction));
}

void init_hookUIKitConstructor(void) {
    swizzle(UIDevice.class, @selector(userInterfaceIdiom), @selector(hook_userInterfaceIdiom));
    swizzle(UIImageView.class, @selector(setImage:), @selector(hook_setImage:));

    if (realUIIdiom == UIUserInterfaceIdiomTV) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            // If you are about to test iPadOS idiom on tvOS, there's no better way for this
            class_setSuperclass(NSClassFromString(@"UITableConstants_Pad"), NSClassFromString(@"UITableConstants_TV"));
#pragma clang diagnostic pop
        }
        swizzle(UINavigationController.class, @selector(toolbar), @selector(hook_toolbar));
        swizzle(UINavigationController.class, @selector(setToolbar:), @selector(hook_setToolbar:));
        swizzleClass(UISwitch.class, @selector(visualElementForTraitCollection:), @selector(hook_visualElementForTraitCollection:));
   }
}

@implementation UIDevice(hook)

- (NSString *)completeOSVersion {
    return [NSString stringWithFormat:@"%@ %@ (%@)", self.systemName, self.systemVersion, self.buildVersion];
}

- (UIUserInterfaceIdiom)hook_userInterfaceIdiom {
    if (getPrefBool(@"debug.debug_ipad_ui")) {
        return UIUserInterfaceIdiomPad;
    } else if (self.hook_userInterfaceIdiom == UIUserInterfaceIdiomTV) {
        return self.hook_userInterfaceIdiom;
    } else {
        return UIUserInterfaceIdiomPhone;
    }
}

@end

// Patch: emulate scaleToFill for table views
@implementation UIImageView(hook)

- (BOOL)isSizeFixed {
    return [objc_getAssociatedObject(self, @selector(isSizeFixed)) boolValue];
}

- (void)setIsSizeFixed:(BOOL)fixed {
    objc_setAssociatedObject(self, @selector(isSizeFixed), @(fixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)hook_setImage:(UIImage *)image {
    if (self.isSizeFixed) {
        UIImage *resizedImage = [image _imageWithSize:self.frame.size];
        [self hook_setImage:resizedImage];
    } else {
        [self hook_setImage:image];
    }
}

@end

// Patch: unimplemented get/set UIToolbar functions on tvOS
@implementation UINavigationController(hook)

- (UIToolbar *)hook_toolbar {
    UIToolbar *toolbar = objc_getAssociatedObject(self, @selector(toolbar));
    if (toolbar == nil) {
        toolbar = [[UIToolbar alloc] initWithFrame:
            CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height - 100,
            self.view.bounds.size.width, 100)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        toolbar.backgroundColor = UIColor.systemBackgroundColor;
        objc_setAssociatedObject(self, @selector(toolbar), toolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self performSelector:@selector(_configureToolbar)];
    }
    return toolbar;
}

- (void)hook_setToolbar:(UIToolbar *)toolbar {
    objc_setAssociatedObject(self, @selector(toolbar), toolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

@implementation UIWindow(hook)

+ (UIWindow *)mainWindow {
    return mainWindow;
}

+ (UIWindow *)externalWindow {
    return externalWindow;
}

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

UIViewController* currentVC() {
    return UIWindow.mainWindow.visibleViewController;
}
