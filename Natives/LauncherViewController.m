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
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, screenBounds.size.width, screenBounds.size.height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    [button setTitle:@"Launch" forState:UIControlStateNormal];
    button.frame = CGRectMake(10.0, 10.0, 100.0, 50.0);
    [button addTarget:self action:@selector(showSinaWeiboUserClickHandler:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button];

    self.view = scrollView;
    
    // [self.view addSubview:scrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

@end
