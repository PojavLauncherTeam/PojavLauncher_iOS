#import "LauncherViewController.h"
#import "LoginViewController.h"

#include "utils.h"

@interface LoginViewController () {
}

// - (void)method

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"PojavLauncher"];

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

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

    CGFloat widthSplit = width / 4.0;
    
    UIButton *button_login_mojang = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_mojang setTitle:@"Mojang login" forState:UIControlStateNormal];
    button_login_mojang.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 - 4.0 - 50.0, width - widthSplit * 2.0, 50.0);
    button_login_mojang.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_mojang.layer.cornerRadius = 5;
    [button_login_mojang setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_mojang addTarget:self action:@selector(loginMojang) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_mojang];
    
    UIButton *button_login_microsoft = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_microsoft setTitle:@"Microsoft login" forState:UIControlStateNormal];
    button_login_microsoft.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0, width - widthSplit * 2.0, 50.0);
    button_login_microsoft.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_microsoft.layer.cornerRadius = 5;
    [button_login_microsoft setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_microsoft addTarget:self action:@selector(loginMicrosoft) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_microsoft];
    
    UIButton *button_login_offline = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_offline setTitle:@"Offline login" forState:UIControlStateNormal];
    button_login_offline.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 + 4.0 + 50.0, width - widthSplit * 2.0, 50.0);
    button_login_offline.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_offline.layer.cornerRadius = 5;
    [button_login_offline setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_offline addTarget:self action:@selector(loginOffline) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_offline];
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(13.0)) {
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

- (void)loginMojang {
    [self enterLauncher];
}

- (void)loginMicrosoft {
    [self enterLauncher];
}

- (void)loginOffline {
    [self enterLauncher];
}

- (void)enterLauncher {
    LauncherViewController *vc = [[LauncherViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
