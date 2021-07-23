#import "customcontrols/ControlButton.h"
#import "CustomControlsViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#include "glfw_keycodes.h"
#include "utils.h"

// CGRectOffset(RECT, notchOffset, 0)
#define ADD_BUTTON(NAME, KEY, RECT, VISIBLE) \
    ControlButton *button_##KEY = [ControlButton initWithName:NAME keycode:KEY rect:CGRectMake(RECT.origin.x * buttonScale, RECT.origin.y * buttonScale, RECT.size.width * buttonScale, RECT.size.height * buttonScale) transparency:0.0f]; \
    [button_##KEY addGestureRecognizer:[[UITapGestureRecognizer alloc] \
        initWithTarget:self action:@selector(showControlPopover:)]]; \
    [self.view addSubview:button_##KEY];

#define APPLY_SCALE(KEY) \
  KEY = @([(NSNumber *)KEY floatValue] * savedScale / currentScale);

int notchOffset;

@interface CustomControlsViewController () <UIPopoverPresentationControllerDelegate>{
}

@property (nonatomic, strong) NSMutableDictionary* cc_dictionary;

// - (void)method

@end

@implementation CustomControlsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    notchOffset = insets.left;
    width = width - notchOffset * 2;
    CGFloat buttonScale = ((NSNumber *) getPreference(@"button_scale")).floatValue / 100.0;

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:longpressGesture];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/%@", getenv("POJAV_PATH_CONTROL"), (NSString *)getPreference(@"default_ctrl")];

    NSError *cc_error;
    NSString *cc_data = [NSString stringWithContentsOfFile:controlFilePath encoding:NSUTF8StringEncoding error:&cc_error];

    if (cc_error != nil) {
        NSLog(@"Error: could not read %@: %@", controlFilePath, cc_error.localizedDescription);
        showDialog(self, @"Error", [NSString stringWithFormat:@"Could not read %@: %@", controlFilePath, cc_error.localizedDescription]);
    } else {
        NSData* cc_objc_data = [cc_data dataUsingEncoding:NSUTF8StringEncoding];
        self.cc_dictionary = [NSJSONSerialization JSONObjectWithData:cc_objc_data options:NSJSONReadingMutableContainers error:&cc_error];
        if (cc_error != nil) {
            showDialog(self, @"Error parsing JSON", cc_error.localizedDescription);
        } else {
            NSMutableArray *cc_controlDataList = self.cc_dictionary[@"mControlDataList"];
            CGFloat currentScale = ((NSNumber *)self.cc_dictionary[@"scaledAt"]).floatValue;
            CGFloat savedScale = ((NSNumber *)getPreference(@"button_scale")).floatValue;
            int cc_version = ((NSNumber *)self.cc_dictionary[@"version"]).intValue;
            for (int i = 0; i < (int) cc_controlDataList.count; i++) {
                NSMutableDictionary *cc_buttonDict = cc_controlDataList[i];
                if (cc_version < 2) {
                    showDialog(self, @"Notice", @"Custom controls v1 to v2 was not implemented!");
                    return;
                    //convertV1ToV2(cc_buttonDict);
                }
                APPLY_SCALE(cc_buttonDict[@"width"]);
                APPLY_SCALE(cc_buttonDict[@"height"]);
                APPLY_SCALE(cc_buttonDict[@"strokeWidth"]);

                ControlButton *button = [ControlButton initWithProperties:cc_buttonDict];
                [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
                    initWithTarget:self action:@selector(showControlPopover:)]];
                [self.view addSubview:button];
            }
            self.cc_dictionary[@"scaledAt"] = @(savedScale);
        }
    }
} 

- (void)showControlPopover:(UIGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if (![sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
                return;
            }
            break;
        case UIGestureRecognizerStateEnded:
            if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
                return;
            }
            break;
        default:
            return;
    }

    CCMenuViewController *vc = [[CCMenuViewController alloc] init];
    vc.shouldDisplayButtonEditor = [sender.view isKindOfClass:[ControlButton class]];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);
    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    popoverController.sourceView = sender.view;
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
        CGPoint point = [sender locationInView:sender.view];
        popoverController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
    } else {
        popoverController.sourceRect = sender.view.bounds;
    }
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
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

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end

#pragma mark - CCMenuViewController
@interface CCMenuViewController () {
}

@end

@implementation CCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"This is not yet finished. Click here to exit" forState:UIControlStateNormal];
    button.frame = self.view.frame;
    [button addTarget:self action:@selector(tempExit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)tempExit {
    [self dismissViewControllerAnimated:YES completion:nil];
    [((UINavigationController *)self.presentingViewController) setNavigationBarHidden:NO animated:YES];
    [((UINavigationController *)self.presentingViewController) popViewControllerAnimated:YES];
        // [((UINavigationController *)self.presentingViewController).topViewController dismissViewControllerAnimated:YES completion:nil];
    // NSLog(@"ok=%@", ((UINavigationController *)self.presentingViewController).topViewController);
}

@end
