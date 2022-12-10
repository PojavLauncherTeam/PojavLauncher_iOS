#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
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
    setDefaultValueForPref(prefDict, @"control_safe_area", NSStringFromCGRect(getDefaultSafeArea()));

    self.delegate = self;
    [self changeDisplayModeForSize:self.view.frame.size];

    LauncherMenuViewController *masterVc = [[LauncherMenuViewController alloc] init];
    LauncherNavigationController *detailVc = [[LauncherNavigationController alloc] init];
    detailVc.toolbarHidden = NO;

    self.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:masterVc], detailVc];

    if(roundf([[NSProcessInfo processInfo] physicalMemory] / 1048576) < 1900 && [getPreference(@"unsupported_warn_counter") intValue] == 0) {
        UIAlertController *RAMAlert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.a7", nil) message:localize(@"login.warn.message.a7", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:RAMAlert animated:YES completion:nil];
        [RAMAlert addAction:ok];
    }
    
    int launchNum = [getPreference(@"unsupported_warn_counter") intValue];
    if(launchNum > 0) {
        setPreference(@"unsupported_warn_counter", @(launchNum - 1));
    } else {
        setPreference(@"unsupported_warn_counter", @(30));
    }

    if(!getenv("POJAV_DETECTEDJB") && [getPreference(@"ram_unjb_warn") boolValue] == YES && [getPreference(@"auto_ram") boolValue] == NO) {
        UIAlertController *ramalert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.ram_unjb", nil) message:localize(@"login.warn.message.ram_unjb", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:ramalert animated:YES completion:nil];
        [ramalert addAction:ok];
        setPreference(@"ram_unjb_warn", @NO);
    }
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    if (self.preferredDisplayMode != displayMode) {
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
        self.preferredDisplayMode = isPortrait ?
            UISplitViewControllerDisplayModeOneOverSecondary :
            UISplitViewControllerDisplayModeOneBesideSecondary;
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
