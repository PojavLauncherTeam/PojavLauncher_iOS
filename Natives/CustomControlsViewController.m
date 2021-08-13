#import "CustomControlsViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/CustomControlsUtils.h"

#include "glfw_keycodes.h"
#include "utils.h"

// CGRectOffset(RECT, notchOffset, 0)
#define ADD_BUTTON(NAME, KEY, RECT, VISIBLE) \
    ControlButton *button_##KEY = [ControlButton initWithName:NAME keycode:KEY rect:CGRectMake(RECT.origin.x * buttonScale, RECT.origin.y * buttonScale, RECT.size.width * buttonScale, RECT.size.height * buttonScale) transparency:0.0f]; \
    [button_##KEY addGestureRecognizer:[[UITapGestureRecognizer alloc] \
        initWithTarget:self action:@selector(showControlPopover:)]]; \
    [self.offsetView addSubview:button_##KEY];

#define APPLY_SCALE(KEY) \
  KEY = @([(NSNumber *)KEY floatValue] * savedScale / currentScale);

int width;

@interface CustomControlsViewController () <UIPopoverPresentationControllerDelegate>{
}

@property(nonatomic, strong) NSMutableDictionary* cc_dictionary;
@property(nonatomic) UIView* offsetView;

// - (void)method

@end

@implementation CustomControlsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;

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

    self.offsetView = [[UIView alloc] initWithFrame:CGRectMake(
        insets.left, 0,
        self.view.frame.size.width - insets.left - insets.right,
        self.view.frame.size.height
    )];
    [self.view addSubview:self.offsetView];

    int height = (int) roundf(screenBounds.size.height);
    width = width - insets.left - insets.right;
    CGFloat buttonScale = ((NSNumber *) getPreference(@"button_scale")).floatValue / 100.0;

    UIPanGestureRecognizer *panRecognizer;
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(wasDragged:)];

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.offsetView addGestureRecognizer:longpressGesture];

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
            convertV1ToV2(self.cc_dictionary);
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
                [self.offsetView addSubview:button];
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
        vc.targetButton = (ControlButton *)sender.view;
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

- (void)wasDragged:(UIPanGestureRecognizer *)recognizer {
    UIButton *button = (UIButton *)recognizer.view;
    CGPoint translation = [recognizer translationInView:button];

    button.center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:button];
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

@property(nonatomic) UIScrollView* scrollView;

@end

@implementation CCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.frame = CGRectMake(0, 0, self.preferredContentSize.width, self.preferredContentSize.height);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20.0, 0.0, self.preferredContentSize.width - 40.0, self.preferredContentSize.height - 40.0)];
    [self.view addSubview:self.scrollView];

    if (self.shouldDisplayButtonEditor) {
        [self displayButtonEditor];
    } else {
        [self displayControlMenu];
    }
}

- (void)displayButtonEditor {
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;

    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    labelName.text = @"Name";
    labelName.numberOfLines = 0;
    [labelName sizeToFit];
    [self.scrollView addSubview:labelName];
    UITextField *editName = [[UITextField alloc] initWithFrame:CGRectMake(labelName.frame.size.width + 4.0, 0.0, width - labelName.frame.size.width - 4.0, labelName.frame.size.height)];
    [editName addTarget:editName action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    editName.placeholder = @"Name";
    editName.text = self.targetButton.properties[@"name"];
    //editName.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    //editName.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.scrollView addSubview:editName];

    UILabel *labelSize = [[UILabel alloc] initWithFrame:CGRectMake(0.0, labelName.frame.size.height + 4.0, 0.0, 0.0)];
    labelSize.text = @"Size";
    labelSize.numberOfLines = 0;
    [labelSize sizeToFit];
    [self.scrollView addSubview:labelSize];
    // width / 2.0 + (labelSize.frame.size.width + 4.0) / 2.0
    UILabel *labelSizeX = [[UILabel alloc] initWithFrame:CGRectMake(labelSize.frame.size.width + 4.0 + (width - labelSize.frame.size.width) / 2, labelName.frame.size.height + 4.0, 0.0, 0.0)];
    labelSizeX.text = @"x";
    labelSizeX.numberOfLines = 0;
    [labelSizeX sizeToFit];
    [self.scrollView addSubview:labelSizeX];
    UITextField *editSizeWidth = [[UITextField alloc] initWithFrame:CGRectMake(labelSize.frame.size.width + 4.0, labelSize.frame.origin.y, width - labelSize.frame.size.width - 4.0, labelSize.frame.size.height)];
    [editSizeWidth addTarget:editSizeWidth action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    editSizeWidth.placeholder = @"width";
    editSizeWidth.text = ((NSNumber *)self.targetButton.properties[@"width"]).stringValue;
    editSizeWidth.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    editSizeWidth.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.scrollView addSubview:editSizeWidth];
}

- (void)displayControlMenu {
    UIButton *buttonExit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonExit.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [buttonExit setTitle:@"Exit" forState:UIControlStateNormal];
    buttonExit.frame = CGRectMake(0.0, 0.0, self.scrollView.frame.size.width, 50.0);
    [buttonExit addTarget:self action:@selector(actionExit) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:buttonExit];
}

- (void)actionExit {
    [self dismissViewControllerAnimated:YES completion:nil];
    [((UINavigationController *)self.presentingViewController) setNavigationBarHidden:NO animated:YES];
    [((UINavigationController *)self.presentingViewController) popViewControllerAnimated:YES];
}

@end
