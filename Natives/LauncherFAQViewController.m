#import "LauncherFAQViewController.h"

#include "utils.h"

@interface LauncherFAQViewController () {
}

@end

@implementation LauncherFAQViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    
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

    UILabel *boldJDKView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, width - 40, 30.0)];
    boldJDKView.text = @"Modded versions before 1.16";
    boldJDKView.lineBreakMode = NSLineBreakByWordWrapping;
    boldJDKView.numberOfLines = 0;
    [scrollView addSubview:boldJDKView];
    [boldJDKView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *JDKView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, boldJDKView.frame.origin.y + boldJDKView.frame.size.height, width - 40, 30.0)];
    JDKView.text = @"In order to use these versions, you need to install openjdk-8-jre from Doregon's Repo and change Java home in Preferences to '/usr/lib/jvm/java-8-openjdk.'";
    JDKView.lineBreakMode = NSLineBreakByWordWrapping;
    JDKView.numberOfLines = 0;
    [JDKView sizeToFit];
    [scrollView addSubview:JDKView];

    UILabel *boldSnapView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, JDKView.frame.origin.y + JDKView.frame.size.height, width - 40, 30.0)];
    boldSnapView.text = @"Vanilla versions after 21w08b";
    boldSnapView.lineBreakMode = NSLineBreakByWordWrapping;
    boldSnapView.numberOfLines = 0;
    [scrollView addSubview:boldSnapView];
    [boldSnapView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *snapView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, boldSnapView.frame.origin.y + boldSnapView.frame.size.height, width - 40, 30.0)];
    snapView.text = @"In order to use these versions, you need to follow the instructions on our website (Recent updates > Preliminary support for 1.17)";
    snapView.lineBreakMode = NSLineBreakByWordWrapping;
    snapView.numberOfLines = 0;
    [snapView sizeToFit];
    [scrollView addSubview:snapView];

    UILabel *boldJetsamView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, snapView.frame.origin.y + snapView.frame.size.height, width - 40, 30.0)];
    boldJetsamView.text = @"Jetsam crashes";
    boldJetsamView.lineBreakMode = NSLineBreakByWordWrapping;
    boldJetsamView.numberOfLines = 0;
    [scrollView addSubview:boldJetsamView];
    [boldJetsamView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *jetsamView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, boldJetsamView.frame.origin.y + boldJetsamView.frame.size.height, width - 40, 30.0)];
    jetsamView.text = @"Even though PojavLauncher only allocates 1/4 of the system's total memory, jetsam can still kill the game. A solution is described on the PojavLauncher website (iOS Wiki > Going further > overb0arding)";
    jetsamView.lineBreakMode = NSLineBreakByWordWrapping;
    jetsamView.numberOfLines = 0;
    [jetsamView sizeToFit];
    [scrollView addSubview:jetsamView];
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
