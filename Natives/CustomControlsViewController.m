#import "CustomControlsViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/CustomControlsUtils.h"

#include "glfw_keycodes.h"
#include "utils.h"

int width;
NSMutableArray *keyCodeMap, *keyValueMap;

@interface ControlLayout ()
@end
@implementation ControlLayout
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(actionExit:)) {
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

    UIPanGestureRecognizer *panRecognizer;
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(wasDragged:)];

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.offsetView addGestureRecognizer:longpressGesture];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/%@", getenv("POJAV_PATH_CONTROL"), (NSString *)getPreference(@"default_ctrl")];

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
            });
        }
    }

    [self initKeyCodeMap];
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

    if (![sender.view isKindOfClass:[ControlButton class]]) {
        UIMenuItem *actionExit = [[UIMenuItem alloc] initWithTitle:@"Exit" action:@selector(actionMenuExit)];
        //UIMenuItem *actionSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionSave:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuItems:@[actionExit]];
        CGPoint point = [sender locationInView:sender.view];
        [sender.view becomeFirstResponder];
        if(@available(iOS 13.0, *)) {
            [menuController showMenuFromView:sender.view rect:CGRectMake(point.x, point.y, 1.0, 1.0)];
        } else {
            [menuController setTargetRect:CGRectMake(point.x, point.y, 1.0, 1.0) inView:sender.view];
            [menuController setMenuVisible:YES animated:YES];
        }
        return;
    }

    CCMenuViewController *vc = [[CCMenuViewController alloc] init];
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

- (void)actionMenuExit {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
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

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
     return NO;
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

#pragma mark - CCMenuViewController
@interface CCMenuViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
}

@property(nonatomic) UIScrollView* scrollView;
@property(nonatomic) UITextField *editName, *editSizeWidth, *editSizeHeight;
@property(nonatomic) UITextView* editMapping;
@property(nonatomic) UIPickerView* pickerMapping;

@end

@implementation CCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.frame = CGRectMake(0, 0, self.preferredContentSize.width, self.preferredContentSize.height);

    UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIToolbar *popoverToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.preferredContentSize.width, 44.0)];
    UIBarButtonItem *popoverCancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionEditCancel)];
    UIBarButtonItem *popoverDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionEditFinish)];
    popoverToolbar.items = @[popoverCancelButton, btnFlexibleSpace, popoverDoneButton];
    [self.view addSubview:popoverToolbar];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5.0, popoverToolbar.frame.size.height + 5.0, self.preferredContentSize.width - 10.0, self.preferredContentSize.height - popoverToolbar.frame.size.height - 10.0)];
    [self.view addSubview:self.scrollView];

    UIToolbar *editPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTextField)];
    editPickToolbar.items = @[btnFlexibleSpace, editDoneButton];

    CGFloat width = self.view.frame.size.width - 10.0;
    CGFloat height = self.view.frame.size.height - 10.0;
    CGFloat currentY = 0; //popoverToolbar.frame.origin.y + popoverToolbar.frame.size.height;


    // Property: Name
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(0.0, currentY, 0.0, 0.0)];
    labelName.text = @"Name";
    labelName.numberOfLines = 0;
    [labelName sizeToFit];
    [self.scrollView addSubview:labelName];
    self.editName = [[UITextField alloc] initWithFrame:CGRectMake(labelName.frame.size.width + 4.0, currentY, width - labelName.frame.size.width - 4.0, labelName.frame.size.height)];
    [self.editName addTarget:self.editName action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.editName.placeholder = @"Name";
    self.editName.text = self.targetButton.properties[@"name"];
    [self.scrollView addSubview:self.editName];

    // Property: Size
    currentY += labelName.frame.size.height + 4.0;
    UILabel *labelSize = [[UILabel alloc] initWithFrame:CGRectMake(0.0, currentY, 0.0, 0.0)];
    labelSize.text = @"Size";
    labelSize.numberOfLines = 0;
    [labelSize sizeToFit];
    [self.scrollView addSubview:labelSize];
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


    // Property: Mapping
    currentY += labelName.frame.size.height + 4.0;
    UILabel *labelMapping = [[UILabel alloc] initWithFrame:CGRectMake(0.0, currentY, 0.0, 0.0)];
    labelMapping.text = @"Mapping";
    labelMapping.numberOfLines = 0;
    [labelMapping sizeToFit];
    [self.scrollView addSubview:labelMapping];

    self.editMapping = [[UITextView alloc] initWithFrame:CGRectMake(0,0,1,1)];
    self.editMapping.text = @"\n\n\n";
    [self.editMapping sizeToFit];
    self.editMapping.scrollEnabled = NO;
    self.editMapping.frame = CGRectMake(labelMapping.frame.size.width + 4.0, labelMapping.frame.origin.y, width - labelMapping.frame.size.width - 4.0, self.editMapping.frame.size.height);

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


    // Property: Toggleable
    


    // Property: Mouse pass
    


    // Property: Swipeable
    


    // Property: Background color
    


    // Property: Stroke width
    


    // Property: Corner radius
    


    // Property: Button Opacity
    


    // Property: Dynamic X-axis
    


    // Property: Dynamic Y-axis
    


    // Property: Button Opacity
    
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.scrollView.contentInset = self.view.safeAreaInsets;
    self.view.subviews[0].frame = CGRectOffset(self.view.subviews[0].frame, self.view.safeAreaInsets.left, self.view.safeAreaInsets.top);
}

#pragma mark - Control editor
- (void)actionEditCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionEditFinish {
    [self dismissViewControllerAnimated:YES completion:nil];

    self.targetButton.properties[@"name"] = self.editName.text;
    self.targetButton.properties[@"width"]  = @([self.editSizeWidth.text floatValue]);
    self.targetButton.properties[@"height"] = @([self.editSizeHeight.text floatValue]);
    for (int i = 0; i < 4; i++) {
        self.targetButton.properties[@"keycodes"][i] = keyValueMap[[self.pickerMapping selectedRowInComponent:i]];
    }
    
    
    [self.targetButton update];
}

- (void)actionSetDef {
    [self dismissViewControllerAnimated:YES completion:nil];
    
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
