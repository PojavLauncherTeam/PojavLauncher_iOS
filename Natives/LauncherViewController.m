#import "LauncherViewController.h"

#include "utils.h"

@interface LauncherViewController () {
}

// - (void)method

@end

@implementation LauncherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    UIScrollView *scrollView = self.view = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    install_progress_bar = [[UIProgressView alloc] initWithFrame:CGRectMake(4.0, 4.0, screenBounds.size.width - 8.0, 40.0)];
    [scrollView addSubview:install_progress_bar];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    [button setTitle:@"Play" forState:UIControlStateNormal];
    button.frame = CGRectMake(10.0, 20.0, 100.0, 50.0);
    [button addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button];
    
    install_progress_text = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 20.0, screenBounds.size.width - 124.0, 50.0)];
    [scrollView addSubview:install_progress_text];
}

- (void)launchMinecraft:(id)sender
{
    callback_LauncherViewController_installMinecraft();
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

@end
