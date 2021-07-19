#import "customcontrols/ControlButton.h"
#import "CustomControlsViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#include "glfw_keycodes.h"
#include "utils.h"

#define ADD_BUTTON(NAME, KEY, RECT, VISIBLE) \
    ControlButton *button_##KEY = [ControlButton initWithName:NAME keycode:KEY rect:CGRectOffset(RECT, notchOffset, 0) transparency:0.0f]; \
    [button_##KEY addGestureRecognizer:[[UITapGestureRecognizer alloc] \
        initWithTarget:self action:@selector(showControlPopover:)]]; \
    [self.view addSubview:button_##KEY];

int notchOffset;

@interface CustomControlsViewController () <UIPopoverPresentationControllerDelegate>{
}

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
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    notchOffset = insets.left;
    width = width - notchOffset * 2;
    CGFloat buttonScale = ((NSNumber *) getPreference(@"button_scale")).floatValue / 100.0;
    CGFloat rectBtnWidth = 80.0 * buttonScale;
    CGFloat rectBtnHeight = 30.0 * buttonScale;
    CGFloat squareBtnSize = 50.0 * buttonScale;
    
    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:longpressGesture];


    // Temporary fallback controls
    BOOL cc_fallback = YES;

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/%@", getenv("POJAV_PATH_CONTROL"), (NSString *)getPreference(@"default_ctrl")];

    NSError *cc_error;
    NSString *cc_data = [NSString stringWithContentsOfFile:controlFilePath encoding:NSUTF8StringEncoding error:&cc_error];

    if (cc_error != nil) {
        NSLog(@"Error: could not read \"%@\", falling back to default control, error: %@", controlFilePath, cc_error.localizedDescription);
    } else {
        NSData* cc_objc_data = [cc_data dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *cc_dictionary = [NSJSONSerialization JSONObjectWithData:cc_objc_data options:kNilOptions error:&cc_error];
        if (cc_error != nil) {
            showDialog(self, @"Error parsing JSON", cc_error.localizedDescription);
        } else {
            NSArray *cc_controlDataList = (NSArray *) [cc_dictionary valueForKey:@"mControlDataList"];
            for (int i = 0; i < (int) cc_controlDataList.count; i++) {
                ControlButton *button = [ControlButton initWithProperties:(NSMutableDictionary *)cc_controlDataList[i]];
                [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
                    initWithTarget:self action:@selector(showControlPopover:)]];
                [self.view addSubview:button];
            }
            cc_fallback = NO;
        }
    }

    if (cc_fallback == YES) {
        ADD_BUTTON(@"GUI", SPECIALBTN_TOGGLECTRL, CGRectMake(5, height - 5 - squareBtnSize, squareBtnSize, squareBtnSize), NO);
        ADD_BUTTON(@"Keyboard", SPECIALBTN_KEYBOARD, CGRectMake(5 * 3 + rectBtnWidth * 2, 5, rectBtnWidth, rectBtnHeight), YES);

        ADD_BUTTON(@"Pri", SPECIALBTN_MOUSEPRI, CGRectMake(5, height - 5 * 3 - squareBtnSize * 3, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"Sec", SPECIALBTN_MOUSESEC, CGRectMake(5 * 3 + squareBtnSize * 2, height - 5 * 3 - squareBtnSize * 3, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"Debug", GLFW_KEY_F3, CGRectMake(5, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Chat", GLFW_KEY_T, CGRectMake(5 * 2 + rectBtnWidth, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Tab", GLFW_KEY_TAB, CGRectMake(5 * 4 + rectBtnWidth * 3, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Opti-Zoom", GLFW_KEY_C, CGRectMake(5 * 5 + rectBtnWidth * 4, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Offhand", GLFW_KEY_F, CGRectMake(5 * 6 + rectBtnWidth * 5, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"3rd", GLFW_KEY_F5, CGRectMake(5, 5 * 2 + rectBtnHeight, rectBtnWidth, rectBtnHeight), YES);

        ADD_BUTTON(@"▲", GLFW_KEY_W, CGRectMake(5 * 2 + squareBtnSize, height - 5 * 3 - squareBtnSize * 3, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"◀", GLFW_KEY_A, CGRectMake(5, height - 5 * 2 - squareBtnSize * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"▼", GLFW_KEY_S, CGRectMake(5 * 2 + squareBtnSize, height - 5 - squareBtnSize, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"▶", GLFW_KEY_D, CGRectMake(5 * 3 + squareBtnSize * 2, height - 5 * 2 - squareBtnSize * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"◇", GLFW_KEY_LEFT_SHIFT, CGRectMake(5 * 2 + squareBtnSize, height - 5 * 2 - squareBtnSize * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"Inv", GLFW_KEY_E, CGRectMake(5 * 3 + squareBtnSize * 2, height - 5 - squareBtnSize, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"⬛", GLFW_KEY_SPACE, CGRectMake(width - 5 * 2 - squareBtnSize * 2, height - 5 * 2 - squareBtnSize * 2, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"Esc", GLFW_KEY_ESCAPE, CGRectMake(width - 5 - rectBtnWidth, height - 5 - rectBtnHeight, rectBtnWidth, rectBtnHeight), YES);

        // ADD_BUTTON(@"Fullscreen", f11, CGRectMake(width - 5 - rectBtnWidth, 5, rectBtnWidth, rectBtnHeight), YES);
    }
}

- (void)showControlPopover:(UIGestureRecognizer *)sender {
    NSLog(@"Got Gesture = %@", sender);
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

    
}

@end
