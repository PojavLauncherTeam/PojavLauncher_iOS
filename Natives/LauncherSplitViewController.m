#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "utils.h"

extern NSMutableDictionary *prefDict;

@interface LauncherSplitViewController ()<UISplitViewControllerDelegate>{
}
@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    setViewBackgroundColor(self.view);
    setDefaultValueForPref(prefDict, @"control_safe_area", NSStringFromUIEdgeInsets(getDefaultSafeArea()));
    if (![getPreference(@"internal_reset_safe_area") boolValue]) {
        setPreference(@"internal_reset_safe_area", @YES);
        setPreference(@"control_safe_area", NSStringFromUIEdgeInsets(getDefaultSafeArea()));
    }

    self.delegate = self;

    UINavigationController *masterVc = [[UINavigationController alloc] initWithRootViewController:[[LauncherMenuViewController alloc] init]];
    LauncherNavigationController *detailVc = [[LauncherNavigationController alloc] initWithRootViewController:[[LauncherNewsViewController alloc] init]];
    detailVc.toolbarHidden = NO;

    self.viewControllers = @[masterVc, detailVc];
    [self changeDisplayModeForSize:self.view.frame.size];
    
    self.maximumPrimaryColumnWidth = self.view.bounds.size.width * 0.95;
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    if (self.preferredDisplayMode != displayMode && self.displayMode != UISplitViewControllerDisplayModeSecondaryOnly) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.preferredDisplayMode = UISplitViewControllerDisplayModeSecondaryOnly;
        });
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self changeDisplayModeForSize:size];
}

- (void)changeDisplayModeForSize:(CGSize)size {
    BOOL isPortrait = size.height > size.width;
    if (self.preferredDisplayMode == 0 || self.displayMode != UISplitViewControllerDisplayModeSecondaryOnly) {
        if([getPreference(@"hidden_sidebar") boolValue] == NO) {
            self.preferredDisplayMode = isPortrait ?
                UISplitViewControllerDisplayModeOneOverSecondary :
                UISplitViewControllerDisplayModeOneBesideSecondary;
        } else {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeSecondaryOnly;
        }
    }
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        self.preferredSplitBehavior = isPortrait ?
            UISplitViewControllerSplitBehaviorOverlay :
            UISplitViewControllerSplitBehaviorTile;
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
