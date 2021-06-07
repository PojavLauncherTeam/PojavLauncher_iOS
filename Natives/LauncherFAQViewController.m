#import "LauncherFAQViewController.h"

#include "utils.h"

@interface LauncherFAQViewController () {
}

@end

@implementation LauncherFAQViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
    [self setTitle:@"Launcher FAQ"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    UILabel *boldSnapView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, width - 4, 15.0)];
    boldSnapView.text = @"Version incompatibility";
    boldSnapView.lineBreakMode = NSLineBreakByWordWrapping;
    boldSnapView.numberOfLines = 0;
    [boldSnapView sizeToFit];
    [scrollView addSubview:boldSnapView];
    [boldSnapView setFont:[UIFont boldSystemFontOfSize:15]];

    UILabel *snapView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, boldSnapView.frame.origin.y + 20.0, width - 4, 30.0)];
    snapView.text = @"Versions of vanilla Minecraft below 1.6 and higher than 21w10a, and modded Minecraft below 1.16 do not yet work with PojavLauncher iOS. There are currently no solutions to fix this issue, but solutions are in the works.";
    snapView.lineBreakMode = NSLineBreakByWordWrapping;
    snapView.numberOfLines = 0;
    [snapView sizeToFit];
    [scrollView addSubview:snapView];

    UILabel *boldJetsamView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, snapView.frame.origin.y + 70, width - 4, 15.0)];
    boldJetsamView.text = @"Jetsam crashes";
    boldJetsamView.lineBreakMode = NSLineBreakByWordWrapping;
    boldJetsamView.numberOfLines = 0;
    [boldJetsamView sizeToFit];
    [scrollView addSubview:boldJetsamView];
    [boldJetsamView setFont:[UIFont boldSystemFontOfSize:15]];

    UILabel *jetsamView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, boldJetsamView.frame.origin.y + 20.0, width - 4, 30.0)];
    jetsamView.text = @"Even though PojavLauncher only allocates 1/4 of the system's total memory, jetsam can still kill the game. A solution is described on the PojavLauncher website.";
    jetsamView.lineBreakMode = NSLineBreakByWordWrapping;
    jetsamView.numberOfLines = 0;
    [jetsamView sizeToFit];
    [scrollView addSubview:jetsamView];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

@end
