#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNavigationController.h"
#import "utils.h"

@interface LauncherSplitViewController () {
}

@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    setViewBackgroundColor(self.view);

    //TODO: maximumPrimaryColumnWidth

    LauncherMenuViewController *masterVc = [[LauncherMenuViewController alloc] init];
    LauncherNavigationController *detailVc = [[LauncherNavigationController alloc] init];
    detailVc.toolbarHidden = NO;

    self.presentsWithGesture = YES;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    self.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:masterVc], detailVc];
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        self.preferredSplitBehavior =   UISplitViewControllerSplitBehaviorTile;
    }
}

- (UITraitCollection *)traitCollection {
    // Allows splitting on compact-sized iPhones
    UITraitCollection *collection = super.traitCollection;
    UITraitCollection *horizontalCollection = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    return [UITraitCollection traitCollectionWithTraitsFromCollections:@[collection, horizontalCollection]];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
