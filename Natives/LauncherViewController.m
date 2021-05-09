#import "LauncherViewController.h"

#include "utils.h"

@interface LauncherViewController () {
}

// - (void)method

@end

@implementation LauncherViewController

UITextField* versionTextField;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    [self setTitle:@"PojavLauncher"];

    FILE *configver_file = fopen("/var/mobile/Documents/minecraft/config_ver.txt", "rw");

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = self.view = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    char configver[1024];
    if (!fgets(configver, 1024, configver_file)) {
        NSLog(@"Error: could not read config_ver.txt");
    }

    UILabel *versionTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, 0.0, 30.0)];
    versionTextView.text = @"Minecraft version: ";
    versionTextView.numberOfLines = 0;
    [versionTextView sizeToFit];
    [scrollView addSubview:versionTextView];

    versionTextField = [[UITextField alloc] initWithFrame:CGRectMake(versionTextView.bounds.size.width + 4.0, 4.0, width - versionTextView.bounds.size.width - 8.0, versionTextView.bounds.size.height)];
    [versionTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    versionTextField.placeholder = @"Minecraft version";
    versionTextField.text = [NSString stringWithUTF8String:configver];
    fclose(configver_file);
    [scrollView addSubview:versionTextField];
    
    install_progress_bar = [[UIProgressView alloc] initWithFrame:CGRectMake(4.0, height - 58.0, width - 8.0, 6.0)];
    [scrollView addSubview:install_progress_bar];

    install_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    install_button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    [install_button setTitle:@"Play" forState:UIControlStateNormal];
    install_button.frame = CGRectMake(10.0, height - 54.0, 100.0, 50.0);
    [install_button addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:install_button];
    
    install_progress_text = [[UILabel alloc] initWithFrame:CGRectMake(120.0, height - 54.0, width - 124.0, 50.0)];
    [scrollView addSubview:install_progress_text];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(13.0)) {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)launchMinecraft:(id)sender
{
    [(UIButton*) sender setEnabled:NO];

    [versionTextField.text writeToFile:@"/var/mobile/Documents/minecraft/config_ver.txt" atomically:NO encoding:NSUTF8StringEncoding error:nil];
    callback_LauncherViewController_installMinecraft();
}

@end
