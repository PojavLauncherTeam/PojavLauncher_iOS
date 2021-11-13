#import "CustomControlsViewController.h"
#import "DBNumberedSlider.h"
#import "FileListViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/ControlDrawer.h"
#import "customcontrols/CustomControlsUtils.h"

#include "glfw_keycodes.h"
#include "utils.h"

BOOL shouldDismissPopover = YES;
int width;
NSMutableArray *keyCodeMap, *keyValueMap;

CGFloat clamp(CGFloat x, CGFloat lower, CGFloat upper) {
    return fmin(upper, fmax(x, lower));
}

@interface ControlLayout ()
@end
@implementation ControlLayout
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(actionMenuExit:) ||
        action == @selector(actionMenuSave:) ||
        action == @selector(actionMenuLoad:) ||
        action == @selector(actionMenuSetDef:) ||
        action == @selector(actionMenuAddButton:) ||
        action == @selector(actionMenuAddDrawer:) ||
        action == @selector(actionMenuBtnCopy:) ||
        action == @selector(actionMenuBtnDelete:) ||
        action == @selector(actionMenuBtnEdit:)) {
            return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}
@end

@interface CustomControlsViewController () <UIPopoverPresentationControllerDelegate>{
}

@property(nonatomic, strong) NSMutableDictionary* cc_dictionary;
@property(nonatomic) UIView* offsetView;
@property(nonatomic) NSString* currentFileName;
@property(nonatomic) CGRect selectedPoint;
@property(nonatomic) UIGestureRecognizer* currentGesture;

// - (void)method

@end

@implementation CustomControlsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    isControlModifiable = YES;

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

    self.offsetView = [[ControlLayout alloc] initWithFrame:CGRectMake(
        insets.left, 0,
        self.view.frame.size.width - insets.left - insets.right,
        self.view.frame.size.height
    )];
    [self.view addSubview:self.offsetView];

    int height = (int) roundf(screenBounds.size.height);
    width = width - insets.left - insets.right;
    CGFloat buttonScale = [getPreference(@"button_scale") floatValue] / 100.0;

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.offsetView addGestureRecognizer:longpressGesture];
    self.currentFileName = [getPreference(@"default_ctrl") stringByDeletingPathExtension];
    [self loadControlFile:[NSString stringWithFormat:@"%s/%@", getenv("POJAV_PATH_CONTROL"), getPreference(@"default_ctrl")]];
}

- (void)loadControlFile:(NSString *)controlFilePath {
    for (UIView *view in self.offsetView.subviews) {
        if ([view isKindOfClass:[ControlButton class]]) {
            [view removeFromSuperview];
        }
    }

    NSError *cc_error;
    NSString *cc_data = [NSString stringWithContentsOfFile:controlFilePath encoding:NSUTF8StringEncoding error:&cc_error];

    if (cc_error) {
        NSLog(@"Error: could not read %@: %@", controlFilePath, cc_error.localizedDescription);
        showDialog(self, @"Error", [NSString stringWithFormat:@"Could not read %@: %@", controlFilePath, cc_error.localizedDescription]);
    } else {
        NSData* cc_objc_data = [cc_data dataUsingEncoding:NSUTF8StringEncoding];
        self.cc_dictionary = [NSJSONSerialization JSONObjectWithData:cc_objc_data options:NSJSONReadingMutableContainers error:&cc_error];
        if (cc_error) {
            showDialog(self, @"Error parsing JSON", cc_error.localizedDescription);
        } else {
            loadControlObject(self.offsetView, self.cc_dictionary, ^void(ControlButton* button) {
                [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
                    initWithTarget:self action:@selector(showControlPopover:)]];
                [button addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                    initWithTarget:self action:@selector(onTouch:)]];
            });
        }
    }

    [self initKeyCodeMap];
} 

- (void)showControlPopover:(UIGestureRecognizer *)sender {
    self.currentGesture = sender;

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

    UIMenuController *menuController = [UIMenuController sharedMenuController];

    if (![sender.view isKindOfClass:[ControlButton class]]) {
        UIMenuItem *actionExit = [[UIMenuItem alloc] initWithTitle:@"Exit" action:@selector(actionMenuExit)];
        UIMenuItem *actionSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionMenuSave)];
        UIMenuItem *actionLoad = [[UIMenuItem alloc] initWithTitle:@"Load" action:@selector(actionMenuLoad)];
        UIMenuItem *actionSetDef = [[UIMenuItem alloc] initWithTitle:@"Select as default" action:@selector(actionMenuSetDef)];
        UIMenuItem *actionAddButton = [[UIMenuItem alloc] initWithTitle:@"Add button" action:@selector(actionMenuAddButton)];
        UIMenuItem *actionAddDrawer = [[UIMenuItem alloc] initWithTitle:@"Add drawer" action:@selector(actionMenuAddDrawer)];
        [menuController setMenuItems:@[actionExit, actionSave, actionLoad, actionSetDef, actionAddButton, /* actionAddDrawer */]];

        CGPoint point = [sender locationInView:sender.view];
        self.selectedPoint = CGRectMake(point.x, point.y, 1.0, 1.0);
    } else {
        UIMenuItem *actionEdit = [[UIMenuItem alloc] initWithTitle:@"Edit" action:@selector(actionMenuBtnEdit)];
        UIMenuItem *actionCopy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionMenuBtnCopy)];
        UIMenuItem *actionDelete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(actionMenuBtnDelete)];
        [menuController setMenuItems:@[actionEdit, /* actionCopy, */ actionDelete]];
        self.selectedPoint = sender.view.bounds;
    }

    if (sender.view != self.offsetView) {
        [self.offsetView becomeFirstResponder];
    }
    [sender.view becomeFirstResponder];

    if(@available(iOS 13.0, *)) {
        [menuController showMenuFromView:sender.view rect:self.selectedPoint];
    } else {
        [menuController setTargetRect:self.selectedPoint inView:sender.view];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)actionMenuExit {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionMenuSave {
      UIAlertController *controller = [UIAlertController alertControllerWithTitle: @"Save"
        message:[NSString stringWithFormat:@"File will be saved to %s directory.", getenv("POJAV_PATH_CONTROL")]
        preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Name";
        textField.text = self.currentFileName;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = controller.textFields;
        UITextField *field = textFields[0];
        if ([field.text isEqualToString:@"default"]) {
            controller.message = @"Control name should not be \"default\" as it will be overriden.";
            [self presentViewController:controller animated:YES completion:nil];
        } else {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.cc_dictionary options:NSJSONWritingPrettyPrinted error:&error];
            if (jsonData == nil) {
                showDialog(self, @"Error while converting to JSON", error.localizedDescription);
                return;
            }
            NSString *jsonStr = [NSString stringWithUTF8String:jsonData.bytes];
            BOOL success = [jsonStr writeToFile:[NSString stringWithFormat:@"%s/%@.json", getenv("POJAV_PATH_CONTROL"), field.text] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (!success) {
                showDialog(self, @"Error while saving file", error.localizedDescription);
                return;
            }

            self.currentFileName = field.text;
        }
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)actionOpenFilePicker:(void (^)(NSString *name))handler {
    FileListViewController *vc = [[FileListViewController alloc] init];
    vc.listPath = [NSString stringWithFormat:@"%s/controlmap", getenv("POJAV_HOME")];
    vc.whenItemSelected = handler;
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);
    
    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    popoverController.sourceView = self.view;
    popoverController.sourceRect = self.selectedPoint;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)actionMenuLoad {
    [self actionOpenFilePicker:^void(NSString* name) {
        self.currentFileName = name;
        [self loadControlFile:[NSString stringWithFormat:@"%s/%@.json", getenv("POJAV_PATH_CONTROL"), name]];
    }];
}

- (void)actionMenuSetDef {
    [self actionOpenFilePicker:^void(NSString* name) {
        self.currentFileName = name;
        [self loadControlFile:[NSString stringWithFormat:@"%s/%@.json", getenv("POJAV_PATH_CONTROL"), name]];
        setPreference(@"default_ctrl", [NSString stringWithFormat:@"%@.json", name]);
    }];
}

- (void)actionMenuAddButton {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = @"New";
    dict[@"keycodes"] = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++) {
        dict[@"keycodes"][i] = @(0);
    }
    dict[@"dynamicX"] = @"0";
    dict[@"dynamicY"] = @"0";
    dict[@"width"] = @(50.0);
    dict[@"height"] = @(50.0);
    dict[@"opacity"] = @(1);
    dict[@"cornerRadius"] = @(0);
    dict[@"bgColor"] = @(0x4d000000);
    ControlButton *button = [ControlButton buttonWithProperties:dict];
    [button snapAndAlignX:self.selectedPoint.origin.x-25.0 Y:self.selectedPoint.origin.y-25.0];
    [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(showControlPopover:)]];
    [button addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onTouch:)]];
    [self.offsetView addSubview:button];
    [self.cc_dictionary[@"mControlDataList"] addObject:button.properties];
}

- (void)actionMenuAddDrawer {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = @"New";
    dict[@"dynamicX"] = @"0";
    dict[@"dynamicY"] = @"0";
    dict[@"width"] = @(50.0);
    dict[@"height"] = @(50.0);
    dict[@"opacity"] = @(1);
    dict[@"cornerRadius"] = @(0);
    dict[@"bgColor"] = @(0x4d000000);
}

- (void)actionMenuBtnCopy {
    // copy
}

- (void)actionMenuBtnDelete {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:((ControlButton *)self.currentGesture.view).currentTitle message:@"Are you sure to delete this button?"preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        ControlButton *button = (ControlButton *)self.currentGesture.view;
        if ([button isKindOfClass:[ControlSubButton class]]) {
            [((ControlSubButton *)button).parentDrawer.buttons removeObject:button];
            [((ControlSubButton *)button).parentDrawer.drawerData[@"buttonProperties"] removeObject:button.properties];
            [((ControlSubButton *)button).parentDrawer syncButtons];
        } else if ([button isKindOfClass:[ControlDrawer class]]) {
            for (ControlSubButton *subButton in ((ControlDrawer *)button).buttons) {
                [subButton removeFromSuperview];
            }
            [self.cc_dictionary[@"mDrawerDataList"] removeObject:((ControlDrawer *)button).drawerData];
        } else {
            [self.cc_dictionary[@"mControlDataList"] removeObject:button.properties];
        }
        [button removeFromSuperview];
        
    }];
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)actionMenuBtnEdit {
    shouldDismissPopover = NO;
    CCMenuViewController *vc = [[CCMenuViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);
    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    popoverController.sourceView = self.currentGesture.view;
    if ([self.currentGesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
        CGPoint point = [self.currentGesture locationInView:self.currentGesture.view];
        popoverController.sourceRect = self.selectedPoint;
    } else {
        vc.targetButton = (ControlButton *)self.currentGesture.view;
        popoverController.sourceRect = self.currentGesture.view.bounds;
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

- (void)onTouch:(UIPanGestureRecognizer *)sender {
    ControlButton *button = (ControlButton *)sender.view;
    if (![button.properties[@"isDynamicBtn"] boolValue]) {
        if ([button isKindOfClass:[ControlSubButton class]] &&
          ![((ControlSubButton *)button).parentDrawer.drawerData[@"orientation"] isEqualToString:@"FREE"]) return;

        if (sender.state == UIGestureRecognizerStateBegan) {
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            if(@available(iOS 13.0, *)) {
                [menuController hideMenu];
            } else {
                [menuController setMenuVisible:NO animated:YES];
            }
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [sender translationInView:button];
            //button.center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
            [button snapAndAlignX:clamp(button.frame.origin.x+translation.x, 0, self.offsetView.frame.size.width - button.frame.size.width) Y:clamp(button.frame.origin.y+translation.y, 0, self.offsetView.frame.size.height - button.frame.size.height)];
            [sender setTranslation:CGPointZero inView:button];
        }
    }
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

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
     return shouldDismissPopover;
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    return shouldDismissPopover;
}

#pragma mark - Keycode table init
- (void)initKeyCodeMap {
#define addkey(key) \
  [keyCodeMap addObject:@(#key)]; \
  [keyValueMap addObject:@(GLFW_KEY_##key)];
#define addspec(key) \
  [keyCodeMap addObject:@(#key)]; \
  [keyValueMap addObject:@(key)];
    keyCodeMap = [[NSMutableArray alloc] init];
    keyValueMap = [[NSMutableArray alloc] init];
    addspec(SPECIALBTN_SCROLLDOWN)
    addspec(SPECIALBTN_SCROLLUP)
    addspec(SPECIALBTN_VIRTUALMOUSE)
    addspec(SPECIALBTN_MOUSEMID)
    addspec(SPECIALBTN_MOUSESEC)
    addspec(SPECIALBTN_MOUSEPRI)
    addspec(SPECIALBTN_TOGGLECTRL)
    addspec(SPECIALBTN_KEYBOARD)

    addkey(UNKNOWN)
    addkey(HOME)
    addkey(ESCAPE)

    // 0-9 keys
    addkey(0) addkey(1) addkey(2) addkey(3) addkey(4) addkey(5) addkey(6) addkey(7) addkey(8) addkey(9)
    //addkey(POUND)

    // Arrow keys
    addkey(DPAD_UP) addkey(DPAD_DOWN) addkey(DPAD_LEFT) addkey(DPAD_RIGHT)

    // A-Z keys
    addkey(A) addkey(B) addkey(C) addkey(D) addkey(E) addkey(F) addkey(G) addkey(H) addkey(I) addkey(J) addkey(K) addkey(L) addkey(M) addkey(N) addkey(O) addkey(P) addkey(Q) addkey(R) addkey(S) addkey(T) addkey(U) addkey(V) addkey(W) addkey(X) addkey(Y) addkey(Z)

    addkey(COMMA)
    addkey(PERIOD)

    // Alt keys
    addkey(LEFT_ALT)
    addkey(RIGHT_ALT)

    // Shift keys
    addkey(LEFT_SHIFT)
    addkey(RIGHT_SHIFT)

    addkey(TAB)
    addkey(SPACE)
    addkey(ENTER)
    addkey(BACKSPACE)
    addkey(DELETE)
    addkey(GRAVE_ACCENT)
    addkey(MINUS)
    addkey(EQUAL)
    addkey(LEFT_BRACKET) addkey(RIGHT_BRACKET)
    addkey(BACKSLASH)
    addkey(SEMICOLON)
    addkey(SLASH)
    //addkey(AT) //@

    // Page keys
    addkey(PAGE_UP) addkey(PAGE_DOWN)

    // Control keys
    addkey(LEFT_CONTROL)
    addkey(RIGHT_CONTROL)

    addkey(CAPS_LOCK)
    addkey(PAUSE)
    addkey(INSERT)

    // Fn keys
    addkey(F1) addkey(F2) addkey(F3) addkey(F4) addkey(F5) addkey(F6) addkey(F7) addkey(F8) addkey(F9) addkey(F10) addkey(F11) addkey(F12)

    // Num keys
    addkey(NUM_LOCK)
    addkey(NUMPAD_0) addkey(NUMPAD_1) addkey(NUMPAD_2) addkey(NUMPAD_3) addkey(NUMPAD_4) addkey(NUMPAD_5) addkey(NUMPAD_6) addkey(NUMPAD_7) addkey(NUMPAD_8) addkey(NUMPAD_9)
    addkey(NUMPAD_DECIMAL) addkey(NUMPAD_DIVIDE) addkey(NUMPAD_MULTIPLY) addkey(NUMPAD_SUBTRACT) addkey(NUMPAD_ADD) addkey(NUMPAD_ENTER) addkey(NUMPAD_EQUAL)

    //addkey(APOSTROPHE)
    //addkey(WORLD_1) addkey(WORLD_2)
    //addkey(END)
    //addkey(SCROLL_LOCK) 
    //addkey(PRINT_SCREEN)
    //addkey(LEFT_SUPER) addkey(RIGHT_ENTER)
    //addkey(MENU)
#undef addkey
}

@end

#define TAG_SLIDER_STROKEWIDTH 10
#define TAG_SLIDER_CORNERRADIUS 11
#define TAG_SLIDER_OPACITY 12
#define TAG_SWITCH_DYNAMICPOS 13

#pragma mark - CCMenuViewController

CGFloat currentY;

@interface CCMenuViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
}

@property(nonatomic) NSArray* arrOrientation;

@property(nonatomic) UIScrollView* scrollView;
@property(nonatomic) UITextField *editName, *editSizeWidth, *editSizeHeight, *editDynamicX, *editDynamicY;
@property(nonatomic) UITextView* editMapping;
@property(nonatomic) UIPickerView* pickerMapping;
@property(nonatomic) UISegmentedControl* ctrlOrientation;
@property(nonatomic) UISwitch *switchToggleable, *switchMousePass, *switchSwipeable, *switchDynamicPos;
@property(nonatomic) UIColorWell API_AVAILABLE(ios(14.0)) *colorWellBackground, *colorWellStroke;
@property(nonatomic) DBNumberedSlider *sliderStrokeWidth, *sliderCornerRadius, *sliderOpacity;

@end

@implementation CCMenuViewController

- (UILabel*)addLabel:(NSString *)name {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, currentY, 0.0, 0.0)];
    label.text = name;
    label.numberOfLines = 0;
    [label sizeToFit];
    [self.scrollView addSubview:label];
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    currentY = 6.0;

    self.view.frame = CGRectMake(0, 0, self.preferredContentSize.width, self.preferredContentSize.height);

    UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIToolbar *popoverToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.preferredContentSize.width, 44.0)];
    UIBarButtonItem *popoverCancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionEditCancel)];
    UIBarButtonItem *popoverDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionEditFinish)];
    popoverToolbar.items = @[popoverCancelButton, btnFlexibleSpace, popoverDoneButton];
    [self.view addSubview:popoverToolbar];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5.0, popoverToolbar.frame.size.height, self.preferredContentSize.width - 10.0, self.preferredContentSize.height - popoverToolbar.frame.size.height)];
    [self.view addSubview:self.scrollView];

    UIToolbar *editPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTextField)];
    editPickToolbar.items = @[btnFlexibleSpace, editDoneButton];

    CGFloat width = self.view.frame.size.width - 10.0;
    CGFloat height = self.view.frame.size.height - 10.0;


    // Property: Name
    UILabel *labelName = [self addLabel:@"Name"];
    self.editName = [[UITextField alloc] initWithFrame:CGRectMake(labelName.frame.size.width + 5.0, currentY, width - labelName.frame.size.width - 5.0, labelName.frame.size.height)];
    [self.editName addTarget:self.editName action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.editName.placeholder = @"Name";
    self.editName.text = self.targetButton.properties[@"name"];
    [self.scrollView addSubview:self.editName];

    // Property: Size
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelSize = [self addLabel:@"Size"];
    // width / 2.0 + (labelSize.frame.size.width + 4.0) / 2.0
    CGFloat editSizeWidthValue = (width - labelSize.frame.size.width) / 2 - labelSize.frame.size.height / 2;
    UILabel *labelSizeX = [[UILabel alloc] initWithFrame:CGRectMake(labelSize.frame.size.width + editSizeWidthValue, labelSize.frame.origin.y, labelSize.frame.size.height, labelSize.frame.size.height)];
    labelSizeX.text = @"x";
    [self.scrollView addSubview:labelSizeX];
    self.editSizeWidth = [[UITextField alloc] initWithFrame:CGRectMake(labelSize.frame.size.width, labelSize.frame.origin.y, editSizeWidthValue, labelSize.frame.size.height)];
    self.editSizeWidth.keyboardType = UIKeyboardTypeDecimalPad;
    self.editSizeWidth.placeholder = @"width";
    self.editSizeWidth.text = [self.targetButton.properties[@"width"] stringValue];
    self.editSizeWidth.textAlignment = NSTextAlignmentCenter;
    self.editSizeWidth.inputAccessoryView = editPickToolbar;
    [self.scrollView addSubview:self.editSizeWidth];
    self.editSizeHeight = [[UITextField alloc] initWithFrame:CGRectMake(labelSizeX.frame.origin.x + labelSizeX.frame.size.width, labelSize.frame.origin.y, editSizeWidthValue, labelSize.frame.size.height)];
    self.editSizeHeight.keyboardType = UIKeyboardTypeDecimalPad;
    self.editSizeHeight.placeholder = @"height";
    self.editSizeHeight.text = [self.targetButton.properties[@"height"] stringValue];
    self.editSizeHeight.textAlignment = NSTextAlignmentCenter;
    self.editSizeHeight.inputAccessoryView = editPickToolbar;
    [self.scrollView addSubview:self.editSizeHeight];


    currentY += labelName.frame.size.height + 12.0;
    if (![self.targetButton isKindOfClass:[ControlDrawer class]]) {
        // Property: Mapping
        UILabel *labelMapping = [self addLabel:@"Mapping"];

        self.editMapping = [[UITextView alloc] initWithFrame:CGRectMake(0,0,1,1)];
        self.editMapping.text = @"\n\n\n";
        [self.editMapping sizeToFit];
        self.editMapping.scrollEnabled = NO;
        self.editMapping.frame = CGRectMake(labelMapping.frame.size.width + 5.0, labelMapping.frame.origin.y, width - labelMapping.frame.size.width - 5.0, self.editMapping.frame.size.height);

        self.pickerMapping = [[UIPickerView alloc] init];
        self.pickerMapping.delegate = self;
        self.pickerMapping.dataSource = self;
        [self.pickerMapping reloadAllComponents];
        for (int i = 0; i < 4; i++) {
          [self.pickerMapping selectRow:[keyValueMap indexOfObject:self.targetButton.properties[@"keycodes"][i]] inComponent:i animated:NO];
        }
        [self pickerView:self.pickerMapping didSelectRow:0 inComponent:0];

        self.editMapping.inputAccessoryView = editPickToolbar;
        self.editMapping.inputView = self.pickerMapping;
        [self.scrollView addSubview:self.editMapping];
        currentY += self.editMapping.frame.size.height + 12.0;
    } else {
        // Property: Orientation
        self.arrOrientation = [NSArray arrayWithObjects:@"DOWN", @"LEFT", @"UP", @"RIGHT", @"FREE", nil];
        UILabel *labelOrientation = [self addLabel:@"Orientation"];
        self.ctrlOrientation = [[UISegmentedControl alloc] initWithItems:self.arrOrientation];
        self.ctrlOrientation.frame = CGRectMake(labelOrientation.frame.size.width + 5.0, currentY - 5.0, width - labelOrientation.frame.size.width - 5.0, 30.0);
        self.ctrlOrientation.selectedSegmentIndex = [self.arrOrientation indexOfObject:
            ((ControlDrawer *)self.targetButton).drawerData[@"orientation"]];
        [self.scrollView addSubview:self.ctrlOrientation];
        currentY += labelName.frame.size.height + 12.0;
    }


    // Property: Toggleable
    UILabel *labelToggleable = [self addLabel:@"Toggleable"];
    self.switchToggleable = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchToggleable setOn:[self.targetButton.properties[@"isToggle"] boolValue] animated:NO];
    [self.scrollView addSubview:self.switchToggleable];


    // Property: Mouse pass
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelMousePass = [self addLabel:@"Mouse pass"];
    self.switchMousePass = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchMousePass setOn:[self.targetButton.properties[@"passThruEnabled"] boolValue]];
    [self.scrollView addSubview:self.switchMousePass];


    // Property: Swipeable
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelSwipeable = [self addLabel:@"Swipeable"];
    self.switchSwipeable = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchSwipeable setOn:[self.targetButton.properties[@"isSwipeable"] boolValue]];
    [self.scrollView addSubview:self.switchSwipeable];


    // Property: Background color
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelBGColor = [self addLabel:@"Background color"];
    if(@available(iOS 14.0, *)) {
        self.colorWellBackground = [[UIColorWell alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        self.colorWellBackground.selectedColor = self.targetButton.backgroundColor;
        [self.scrollView addSubview:self.colorWellBackground];
    } else {
        // TODO: color picker for iOS < 14.0
    }


    // Property: Stroke width
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelStrokeWidth = [self addLabel:@"Stroke width (%)"];
    self.sliderStrokeWidth = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelStrokeWidth.frame.size.width + 5.0, currentY - 5.0, width - labelStrokeWidth.frame.size.width - 5.0, 30.0)];
    self.sliderStrokeWidth.continuous = YES;
    self.sliderStrokeWidth.maximumValue = 100;
    self.sliderStrokeWidth.tag = TAG_SLIDER_STROKEWIDTH;
    self.sliderStrokeWidth.value = [self.targetButton.properties[@"strokeWidth"] intValue];
    [self.sliderStrokeWidth addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderStrokeWidth];


    // Property: Stroke color
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelStrokeColor = [self addLabel:@"Stroke color"];
    if(@available(iOS 14.0, *)) {
        self.colorWellStroke = [[UIColorWell alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        self.colorWellStroke.supportsAlpha = NO;
        self.colorWellStroke.selectedColor = [[UIColor alloc] initWithCGColor:self.targetButton.layer.borderColor];
        [self.scrollView addSubview:self.colorWellStroke];
        [self sliderValueChanged:self.sliderStrokeWidth];
    } else {
        // TODO: color picker for iOS < 14.0
    }


    // Property: Corner radius
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelCornerRadius = [self addLabel:@"Corner radius (%)"];
    self.sliderCornerRadius = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelCornerRadius.frame.size.width + 5.0, currentY - 5.0, width - labelCornerRadius.frame.size.width - 5.0, 30.0)];
    self.sliderCornerRadius.continuous = NO;
    self.sliderCornerRadius.maximumValue = 100;
    self.sliderCornerRadius.tag = TAG_SLIDER_CORNERRADIUS;
    self.sliderCornerRadius.value = [self.targetButton.properties[@"cornerRadius"] intValue];
    [self.sliderCornerRadius addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderCornerRadius];


    // Property: Button Opacity
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelOpacity = [self addLabel:@"Button opacity"];
    self.sliderOpacity = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelOpacity.frame.size.width + 5.0, currentY - 5.0, width - labelOpacity.frame.size.width - 5.0, 30.0)];
    self.sliderOpacity.continuous = NO;
    self.sliderOpacity.minimumValue = 1;
    self.sliderOpacity.maximumValue = 100;
    self.sliderOpacity.tag = TAG_SLIDER_OPACITY;
    self.sliderOpacity.value = [self.targetButton.properties[@"opacity"] floatValue] * 100.0;
    [self.sliderOpacity addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderOpacity];


    if (![self.targetButton isKindOfClass:[ControlSubButton class]] ||
      [((ControlSubButton *)self.targetButton).parentDrawer.drawerData[@"orientation"] isEqualToString:@"FREE"]) {
        // Property: Dynamic position
        currentY += labelName.frame.size.height + 12.0; 
        UILabel *labelDynamicPos = [self addLabel:@"Dynamic position"];
        self.switchDynamicPos = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
        self.switchDynamicPos.tag = TAG_SWITCH_DYNAMICPOS;
        [self.switchDynamicPos setOn:[self.targetButton.properties[@"isDynamicBtn"] boolValue] animated:NO];
        [self.switchDynamicPos addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:self.switchDynamicPos];


        // Property: Dynamic X-axis
        currentY += labelName.frame.size.height + 12.0;
        UILabel *labelDynamicX = [self addLabel:@"Dynamic X-axis"];
        self.editDynamicX = [[UITextField alloc] initWithFrame:CGRectMake(labelDynamicX.frame.size.width + 5.0, currentY, width - labelDynamicX.frame.size.width - 5.0, labelDynamicX.frame.size.height)];
        [self.editDynamicX addTarget:self.editDynamicX action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        self.editDynamicX.text = self.targetButton.properties[@"dynamicX"];
        [self.scrollView addSubview:self.editDynamicX];


        // Property: Dynamic Y-axis
        currentY += labelName.frame.size.height + 12.0;
        UILabel *labelDynamicY = [self addLabel:@"Dynamic Y-axis"];
        self.editDynamicY = [[UITextField alloc] initWithFrame:CGRectMake(labelDynamicY.frame.size.width + 5.0, currentY, width - labelDynamicY.frame.size.width - 5.0, labelDynamicY.frame.size.height)];
        [self.editDynamicY addTarget:self.editDynamicY action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        self.editDynamicY.text = self.targetButton.properties[@"dynamicY"];
        [self.scrollView addSubview:self.editDynamicY];
        self.editDynamicX.enabled = self.editDynamicY.enabled = self.switchDynamicPos.isOn;
    }


    currentY += labelName.frame.size.height + 12.0;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, currentY + 100.0);
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.scrollView.contentInset = self.view.safeAreaInsets;
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y + self.view.safeAreaInsets.top, self.scrollView.frame.size.width + self.view.safeAreaInsets.left, self.scrollView.frame.size.height + self.view.safeAreaInsets.bottom);
    self.view.subviews[0].frame = CGRectOffset(self.view.subviews[0].frame, self.view.safeAreaInsets.left, self.view.safeAreaInsets.top);
}

#pragma mark - Control editor
- (void)actionEditCancel {
    shouldDismissPopover = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionEditFinish {
    shouldDismissPopover = YES;
    [self dismissViewControllerAnimated:YES completion:nil];

    self.targetButton.properties[@"name"] = self.editName.text;
    self.targetButton.properties[@"width"]  = @([self.editSizeWidth.text floatValue]);
    self.targetButton.properties[@"height"] = @([self.editSizeHeight.text floatValue]);
    if (![self.targetButton isKindOfClass:[ControlDrawer class]]) {
        for (int i = 0; i < 4; i++) {
            self.targetButton.properties[@"keycodes"][i] = keyValueMap[[self.pickerMapping selectedRowInComponent:i]];
        }
    } else {
        ((ControlDrawer *)self.targetButton).drawerData[@"orientation"] =
            self.arrOrientation[self.ctrlOrientation.selectedSegmentIndex];
        [(ControlDrawer *)self.targetButton syncButtons];
    }
    self.targetButton.properties[@"isToggle"] = @(self.switchToggleable.isOn);
    self.targetButton.properties[@"passThruEnabled"] = @(self.switchMousePass.isOn);
    self.targetButton.properties[@"isSwipeable"] = @(self.switchSwipeable.isOn);
    if(@available(iOS 14.0, *)) {
        self.targetButton.properties[@"bgColor"] = @(convertUIColor2ARGB(self.colorWellBackground.selectedColor));
        self.targetButton.properties[@"strokeColor"] = @(convertUIColor2RGB(self.colorWellStroke.selectedColor));
    }
    self.targetButton.properties[@"strokeWidth"] = @((NSInteger) self.sliderStrokeWidth.value);
    self.targetButton.properties[@"cornerRadius"] = @((NSInteger) self.sliderCornerRadius.value);
    self.targetButton.properties[@"opacity"] = @(self.sliderOpacity.value / 100.0);
    self.targetButton.properties[@"isDynamicBtn"] = @(self.switchDynamicPos.isOn);
    self.targetButton.properties[@"dynamicX"] = self.editDynamicX.text;
    self.targetButton.properties[@"dynamicY"] = self.editDynamicY.text;

    [self.targetButton update];
}

- (void)sliderValueChanged:(DBNumberedSlider *)sender {
    [sender setValue:(NSInteger)sender.value animated:NO];
    if (sender.tag == TAG_SLIDER_STROKEWIDTH) {
        if(@available(iOS 14.0, *)) {
            self.colorWellStroke.enabled = sender.value != 0;
        } else {
            // TODO
        }
    }
}

- (void)switchValueChanged:(UISwitch *)sender {
    if (sender.tag == TAG_SWITCH_DYNAMICPOS) {
        self.editDynamicX.enabled = self.editDynamicY.enabled = self.switchDynamicPos.isOn;
    }
}

#pragma mark - UIPickerView stuff
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //versionTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    //setPreference(@"selected_version", versionTextField.text);
    self.editMapping.text = [NSString stringWithFormat:@"1: %@\n2: %@\n3: %@\n4: %@",
      keyCodeMap[[pickerView selectedRowInComponent:0]],
      keyCodeMap[[pickerView selectedRowInComponent:1]],
      keyCodeMap[[pickerView selectedRowInComponent:2]],
      keyCodeMap[[pickerView selectedRowInComponent:3]]
    ];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 4;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return keyCodeMap.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [keyCodeMap objectAtIndex:row];
}

- (void)closeTextField {
    [self.editSizeWidth endEditing:YES];
    [self.editSizeHeight endEditing:YES];
    [self.editMapping endEditing:YES];
}

@end
