#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNavigationController.h"
#import "utils.h"

@interface LauncherSplitViewController ()<UISplitViewControllerDelegate>{
}
@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    setViewBackgroundColor(self.view);

    self.delegate = self;
    [self changeDisplayModeForSize:self.view.frame.size];

    LauncherMenuViewController *masterVc = [[LauncherMenuViewController alloc] init];
    LauncherNavigationController *detailVc = [[LauncherNavigationController alloc] init];
    detailVc.toolbarHidden = NO;

    self.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:masterVc], detailVc];
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
