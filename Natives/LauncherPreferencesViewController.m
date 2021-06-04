#import "LauncherPreferencesViewController.h"

#include "utils.h"

@interface LauncherPreferencesViewController () {
}

// - (void)method

@end

@implementation LauncherPreferencesViewController

UITextField* versionTextField;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
    [self setTitle:@"Launcher preferences"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

// not yet finished, empty view controller for now
/*
    UILabel *btnsizeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, 0.0, 30.0)];
    btnsizeTextView.text = @"Button size: ";
    btnsizeTextView.numberOfLines = 0;
    [btnsizeTextView sizeToFit];
    [scrollView addSubview:btnsizeTextView];
    
    UISlider *buttonSizeSlider = [[UISlider alloc] initWithFrame:CGRectMake(8.0 + btnsizeTextView.frame.x, 4.0, 200.0, 30.0)];
    // [buttonSizeSlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [buttonSizeSlider setBackgroundColor:[UIColor clearColor]];
    buttonSizeSlider.minimumValue = 50.0;
    buttonSizeSlider.maximumValue = 200.0;
    buttonSizeSlider.continuous = YES;
    buttonSizeSlider.value = 50.0;
    [scrollView addSubview:buttonSizeSlider];
*/

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);
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
