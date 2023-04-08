#import "Alderis.h"
#import "Alderis-Swift.h"
#import "CustomControlsViewController.h"
#import "DBNumberedSlider.h"
#import "FileListViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/ControlDrawer.h"
#import "customcontrols/CustomControlsUtils.h"

#include <dlfcn.h>

#include "glfw_keycodes.h"
#include "utils.h"

BOOL shouldDismissPopover = YES;

@implementation ControlHandleView
// Nothing
@end

@interface CustomControlsViewController () <UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate>{
}

@property(nonatomic) NSString* currentFileName;
@property(nonatomic) CGRect selectedPoint;
@property(nonatomic) UINavigationBar* navigationBar;

@end

@implementation CustomControlsViewController
#define isInGame [self.presentingViewController respondsToSelector:@selector(loadCustomControls)]

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.undoManager removeAllActions];
    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
    isControlModifiable = YES;

    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    UILabel *guideLabel = [[UILabel alloc] initWithFrame:self.view.frame];
    guideLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    guideLabel.numberOfLines = 0;
    guideLabel.textAlignment = NSTextAlignmentCenter;
    guideLabel.textColor = UIColor.whiteColor;
    guideLabel.text = localize(@"custom_controls.hint", nil);
    [self.view addSubview:guideLabel]; 

    self.ctrlView = [[ControlLayout alloc] initWithFrame:getSafeArea()];
    if (@available(iOS 13.0, *)) {
        self.ctrlView.layer.borderColor = UIColor.labelColor.CGColor;
    } else {
        self.ctrlView.layer.borderColor = UIColor.blackColor.CGColor;
    }
    [self.view addSubview:self.ctrlView];

    // Prepare the navigation bar for safe area customization
    UINavigationItem *navigationItem = [[UINavigationItem alloc] init];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"None", @"Default", @"Custom"]];
    [segmentedControl addTarget:self action:@selector(changeSafeAreaSelection:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl setEnabled:(insets.left+insets.right)>0 forSegmentAtIndex:1];
    [self loadSafeAreaSelectionFor:segmentedControl];
    navigationItem.titleView = segmentedControl;
    navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionMenuSafeAreaCancel)];
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionMenuSafeAreaDone)];
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
    self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.navigationBar.hidden = YES;
    self.navigationBar.items = @[navigationItem];
    self.navigationBar.translucent = YES;
    [self.view addSubview:self.navigationBar];

    CGFloat buttonScale = [getPreference(@"button_scale") floatValue] / 100.0;

    self.resizeView = [[ControlHandleView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.resizeView.backgroundColor = self.view.tintColor;
    self.resizeView.layer.cornerRadius = self.resizeView.frame.size.width / 2;
    self.resizeView.clipsToBounds = YES;
    self.resizeView.hidden = YES;
    [self.resizeView addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onTouch:)]];
    [self.view addSubview:self.resizeView];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panControlArea:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    [self.ctrlView addGestureRecognizer:panGesture];

    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchControlArea:)];
    pinchGesture.delegate = self;
    [self.ctrlView addGestureRecognizer:pinchGesture];

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showControlPopover:)];
    longpressGesture.minimumPressDuration = 0.5;
    [self.ctrlView addGestureRecognizer:longpressGesture];
    self.currentFileName = [getPreference(@"default_ctrl") stringByDeletingPathExtension];
    [self loadControlFile:getPreference(@"default_ctrl")];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (isInGame) {
        isControlModifiable = NO;
        [self.presentingViewController performSelector:@selector(loadCustomControls)];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)sender shouldReceiveTouch:(UITouch *)touch {
    return sender.view != self.view || !CGRectContainsPoint(self.resizeView.frame, [sender locationInView:self.view]);
}
/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)sender shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
*/
- (void)panControlArea:(UIPanGestureRecognizer *)sender {
    static CGPoint previous;
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self setButtonMenuVisibleForView:nil];
        self.resizeView.hidden = self.ctrlView.layer.borderWidth == 0;
        self.resizeView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner;
        previous = [sender locationInView:self.view];
        return;
    } else if (self.navigationBar.hidden) {
        return;
    }

    CGPoint current = [sender locationInView:self.view];

    CGRect rect = self.ctrlView.frame;
    rect.origin.x = clamp(rect.origin.x + current.x - previous.x, 0, self.view.frame.size.width - rect.size.width);
    rect.origin.y = clamp(rect.origin.y + current.y - previous.y, 0, self.view.frame.size.height - rect.size.height);
    self.ctrlView.frame = rect;

    self.resizeView.frame = CGRectMake(CGRectGetMaxX(self.ctrlView.frame) - self.resizeView.frame.size.width, CGRectGetMaxY(self.ctrlView.frame) - self.resizeView.frame.size.height, self.resizeView.frame.size.width, self.resizeView.frame.size.height);

    previous = current;
}

- (void)pinchControlArea:(UIPinchGestureRecognizer *)sender {
    if (sender.numberOfTouches < 2 || self.navigationBar.hidden) {
        return;
    }

    static CGPoint previous;
    CGPoint current = [sender locationInView:self.view];
    if (sender.state == UIGestureRecognizerStateBegan) {
        previous = current;
        return;
    }

    self.ctrlView.frame = CGRectMake(
        clamp(self.ctrlView.frame.origin.x + current.x - previous.x, 0, self.view.frame.size.width - self.ctrlView.frame.size.width),
        clamp(self.ctrlView.frame.origin.y + current.y - previous.y, 0, self.view.frame.size.height - self.ctrlView.frame.size.height),
        clamp(self.ctrlView.frame.size.width * sender.scale, self.view.frame.size.width / 2, self.view.frame.size.width),
        clamp(self.ctrlView.frame.size.height * sender.scale, self.view.frame.size.height / 2, self.view.frame.size.height)
    );
    self.resizeView.frame = CGRectMake(CGRectGetMaxX(self.ctrlView.frame), CGRectGetMaxY(self.ctrlView.frame), self.resizeView.frame.size.width, self.resizeView.frame.size.height);

    previous = current;

    sender.scale = 1.0;
}

- (void)loadControlFile:(NSString *)file {
    [self.ctrlView loadControlFile:file];
    for (ControlButton *button in self.ctrlView.subviews) {
        [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(showControlPopover:)]];
        [button addGestureRecognizer:[[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(onTouch:)]];
    }
}

- (void)viewDidLayoutSubviews {
    if (self.navigationBar.hidden) {
        self.ctrlView.frame = getSafeArea();
    }

    // Update dynamic position for each view
    for (UIView *view in self.ctrlView.subviews) {
        if ([view isKindOfClass:[ControlButton class]]) {
            [(ControlButton *)view update];
        }
    }
}

- (void)changeSafeAreaSelection:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.ctrlView.frame = self.view.frame;
            break;
        case 1:
            self.ctrlView.frame = UIEdgeInsetsInsetRect(self.view.frame, getDefaultSafeArea());
            break;
        case 2:
            self.ctrlView.frame = getSafeArea();
            break;
    }
    self.ctrlView.userInteractionEnabled = sender.selectedSegmentIndex == 2;
    self.resizeView.hidden = sender.selectedSegmentIndex != 2;
}

- (void)loadSafeAreaSelectionFor:(UISegmentedControl *)control {
    if (CGRectEqualToRect(self.ctrlView.frame, UIScreen.mainScreen.bounds)) {
        control.selectedSegmentIndex = 0;
    } else {
        control.selectedSegmentIndex = !CGRectEqualToRect(self.ctrlView.frame, UIEdgeInsetsInsetRect(self.view.frame, getDefaultSafeArea())) + 1;
    }
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
        UIMenuItem *actionExit = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.exit", nil) action:@selector(actionMenuExit)];
        UIMenuItem *actionSave = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.save", nil) action:@selector(actionMenuSave)];
        UIMenuItem *actionLoad = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.load", nil) action:@selector(actionMenuLoad)];
        UIMenuItem *actionSetDef = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.make_default", nil) action:@selector(actionMenuSetDef)];
        UIMenuItem *actionSafeArea = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.safe_area", nil) action:@selector(actionMenuSafeArea)];
        UIMenuItem *actionAddButton = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.add_button", nil) action:@selector(actionMenuAddButton)];
        UIMenuItem *actionAddDrawer = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.control_menu.add_drawer", nil) action:@selector(actionMenuAddDrawer)];
        [menuController setMenuItems:@[actionExit, actionSave, actionLoad, actionSetDef, actionSafeArea, actionAddButton, actionAddDrawer]];

        CGPoint point = [sender locationInView:sender.view];
        self.selectedPoint = CGRectMake(point.x, point.y, 1.0, 1.0);
    } else {
        UIMenuItem *actionEdit = [[UIMenuItem alloc] initWithTitle:localize(@"Edit", nil) action:@selector(actionMenuBtnEdit)];
        UIMenuItem *actionCopy = [[UIMenuItem alloc] initWithTitle:localize(@"Copy", nil) action:@selector(actionMenuBtnCopy)];
        UIMenuItem *actionDelete = [[UIMenuItem alloc] initWithTitle:localize(@"Remove", nil) action:@selector(actionMenuBtnDelete)];
        if ([sender.view isKindOfClass:[ControlDrawer class]]) {
            UIMenuItem *actionAddSubButton = [[UIMenuItem alloc] initWithTitle:localize(@"custom_controls.button_menu.add_subbutton", nil) action:@selector(actionMenuAddSubButton)];
            [menuController setMenuItems:@[actionEdit, /* actionCopy, */ actionDelete, actionAddSubButton]];
        } else {
            [menuController setMenuItems:@[actionEdit, /* actionCopy, */ actionDelete]];
        }
        self.selectedPoint = sender.view.bounds;
    }

    if (sender.view != self.ctrlView) {
        [self.ctrlView becomeFirstResponder];
    }
    [sender.view becomeFirstResponder];

    self.resizeView.hidden = sender.view == self.ctrlView;
    [self setButtonMenuVisibleForView:sender.view];
}

- (void)actionMenuExit {
    if (self.undoManager.canUndo) {
        [self actionMenuSaveWithExit:YES];
        return;
    }
    [self dismissViewControllerAnimated:!isInGame completion:nil];
}

- (void)actionMenuSaveWithExit:(BOOL)exit {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle: localize(@"custom_controls.control_menu.save", nil)
        message:exit?localize(@"custom_controls.control_menu.exit.warn", nil):@""
        preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Name";
        textField.text = self.currentFileName;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = controller.textFields;
        UITextField *field = textFields[0];
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.ctrlView.layoutDictionary options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData == nil) {
            showDialog(self, localize(@"custom_controls.control_menu.save.error.json", nil), error.localizedDescription);
            return;
        }
        BOOL success = [jsonData writeToFile:[NSString stringWithFormat:@"%s/controlmap/%@.json", getenv("POJAV_HOME"), field.text] options:NSDataWritingAtomic error:&error];
        if (!success) {
            showDialog(self, localize(@"custom_controls.control_menu.save.error.write", nil), error.localizedDescription);
            return;
        }

        if (exit) {
            [self dismissViewControllerAnimated:!isInGame completion:nil];
        }

        self.currentFileName = field.text;
        [self.undoManager removeAllActions];
    }]];
    if (exit) {
        [controller addAction:[UIAlertAction actionWithTitle:localize(@"custom_controls.control_menu.discard_changes", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:!isInGame completion:nil];
        }]];
    }
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)actionMenuSave {
    [self actionMenuSaveWithExit:NO];
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
        [self loadControlFile:[NSString stringWithFormat:@"%@.json", name]];
    }];
}

- (void)actionMenuSetDef {
    [self actionOpenFilePicker:^void(NSString* name) {
        self.currentFileName = name;
        name = [NSString stringWithFormat:@"%@.json", name];
        [self loadControlFile:name];
        setPreference(@"default_ctrl", name);
    }];
}

- (void)actionMenuSafeArea {
    // Set _UIBarBackground alpha to 0.8
    self.navigationBar.subviews[0].alpha = 0.8;

    BOOL isCustom = ((UISegmentedControl *)self.navigationBar.items[0].titleView).selectedSegmentIndex == 2;

    self.navigationBar.hidden = !self.navigationBar.hidden;
    self.ctrlView.layer.borderWidth = self.navigationBar.hidden ? 0 : 2;
    self.ctrlView.userInteractionEnabled = self.navigationBar.hidden || isCustom;
    self.resizeView.frame = CGRectMake(CGRectGetMaxX(self.ctrlView.frame), CGRectGetMaxY(self.ctrlView.frame), self.resizeView.frame.size.width, self.resizeView.frame.size.height);
    self.resizeView.hidden = self.navigationBar.hidden || !isCustom;
    self.resizeView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner;
    self.resizeView.target = nil;
}

- (void)actionMenuSafeAreaCancel {
    self.ctrlView.frame = getSafeArea();
    [self actionMenuSafeArea];
}

- (void)actionMenuSafeAreaDone {
    setSafeArea(self.ctrlView.frame);
    [self actionMenuSafeArea];
}

- (void)actionMenuAddButtonWithDrawer:(ControlDrawer *)drawer {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = @"New";
    dict[@"keycodes"] = [[NSMutableArray alloc] initWithCapacity:4];
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
    ControlButton *button;
    if (drawer == nil) {
        button = [ControlButton buttonWithProperties:dict];
        [self doAddButton:button atIndex:@([self.ctrlView.layoutDictionary[@"mControlDataList"] count])];
        [button snapAndAlignX:self.selectedPoint.origin.x-25.0 Y:self.selectedPoint.origin.y-25.0];
        [button update];
    } else {
        button = [ControlSubButton buttonWithProperties:dict];
        ((ControlSubButton *)button).parentDrawer = drawer;
        [self doAddButton:button atIndex:@(drawer.buttons.count)];
        [button snapAndAlignX:self.selectedPoint.origin.x-25.0 Y:self.selectedPoint.origin.y-25.0];
        [drawer syncButtons];
    }

    [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(showControlPopover:)]];
    [button addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onTouch:)]];
}

- (void)actionMenuAddButton {
    [self actionMenuAddButtonWithDrawer:nil];
}

- (void)actionMenuAddDrawer {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[@"name"] = @"New";
    properties[@"dynamicX"] = @"0";
    properties[@"dynamicY"] = @"0";
    properties[@"width"] = @(50.0);
    properties[@"height"] = @(50.0);
    properties[@"opacity"] = @(1);
    properties[@"cornerRadius"] = @(0);
    properties[@"bgColor"] = @(0x4d000000);
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"orientation"] = @"FREE";
    data[@"properties"] = properties;
    data[@"buttonProperties"] = [[NSMutableArray alloc] init];
    ControlDrawer *button = [ControlDrawer buttonWithData:data];
    [self doAddButton:button atIndex:@([self.ctrlView.layoutDictionary[@"mDrawerDataList"] count])];
    [button snapAndAlignX:self.selectedPoint.origin.x-25.0 Y:self.selectedPoint.origin.y-25.0];
    [button update];

    [button addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(showControlPopover:)]];
    [button addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onTouch:)]];
}

- (void)actionMenuAddSubButton {
    self.selectedPoint = CGRectMake(self.currentGesture.view.frame.origin.x + 25.0, self.currentGesture.view.frame.origin.y + 25.0, 1.0, 1.0);
    [self actionMenuAddButtonWithDrawer:(ControlDrawer *)self.currentGesture.view];
}

- (void)actionMenuBtnCopy {
    // copy
}

- (void)actionMenuBtnDelete {
    self.resizeView.hidden = YES;
    ControlButton *button = (ControlButton *)self.currentGesture.view;
    [self doRemoveButton:button];
}

- (void)actionMenuBtnEdit {
    shouldDismissPopover = NO;
    CCMenuViewController *vc = [[CCMenuViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    vc.preferredContentSize = self.view.frame.size;
    if (![self.currentGesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
        vc.targetButton = (ControlButton *)self.currentGesture.view;
    }
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)setButtonMenuVisibleForView:(UIView *)view {
    self.resizeView.layer.maskedCorners = kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner;
    self.resizeView.target = (ControlButton *)view;
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if(@available(iOS 13.0, *)) {
        if (view) {
            [menuController showMenuFromView:view rect:self.selectedPoint];
        } else {
            [menuController hideMenu];
        }
    } else {
        if (view) {
            [menuController setTargetRect:self.selectedPoint inView:view];
        }
        [menuController setMenuVisible:(view!=nil) animated:YES];
    }
    if (view) {
        CGPoint origin = [self.ctrlView convertPoint:view.frame.origin toView:self.view];
        self.resizeView.frame = CGRectMake(origin.x + view.frame.size.width, origin.y + view.frame.size.height, self.resizeView.frame.size.width, self.resizeView.frame.size.height);
    }
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return [getPreference(@"debug_hide_home_indicator") boolValue];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)onTouchAreaHandleView:(UIPanGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateChanged) return;
    CGPoint translation = [sender translationInView:sender.view];

    // Perform safe area resize
    CGRect targetFrame = self.ctrlView.frame;
    targetFrame.size.width += translation.x;
    targetFrame.size.height += translation.y;
    self.ctrlView.frame = targetFrame;

    // Keep track of handle view location
    targetFrame = self.resizeView.frame;
    targetFrame.origin.x = CGRectGetMaxX(self.ctrlView.frame) - targetFrame.size.width;
    targetFrame.origin.y = CGRectGetMaxY(self.ctrlView.frame) - targetFrame.size.height;
    self.resizeView.frame = targetFrame;

    [sender setTranslation:CGPointZero inView:sender.view];
}

- (void)onTouchButtonHandleView:(UIPanGestureRecognizer *)sender {
    static CGRect origButtonRect;

    CGPoint translation = [sender translationInView:sender.view];
    CGFloat width, height;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            // Save old button frame
            origButtonRect = self.resizeView.target.frame;
        } break;
        case UIGestureRecognizerStateChanged: {
            // Perform button resize
            width = MAX(10, [self.resizeView.target.properties[@"width"] floatValue] + translation.x);
            height = MAX(10, [self.resizeView.target.properties[@"height"] floatValue] + translation.y);
            self.resizeView.target.properties[@"width"] = @(width);
            self.resizeView.target.properties[@"height"] = @(height);
            [self.resizeView.target update];
            [sender setTranslation:CGPointZero inView:sender.view];

            // Keep track of handle view location
            self.resizeView.frame = CGRectMake(CGRectGetMaxX(self.resizeView.target.frame), CGRectGetMaxY(self.resizeView.target.frame),
                self.resizeView.frame.size.width, self.resizeView.frame.size.height);
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self doMoveOrResizeButton:self.resizeView.target from:origButtonRect to:self.resizeView.target.frame];
        } break;
        default: break;
    }
}

- (void)onTouch:(UIPanGestureRecognizer *)sender {
    static CGRect origButtonRect;

    if ([sender.view isKindOfClass:ControlHandleView.class]) {
        if (self.resizeView.target == nil) {
            [self onTouchAreaHandleView:sender];
        } else {
            [self onTouchButtonHandleView:sender];
        }
        return;
    }

    CGPoint translation = [sender translationInView:sender.view];

    ControlButton *button = (ControlButton *)sender.view;
    if ([button isKindOfClass:ControlSubButton.class] &&
        ![((ControlSubButton *)button).parentDrawer.drawerData[@"orientation"] isEqualToString:@"FREE"]) return;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            origButtonRect = button.frame;
            [self setButtonMenuVisibleForView:nil];
            self.resizeView.hidden = NO;
            self.resizeView.target = button;
        } break;
        case UIGestureRecognizerStateChanged: {
            //button.center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
            [button snapAndAlignX:clamp(button.frame.origin.x+translation.x, 0, self.ctrlView.frame.size.width - button.frame.size.width) Y:clamp(button.frame.origin.y+translation.y, 0, self.ctrlView.frame.size.height - button.frame.size.height)];
            [sender setTranslation:CGPointZero inView:button];
            self.resizeView.frame = CGRectMake(CGRectGetMaxX(button.frame), CGRectGetMaxY(button.frame), self.resizeView.frame.size.width, self.resizeView.frame.size.height);
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self doMoveOrResizeButton:button from:origButtonRect to:button.frame];
        } break;
        default: break;
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

@end

#define TAG_SLIDER_STROKEWIDTH 10
#define TAG_SLIDER_CORNERRADIUS 11
#define TAG_SLIDER_OPACITY 12
#define TAG_SWITCH_DYNAMICPOS 13

#pragma mark - CCMenuViewController

CGFloat currentY;

@interface CCMenuViewController () <UIPickerViewDataSource, UIPickerViewDelegate, HBColorPickerDelegate> {
}

@property(nonatomic) NSMutableArray *keyCodeMap, *keyValueMap;
@property(nonatomic) NSArray* arrOrientation;
@property(nonatomic) NSMutableDictionary* oldProperties;

@property UITextField *activeField;
@property(nonatomic) UIScrollView* scrollView;
@property(nonatomic) UITextField *editName, *editSizeWidth, *editSizeHeight;
@property(nonatomic) UITextView* editMapping;
@property(nonatomic) UIPickerView* pickerMapping;
@property(nonatomic) UISegmentedControl* ctrlOrientation;
@property(nonatomic) UISwitch *switchToggleable, *switchMousePass, *switchSwipeable;
@property(nonatomic) UIColorWell API_AVAILABLE(ios(14.0)) *colorWellINTBackground, *colorWellINTStroke;
@property(nonatomic) HBColorWell *colorWellEXTBackground, *colorWellEXTStroke;
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

    self.keyCodeMap = [[NSMutableArray alloc] init];
    self.keyValueMap = [[NSMutableArray alloc] init];
    initKeycodeTable(self.keyCodeMap, self.keyValueMap);

    self.oldProperties = self.targetButton.properties.mutableCopy;
    currentY = 6.0;

    CGFloat shortest = MIN(self.view.frame.size.width, self.view.frame.size.height);
    CGFloat tempW = MIN(self.view.frame.size.width * 0.75, shortest);
    CGFloat tempH = MIN(self.view.frame.size.height * 0.6, shortest);

    UIBlurEffectStyle blurStyle;
    UIVisualEffectView *blurView;
    if (@available(iOS 13.0, *)) {
        blurStyle = UIBlurEffectStyleSystemMaterial;
    } else {
        blurStyle = UIBlurEffectStyleExtraLight;
    }
    blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
    blurView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    blurView.frame = CGRectMake(
        (self.view.frame.size.width - MAX(tempW, tempH))/2,
        (self.view.frame.size.height - MIN(tempW, tempH))/2,
        MAX(tempW, tempH), MIN(tempW, tempH));
    blurView.layer.cornerRadius = 10.0;
    blurView.clipsToBounds = YES;
    [self.view addSubview:blurView];

    UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIToolbar *popoverToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0,   blurView.frame.size.width, 44.0)];
    UIPanGestureRecognizer *dragVCGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragViewController:)];
    dragVCGesture.minimumNumberOfTouches = 1;
    dragVCGesture.maximumNumberOfTouches = 1;
    [popoverToolbar addGestureRecognizer:dragVCGesture];
    
    UIBarButtonItem *popoverCancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionEditCancel)];
    UIBarButtonItem *popoverDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionEditFinish)];
    popoverToolbar.items = @[popoverCancelButton, btnFlexibleSpace, popoverDoneButton]; 
    [blurView.contentView addSubview:popoverToolbar];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5.0, popoverToolbar.frame.size.height, blurView.frame.size.width - 10.0, blurView.frame.size.height - popoverToolbar.frame.size.height)];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [blurView.contentView addSubview:self.scrollView];

    UIToolbar *editPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, blurView.frame.size.width, 44.0)];
 
    UIBarButtonItem *editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTextField)];
    editPickToolbar.items = @[btnFlexibleSpace, editDoneButton];

    CGFloat width = blurView.frame.size.width - 10.0;
    CGFloat height = blurView.frame.size.height - 10.0;


    // Property: Name
    UILabel *labelName = [self addLabel:localize(@"custom_controls.button_edit.name", nil)];
    self.editName = [[UITextField alloc] initWithFrame:CGRectMake(labelName.frame.size.width + 5.0, currentY, width - labelName.frame.size.width - 5.0, labelName.frame.size.height)];
    [self.editName addTarget:self action:@selector(textFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.editName addTarget:self.editName action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.editName.placeholder = localize(@"custom_controls.button_edit.name", nil);
    self.editName.returnKeyType = UIReturnKeyDone;
    self.editName.text = self.targetButton.properties[@"name"];
    [self.scrollView addSubview:self.editName];

    if (![self.targetButton isKindOfClass:[ControlSubButton class]]) {
        // Property: Size
        currentY += labelName.frame.size.height + 12.0;
        UILabel *labelSize = [self addLabel:localize(@"custom_controls.button_edit.size", nil)];
        // width / 2.0 + (labelSize.frame.size.width + 4.0) / 2.0
        CGFloat editSizeWidthValue = (width - labelSize.frame.size.width) / 2 - labelSize.frame.size.height / 2;
        UILabel *labelSizeX = [[UILabel alloc] initWithFrame:CGRectMake(labelSize.frame.size.width + editSizeWidthValue, labelSize.frame.origin.y, labelSize.frame.size.height, labelSize.frame.size.height)];
        labelSizeX.text = @"x";
        [self.scrollView addSubview:labelSizeX];
        self.editSizeWidth = [[UITextField alloc] initWithFrame:CGRectMake(labelSize.frame.size.width, labelSize.frame.origin.y, editSizeWidthValue, labelSize.frame.size.height)];
        [self.editSizeWidth addTarget:self action:@selector(textFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
        [self.editSizeWidth addTarget:self.editSizeWidth action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        self.editSizeWidth.keyboardType = UIKeyboardTypeDecimalPad;
        self.editSizeWidth.placeholder = @"width";
        self.editSizeWidth.returnKeyType = UIReturnKeyDone;
        self.editSizeWidth.text = [self.targetButton.properties[@"width"] stringValue];
        self.editSizeWidth.textAlignment = NSTextAlignmentCenter;
        [self.scrollView addSubview:self.editSizeWidth];
        self.editSizeHeight = [[UITextField alloc] initWithFrame:CGRectMake(labelSizeX.frame.origin.x + labelSizeX.frame.size.width, labelSize.frame.origin.y, editSizeWidthValue, labelSize.frame.size.height)];
        [self.editSizeHeight addTarget:self action:@selector(textFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
        [self.editSizeHeight addTarget:self.editSizeHeight action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        self.editSizeHeight.keyboardType = UIKeyboardTypeDecimalPad;
        self.editSizeHeight.placeholder = @"height";
        self.editSizeHeight.returnKeyType = UIReturnKeyDone;
        self.editSizeHeight.text = [self.targetButton.properties[@"height"] stringValue];
        self.editSizeHeight.textAlignment = NSTextAlignmentCenter;
        [self.scrollView addSubview:self.editSizeHeight];
    }


    currentY += labelName.frame.size.height + 12.0;
    if (![self.targetButton isKindOfClass:[ControlDrawer class]]) {
        // Property: Mapping
        UILabel *labelMapping = [self addLabel:localize(@"custom_controls.button_edit.mapping", nil)];

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
            [self.pickerMapping selectRow:[self.keyValueMap indexOfObject:self.targetButton.properties[@"keycodes"][i]] inComponent:i animated:NO];
        }
        [self pickerView:self.pickerMapping didSelectRow:0 inComponent:0];

        self.editMapping.inputAccessoryView = editPickToolbar;
        self.editMapping.inputView = self.pickerMapping;
        [self.scrollView addSubview:self.editMapping];
        currentY += self.editMapping.frame.size.height + 12.0;
    } else {
        // Property: Orientation
        self.arrOrientation = @[@"DOWN", @"LEFT", @"UP", @"RIGHT", @"FREE"];
        UILabel *labelOrientation = [self addLabel:localize(@"custom_controls.button_edit.orientation", nil)];
        self.ctrlOrientation = [[UISegmentedControl alloc] initWithItems:self.arrOrientation];
        [self.ctrlOrientation addTarget:self action:@selector(orientationValueChanged) forControlEvents:UIControlEventValueChanged];
        self.ctrlOrientation.frame = CGRectMake(labelOrientation.frame.size.width + 5.0, currentY - 5.0, width - labelOrientation.frame.size.width - 5.0, 30.0);
        self.ctrlOrientation.selectedSegmentIndex = [self.arrOrientation indexOfObject:
            ((ControlDrawer *)self.targetButton).drawerData[@"orientation"]];
        [self.scrollView addSubview:self.ctrlOrientation];
        currentY += labelName.frame.size.height + 12.0;
    }


    // Property: Toggleable
    UILabel *labelToggleable = [self addLabel:localize(@"custom_controls.button_edit.toggleable", nil)];
    self.switchToggleable = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchToggleable setOn:[self.targetButton.properties[@"isToggle"] boolValue] animated:NO];
    [self.scrollView addSubview:self.switchToggleable];


    // Property: Mouse pass
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelMousePass = [self addLabel:localize(@"custom_controls.button_edit.mouse_pass", nil)];
    self.switchMousePass = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchMousePass setOn:[self.targetButton.properties[@"passThruEnabled"] boolValue]];
    [self.scrollView addSubview:self.switchMousePass];


    // Property: Swipeable
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelSwipeable = [self addLabel:localize(@"custom_controls.button_edit.swipeable", nil)];
    self.switchSwipeable = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currentY - 5.0, 50.0, 30)];
    [self.switchSwipeable setOn:[self.targetButton.properties[@"isSwipeable"] boolValue]];
    [self.scrollView addSubview:self.switchSwipeable];


    // Property: Background color
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelBGColor = [self addLabel:localize(@"custom_controls.button_edit.bg_color", nil)];
    if(@available(iOS 14.0, *)) {
        self.colorWellINTBackground = [[UIColorWell alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        [self.colorWellINTBackground addTarget:self action:@selector(colorWellChanged) forControlEvents:UIControlEventValueChanged];
        self.colorWellINTBackground.selectedColor = self.targetButton.backgroundColor;
        [self.scrollView addSubview:self.colorWellINTBackground];
    } else {
        if (!dlopen("Alderis.framework/Alderis", RTLD_NOW)) {
            NSLog(@"Cannot load Alderis framework: %s", dlerror());
        }

        self.colorWellEXTBackground = [[NSClassFromString(@"HBColorWell") alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        self.colorWellEXTBackground.color = self.targetButton.backgroundColor;
        self.colorWellEXTBackground.isDragInteractionEnabled = YES;
        self.colorWellEXTBackground.isDropInteractionEnabled = YES;
        [self.colorWellEXTBackground addTarget:self action:@selector(presentColorPicker:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.colorWellEXTBackground];
    }


    // Property: Stroke width
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelStrokeWidth = [self addLabel:localize(@"custom_controls.button_edit.stroke_width", nil)];
    self.sliderStrokeWidth = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelStrokeWidth.frame.size.width + 5.0, currentY - 5.0, width - labelStrokeWidth.frame.size.width - 5.0, 30.0)];
    self.sliderStrokeWidth.continuous = YES;
    self.sliderStrokeWidth.maximumValue = 100;
    self.sliderStrokeWidth.tag = TAG_SLIDER_STROKEWIDTH;
    self.sliderStrokeWidth.value = [self.targetButton.properties[@"strokeWidth"] intValue];
    [self.sliderStrokeWidth addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderStrokeWidth];


    // Property: Stroke color
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelStrokeColor = [self addLabel:localize(@"custom_controls.button_edit.stroke_color", nil)];
    if(@available(iOS 14.0, *)) {
        self.colorWellINTStroke = [[UIColorWell alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        [self.colorWellINTStroke addTarget:self action:@selector(colorWellChanged) forControlEvents:UIControlEventValueChanged];
        self.colorWellINTStroke.selectedColor = [[UIColor alloc] initWithCGColor:self.targetButton.layer.borderColor];
        [self.scrollView addSubview:self.colorWellINTStroke];
    } else {
        self.colorWellEXTStroke = [[NSClassFromString(@"HBColorWell") alloc] initWithFrame:CGRectMake(width - 42.0, currentY - 5.0, 30.0, 30.0)];
        self.colorWellEXTStroke.color = [[UIColor alloc] initWithCGColor:self.targetButton.layer.borderColor];
        [self.colorWellEXTStroke addTarget:self action:@selector(presentColorPicker:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.colorWellEXTStroke];
    }
    [self sliderValueChanged:self.sliderStrokeWidth];


    // Property: Corner radius
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelCornerRadius = [self addLabel:localize(@"custom_controls.button_edit.corner_radius", nil)];
    self.sliderCornerRadius = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelCornerRadius.frame.size.width + 5.0, currentY - 5.0, width - labelCornerRadius.frame.size.width - 5.0, 30.0)];
    self.sliderCornerRadius.continuous = YES;
    self.sliderCornerRadius.maximumValue = 100;
    self.sliderCornerRadius.tag = TAG_SLIDER_CORNERRADIUS;
    self.sliderCornerRadius.value = [self.targetButton.properties[@"cornerRadius"] intValue];
    [self.sliderCornerRadius addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderCornerRadius];


    // Property: Button Opacity
    currentY += labelName.frame.size.height + 12.0;
    UILabel *labelOpacity = [self addLabel:localize(@"custom_controls.button_edit.opacity", nil)];
    self.sliderOpacity = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(labelOpacity.frame.size.width + 5.0, currentY - 5.0, width - labelOpacity.frame.size.width - 5.0, 30.0)];
    self.sliderOpacity.continuous = YES;
    self.sliderOpacity.minimumValue = 1;
    self.sliderOpacity.maximumValue = 100;
    self.sliderOpacity.tag = TAG_SLIDER_OPACITY;
    self.sliderOpacity.value = [self.targetButton.properties[@"opacity"] floatValue] * 100.0;
    [self.sliderOpacity addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.sliderOpacity];


    currentY += labelName.frame.size.height + 12.0;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, currentY);
}

#pragma mark - Gesture callback
- (void)dragViewController:(UIPanGestureRecognizer *)sender {
    static CGPoint lastPoint;
    CGPoint point = [sender translationInView:self.view];
    if (sender.state != UIGestureRecognizerStateBegan) {
        CGRect rect = self.view.subviews[0].frame;
        rect.origin.x = clamp(rect.origin.x - lastPoint.x + point.x, -self.view.frame.size.width/2, self.view.frame.size.width - sender.view.frame.size.width/2);
        rect.origin.y = clamp(rect.origin.y - lastPoint.y + point.y, 0, self.view.frame.size.height - sender.view.frame.size.height);
        self.view.subviews[0].frame = rect;
    }
    lastPoint = point;
}

#pragma mark - Alderis functions
// HBColorWell
- (void)presentColorPicker:(HBColorWell *)sender {
    HBColorPickerViewController *vc = [[NSClassFromString(@"HBColorPickerViewController") alloc] init];
    vc.delegate = self;
    vc.popoverPresentationController.sourceView = sender;
    vc.configuration = [[NSClassFromString(@"HBColorPickerConfiguration") alloc] initWithColor:sender.color];
    if (sender == self.colorWellEXTBackground) {
        vc.configuration.title = @"Background color";
        vc.configuration.supportsAlpha = YES;
    } else if (sender == self.colorWellEXTStroke) {
        vc.configuration.title = @"Stroke color";
        vc.configuration.supportsAlpha = YES;
    } else {
        NSLog(@"Unknown color well: %@", sender);
        abort();
    }
    [self presentViewController:vc animated:YES completion:nil];
}

// iOS 14 color well
- (void)colorWellChanged {
    if(@available(iOS 14.0, *)) {
        self.targetButton.properties[@"bgColor"] = @(convertUIColor2ARGB(self.colorWellINTBackground.selectedColor));
        self.targetButton.properties[@"strokeColor"] = @(convertUIColor2ARGB(self.colorWellINTStroke.selectedColor));
    }
    [self.targetButton update];
}

// HBColorPickerDelegate (iOS 12-13 color well)
- (void)colorPicker:(HBColorPickerViewController *)picker didSelectColor:(UIColor *)color {
    if ([picker.configuration.title isEqualToString:@"Background color"]) {
        self.colorWellEXTBackground.color = color;
        self.targetButton.properties[@"bgColor"] = @(convertUIColor2ARGB(self.colorWellEXTBackground.color));
    } else if ([picker.configuration.title isEqualToString:@"Stroke color"]) {
        self.colorWellEXTStroke.color = color;
        self.targetButton.properties[@"strokeColor"] = @(convertUIColor2ARGB(self.colorWellEXTStroke.color));
    } else {
        NSLog(@"Unknown color well: %@", picker.configuration.title);
        abort();
    }
    [self.targetButton update];
}

 - (void)textFieldEditingChanged {
    self.targetButton.properties[@"name"] = self.editName.text;
    self.targetButton.properties[@"width"]  = @([self.editSizeWidth.text floatValue]);
    self.targetButton.properties[@"height"] = @([self.editSizeHeight.text floatValue]);
    [self.targetButton update];
}

#pragma mark - Control editor
- (void)actionEditCancel {
    self.targetButton.properties = self.oldProperties;
    [self.targetButton update];
    shouldDismissPopover = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionEditFinish {
    self.targetButton.properties[@"isToggle"] = @(self.switchToggleable.isOn);
    self.targetButton.properties[@"passThruEnabled"] = @(self.switchMousePass.isOn);
    self.targetButton.properties[@"isSwipeable"] = @(self.switchSwipeable.isOn);

    NSMutableDictionary *newProperties = self.targetButton.properties.mutableCopy;

    for (NSString *key in self.oldProperties) {
        if ([self.oldProperties[key] isEqual:newProperties[key]]) {
            [newProperties removeObjectForKey:key];
        }
    }

    [(CustomControlsViewController *)self.presentingViewController
        doUpdateButton:self.targetButton from:self.oldProperties to:newProperties];
    self.oldProperties = nil;
    shouldDismissPopover = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)orientationValueChanged {
    ((ControlDrawer *)self.targetButton).drawerData[@"orientation"] =
        self.arrOrientation[self.ctrlOrientation.selectedSegmentIndex];
    [(ControlDrawer *)self.targetButton syncButtons];
}

- (void)sliderValueChanged:(DBNumberedSlider *)sender {
    [sender setValue:(NSInteger)sender.value animated:NO];
    if (sender.tag == TAG_SLIDER_STROKEWIDTH) {
        if(@available(iOS 14.0, *)) {
            self.colorWellINTStroke.enabled = sender.value != 0;
        } else {
            self.colorWellEXTStroke.enabled = sender.value != 0;
        }
        self.targetButton.properties[@"strokeWidth"] = @((NSInteger) self.sliderStrokeWidth.value);
    } else {
        self.targetButton.properties[@"cornerRadius"] = @((NSInteger) self.sliderCornerRadius.value);
        self.targetButton.properties[@"opacity"] = @(self.sliderOpacity.value / 100.0);
    }
    [self.targetButton update];
}

#pragma mark - UIPickerView stuff
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = (UILabel *)view;
    if (label == nil) {
        label = [UILabel new];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.5;
        label.textAlignment = NSTextAlignmentCenter;
    }
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];

    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.editMapping.text = [NSString stringWithFormat:@"1: %@\n2: %@\n3: %@\n4: %@",
        self.keyCodeMap[[pickerView selectedRowInComponent:0]],
        self.keyCodeMap[[pickerView selectedRowInComponent:1]],
        self.keyCodeMap[[pickerView selectedRowInComponent:2]],
        self.keyCodeMap[[pickerView selectedRowInComponent:3]]
    ];

    for (int i = 0; i < 4; i++) {
        self.targetButton.properties[@"keycodes"][i] = self.keyValueMap[[self.pickerMapping selectedRowInComponent:i]];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 4;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.keyCodeMap.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.keyCodeMap objectAtIndex:row];
}

- (void)closeTextField {
    [self.editMapping endEditing:YES];
}

@end
