#import <GameController/GameController.h>

#import "authenticator/BaseAuthenticator.h"
#import "customcontrols/ControlButton.h"
#import "customcontrols/ControlDrawer.h"
#import "customcontrols/ControlLayout.h"
#import "customcontrols/ControlSubButton.h"
#import "customcontrols/CustomControlsUtils.h"

#import "input/ControllerInput.h"
#import "input/KeyboardInput.h"

#import "JavaLauncher.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController2.h"
#import "MinecraftResourceUtils.h"
#import "SurfaceViewController.h"

#import "ios_uikit_bridge.h"

#include "glfw_keycodes.h"
#include "utils.h"

int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);
#define MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT        6

// Debugging only
// #define DEBUG_VISIBLE_TEXT_FIELD
// #define DEBUG_VISIBLE_TOUCH

#ifdef DEBUG_VISIBLE_TEXT_FIELD
UILabel *inputLengthView;
#endif
int inputTextLength;

int currentHotbarSlot = -1;
BOOL slideableHotbar;

// TODO: key modifiers impl


// There are private functions that we are unable to find public replacements
// (Both are found by placing breakpoints)
@interface UITextField(private)
- (NSRange)insertFilteredText:(NSString *)text;
- (id) replaceRangeWithTextWithoutClosingTyping:(UITextRange *)range replacementText:(NSString *)text;
@end


#pragma mark Class TrackedTextField
@interface TrackedTextField : UITextField
@property int lastTextPos;
@property CGFloat lastPointX;
@end

@implementation TrackedTextField

- (void)sendMultiBackspaces:(int)times {
    for (int i = 0; i < times; i++) {
        CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 1, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 0, 0);
    }
}

- (void)sendText:(NSString *)text {
    for (int i = 0; i < text.length; i++) {
        // Directly convert unichar to jchar since both are in UTF-16 encoding.
        jchar theChar = (jchar) [text characterAtIndex:i];
        if (isUseStackQueueCall) {
            CallbackBridge_nativeSendCharMods(theChar, 0);
        } else {
            CallbackBridge_nativeSendChar(theChar);
        }
#ifdef DEBUG_VISIBLE_TEXT_FIELD
        inputLengthView.text = [NSString stringWithFormat:@"length=%lu", self.text.length];
#endif
    }
}

- (void)beginFloatingCursorAtPoint:(CGPoint)point {
    [super beginFloatingCursorAtPoint:point];
    self.lastPointX = point.x;
}

// Handle cursor movement in the empty space
- (void)updateFloatingCursorAtPoint:(CGPoint)point {
    [super updateFloatingCursorAtPoint:point];

    if (self.lastPointX == 0 || (self.lastTextPos > 0 && self.lastTextPos < self.text.length)) {
        // This is handled in -[TrackedTextField closestPositionToPoint:]
        return;
    }

#ifdef DEBUG_VISIBLE_TEXT_FIELD
    inputLengthView.text = [NSString stringWithFormat:@"updateFloatingCursorAtPoint lastPointX=%f, lastTextPos=%d\n", self.lastPointX, self.lastTextPos];
#endif

    CGFloat diff = point.x - self.lastPointX;
    if (ABS(diff) < 8) {
        return;
    }
    self.lastPointX = point.x;

    int key = (diff > 0) ? GLFW_KEY_DPAD_RIGHT : GLFW_KEY_DPAD_LEFT;
    CallbackBridge_nativeSendKey(key, 0, 1, 0);
    CallbackBridge_nativeSendKey(key, 0, 0, 0);
}

- (void)endFloatingCursor {
    [super endFloatingCursor];
    self.lastPointX = 0;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    // Handle cursor movement between characters
    UITextPosition *position = [super closestPositionToPoint:point];
    int start = [self offsetFromPosition:self.beginningOfDocument toPosition:position];
    if (start - self.lastTextPos != 0) {
        int key = (start - self.lastTextPos > 0) ? GLFW_KEY_DPAD_RIGHT : GLFW_KEY_DPAD_LEFT;
        CallbackBridge_nativeSendKey(key, 0, 1, 0);
        CallbackBridge_nativeSendKey(key, 0, 0, 0);
    }
    self.lastTextPos = start;
    return position;
}

- (void)deleteBackward {
    if (self.text.length > 1) {
        // Keep the first character (a space)
        [super deleteBackward];
    } else {
        self.text = @" ";
    }
    self.lastTextPos = [super offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];

    [self sendMultiBackspaces:1];
}

- (BOOL)hasText {
    self.lastTextPos = MAX(self.lastTextPos, 1);
    return YES;
}

// Old name: insertText
- (NSRange)insertFilteredText:(NSString *)text {
    int cursorPos = [super offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];

    // This also makes sure that lastTextPos != cursorPos (text should never be empty)
    if (self.lastTextPos - cursorPos == text.length) {
        // Handle text markup by first deleting N amount of characters equal to the replaced text
        [self sendMultiBackspaces:text.length];
    }
    // What else is done by past-autocomplete (insert a space after autocompletion)
    // See -[TrackedTextField replaceRangeWithTextWithoutClosingTyping:replacementText:]

    self.lastTextPos = cursorPos + text.length;

    [self sendText:text];

    NSRange range = [super insertFilteredText:text];
    return range;
}

- (id) replaceRangeWithTextWithoutClosingTyping:(UITextRange *)range replacementText:(NSString *)text
{
    int length = [super offsetFromPosition:range.start toPosition:range.end];

    // Delete the range of needs for autocompletion
    [self sendMultiBackspaces:length];

    // Insert the autocompleted text
    [self sendText:text];

    return [super replaceRangeWithTextWithoutClosingTyping:range replacementText:text];
}

@end


#pragma mark Class SurfaceViewController
@interface SurfaceViewController ()<UITextFieldDelegate, UIPointerInteractionDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate> {
}

@property NSArray *menuArray;
@property UITableView *menuView;

@property UIView *ctrlView, *rootView;

@property TrackedTextField *inputView;
@property(nonatomic, strong) NSMutableDictionary* cc_dictionary;
@property(nonatomic, strong) NSMutableArray* swipeableButtons;
@property ControlButton* swipingButton;
@property UITouch *primaryTouch, *hotbarTouch;

@property UIView *logOutputView;

@property id mouseConnectCallback, mouseDisconnectCallback;
@property id controllerConnectCallback, controllerDisconnectCallback;

@property CGFloat mouseSpeed;
@property CGRect clickRange;
@property BOOL shouldTriggerClick;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    isControlModifiable = NO;

    setPreference(@"internal_launch_on_boot", @(NO));
    isUseStackQueueCall = [getPreference(@"internal_useStackQueue") boolValue];
    setPreference(@"internal_useStackQueue", nil);

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    // Perform Gamepad joystick ticking, while alos controlling frame rate?
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:ControllerInput.class selector:@selector(tick)];
    if (@available(iOS 15.0, *)) {
        displayLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    }
    [displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    resolutionScale = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;

    physicalWidth = roundf(screenBounds.size.width * screenScale);
    physicalHeight = roundf(screenBounds.size.height * screenScale);
    [self updateSavedResolution];

    self.rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 30.0, self.view.frame.size.height)];
    [self.view addSubview:self.rootView];

    self.ctrlView = [[ControlLayout alloc] initWithFrame:CGRectFromString(getPreference(@"control_safe_area"))];

    // Side menu
    UIScreenEdgePanGestureRecognizer *edgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightEdge:)];
    edgeGesture.edges = UIRectEdgeRight;
    edgeGesture.delegate = self;

    UIPanGestureRecognizer *menuPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightEdge:)];
    menuPanGesture.delegate = self;

    UIView *menuSwipeLineView = [[UIView alloc] initWithFrame:CGRectMake(11.0, self.view.frame.size.height/2 - 100.0, 
8.0, 200.0)];
    menuSwipeLineView.backgroundColor = UIColor.whiteColor;
    menuSwipeLineView.layer.cornerRadius = 4;
    menuSwipeLineView.userInteractionEnabled = NO;

    UIView *menuSwipeView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, 30.0, self.view.frame.size.height)];
    menuSwipeView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    [menuSwipeView addGestureRecognizer:menuPanGesture];
    [menuSwipeView addSubview:menuSwipeLineView];
    [self.rootView addSubview:menuSwipeView];

    self.menuArray = @[@"game.menu.force_close", @"Settings" /*, @"game.menu.log_output" */];

    self.menuView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 30.0, 0, 
self.view.frame.size.width * 0.3 - 36.0 * 0.7, self.view.frame.size.height)];

    //menuView.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1];
    self.menuView.dataSource = self;
    self.menuView.delegate = self;
    self.menuView.layer.cornerRadius = 12;
    self.menuView.scrollEnabled = NO;
    self.menuView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:self.menuView];


    self.surfaceView = [[GameSurfaceView alloc] initWithFrame:self.view.frame];
    self.surfaceView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    self.surfaceView.multipleTouchEnabled = YES;
    self.surfaceView.layer.contentsScale = screenScale * resolutionScale;
    self.surfaceView.layer.magnificationFilter = self.surfaceView.layer.minificationFilter = kCAFilterNearest;
    [self.surfaceView addGestureRecognizer:edgeGesture];
    [self.rootView addSubview:self.surfaceView];
    [self.rootView addSubview:self.ctrlView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [self.surfaceView addGestureRecognizer:tapGesture];

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnDoubleClick:)];
    doubleTapGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    doubleTapGesture.delegate = self;
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    doubleTapGesture.cancelsTouchesInView = NO;
    [self.surfaceView addGestureRecognizer:doubleTapGesture];

    if (@available(iOS 13.0, *)) {
        UIHoverGestureRecognizer *hoverGesture = [[UIHoverGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnHover:)];
        [self.surfaceView addGestureRecognizer:hoverGesture];
    }

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnLongpress:)];
    longpressGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    longpressGesture.cancelsTouchesInView = NO;
    longpressGesture.delegate = self;
    [self.surfaceView addGestureRecognizer:longpressGesture];

    self.scrollPanGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnTouchesScroll:)];
    self.scrollPanGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.scrollPanGesture.delegate = self;
    self.scrollPanGesture.minimumNumberOfTouches = 2;
    self.scrollPanGesture.maximumNumberOfTouches = 2;
    [self.surfaceView addGestureRecognizer:self.scrollPanGesture];

    if (@available(iOS 13.4, *)) {
        [self.surfaceView addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
    }

    // Virtual mouse
    virtualMouseEnabled = [getPreference(@"virtmouse_enable") boolValue];
    virtualMouseFrame = CGRectMake(screenBounds.size.width / 2, screenBounds.size.height / 2, 18, 27);
    self.mousePointerView = [[UIImageView alloc] initWithFrame:virtualMouseFrame];
    self.mousePointerView.hidden = !virtualMouseEnabled;
    self.mousePointerView.image = [UIImage imageNamed:@"mouse_pointer.png"];
    self.mousePointerView.userInteractionEnabled = NO;
    [self.rootView addSubview:self.mousePointerView];

    self.inputView = [[TrackedTextField alloc] initWithFrame:CGRectMake(0, -32.0, self.view.frame.size.width, 30.0)];
#ifdef DEBUG_VISIBLE_TEXT_FIELD
    inputLengthView = [[UILabel alloc] initWithFrame:CGRectMake(0, -62.0, self.view.frame.size.width, 30.0)];
    inputLengthView.text = @"length=?";
    inputLengthView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.6f];
    [self.rootView addSubview:inputLengthView];
#endif
    if (@available(iOS 13.0, *)) {
        self.inputView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    } else {
        self.inputView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }
    self.inputView.delegate = self;
    self.inputView.font = [UIFont fontWithName:@"Menlo-Regular" size:20];
    self.inputView.clearsOnBeginEditing = YES;
    self.inputView.textAlignment = NSTextAlignmentCenter;

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/controlmap/%@", getenv("POJAV_HOME"), (NSString *)getPreference(@"default_ctrl")];

    self.swipeableButtons = [[NSMutableArray alloc] init];

    [KeyboardInput initKeycodeTable];
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        self.mouseConnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCMouseDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Input: Mouse connected!");
            GCMouse* mouse = note.object;
            [self registerMouseCallbacks:mouse];
            [self setNeedsUpdateOfPrefersPointerLocked];
        }];
        self.mouseDisconnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCMouseDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Input: Mouse disconnected!");
            GCMouse* mouse = note.object;
            mouse.mouseInput.mouseMovedHandler = nil;
            mouse.mouseInput.leftButton.pressedChangedHandler = nil;
            mouse.mouseInput.middleButton.pressedChangedHandler = nil;
            mouse.mouseInput.rightButton.pressedChangedHandler = nil;
            [self setNeedsUpdateOfPrefersPointerLocked];
        }];
        if (GCMouse.current != nil) {
            [self registerMouseCallbacks: GCMouse.current];
        }
    }

    // TODO: deal with multiple controllers by letting users decide which one to use?
    self.controllerConnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSLog(@"Input: Controller connected!");
        GCController* controller = note.object;
        [ControllerInput initKeycodeTable];
        [ControllerInput registerControllerCallbacks:controller];
    }];
    self.controllerDisconnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSLog(@"Input: Controller disconnected!");
        GCController* controller = note.object;
        [ControllerInput unregisterControllerCallbacks:controller];
    }];
    if (GCController.controllers.count == 1) {
        [ControllerInput registerControllerCallbacks:GCController.controllers.firstObject];
    }

    [self.rootView addSubview:self.inputView];

/*
    self.logOutputView = [[UIView alloc] initWithFrame:self.view.frame];
    self.logOutputView.hidden = YES;
    [self.rootView addSubview:self.logOutputView];

    UINavigationBar *logNavbar = [[UINavigationBar alloc] init];
    [logNavbar
    NSLog(@"NavBar %@", logNavbar);
    //logNavbar.title = NSLocalizedString(self.menuArray[1], nil);
    [logNavbar sizeToFit];
    [self.logOutputView addSubview:logNavbar];
*/

    // [self setPreferredFramesPerSecond:1000];
    [self updateJetsamControl];
    [self updatePreferenceChanges];
    [self executebtn_special_togglebtn:0];

    [self launchMinecraft];
}

- (void)updateJetsamControl {
    if (!getEntitlementValue(@"com.apple.private.memorystatus")) {
        return;
    }
    // More 1024MB is necessary for other memory regions (native, Java GC, etc.)
    int limit = [getPreference(@"allocated_memory") intValue] + 1024;
    if (memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), limit, NULL, 0) == -1) {
        NSLog(@"Failed to set Jetsam task limit: error: %s", strerror(errno));
    } else {
        NSLog(@"Successfully set Jetsam task limit");
    }
}

- (void)updatePreferenceChanges {
    self.mouseSpeed = [getPreference(@"mouse_speed") floatValue] / 100.0;
    slideableHotbar = [getPreference(@"slideable_hotbar") boolValue];

    virtualMouseEnabled = [getPreference(@"virtmouse_enable") boolValue];
    self.mousePointerView.hidden = isGrabbing || !virtualMouseEnabled;

    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGFloat screenScale = UIScreen.mainScreen.scale;

    // Update virtual mouse scale
    CGFloat mouseScale = [getPreference(@"mouse_scale") floatValue] / 100.0;
    virtualMouseFrame = CGRectMake(screenBounds.size.width / 2, screenBounds.size.height / 2, 18.0 * mouseScale, 27 * mouseScale);
    self.mousePointerView.frame = virtualMouseFrame;

    // May break anytime lol, current: edge, tap, doubleTap, hover, longPress, scrollPan
    UILongPressGestureRecognizer *longpressGesture = self.surfaceView.gestureRecognizers[4];
    longpressGesture.minimumPressDuration = [getPreference(@"press_duration") floatValue] / 1000.0;

    self.ctrlView.frame = CGRectFromString(getPreference(@"control_safe_area"));
    [self loadCustomControls];

    // Update resolution
    resolutionScale = [getPreference(@"resolution") floatValue] / 100.0;
    self.surfaceView.layer.contentsScale = screenScale * resolutionScale;
    [self updateSavedResolution];
    CallbackBridge_nativeSendScreenSize(windowWidth, windowHeight);
}

- (void)updateSavedResolution {
    windowWidth = roundf(physicalWidth * resolutionScale);
    windowHeight = roundf(physicalHeight * resolutionScale);
    // Resolution should not be odd
    if ((windowWidth % 2) != 0) {
        --windowWidth;
    }
    if ((windowHeight % 2) != 0) {
        --windowHeight;
    }
}

- (void)launchMinecraft {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [MinecraftResourceUtils downloadClientJson:getPreference(@"selected_version") progress:nil callback:nil success:^(NSMutableDictionary *json) {
            [MinecraftResourceUtils processJVMArgs:json];
            launchJVM(
                BaseAuthenticator.current.authData[@"username"],
                json,
                windowWidth, windowHeight,
                [json[@"javaVersion"][@"majorVersion"] intValue]
            );
        }];
    });
}

- (void)loadCustomControls {
    [self.ctrlView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.swipeableButtons removeAllObjects];
    [self.cc_dictionary removeAllObjects];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/controlmap/%@", getenv("POJAV_HOME"), (NSString *)getPreference(@"default_ctrl")];

    self.cc_dictionary = parseJSONFromFile(controlFilePath);
    if (self.cc_dictionary[@"error"] != nil) {
        showDialog(self, NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"Could not open %@: %@", controlFilePath, [self.cc_dictionary[@"error"] localizedDescription]]);
        return;
    }

    CGFloat currentScale = [self.cc_dictionary[@"scaledAt"] floatValue];
    CGFloat savedScale = [getPreference(@"button_scale") floatValue];
    loadControlObject(self.ctrlView, self.cc_dictionary, ^void(ControlButton* button) {
        BOOL isSwipeable = [button.properties[@"isSwipeable"] boolValue];

        button.canBeHidden = YES;
        for (int i = 0; i < 4; i++) {
            int keycodeInt = [button.properties[@"keycodes"][i] intValue];
            button.canBeHidden &= keycodeInt != SPECIALBTN_TOGGLECTRL;
        }

        [button addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(executebtn_up_inside:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(executebtn_up_outside:) forControlEvents:UIControlEventTouchUpOutside];

        if (isSwipeable) {
            UIPanGestureRecognizer *panRecognizerButton = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(executebtn_swipe:)];
            panRecognizerButton.delegate = self;
            [button addGestureRecognizer:panRecognizerButton];
            [self.swipeableButtons addObject:button];
        }
    });

    self.cc_dictionary[@"scaledAt"] = @(savedScale);
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom | UIRectEdgeRight;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

#pragma mark - Menu functions

CGPoint lastCenterPoint;
- (void)handleRightEdge:(UIPanGestureRecognizer *)sender {
    if (lastCenterPoint.y == 0) {
        lastCenterPoint.x = self.rootView.center.x;
        lastCenterPoint.y = 1;

        // Set the height to fit the content
        CGRect menuFrame = self.menuView.frame;
        menuFrame.size.height = MIN(self.view.frame.size.height, self.menuView.contentSize.height);
        self.menuView.frame = menuFrame;
    }

    CGFloat centerX = self.rootView.bounds.size.width / 2;
    CGFloat centerY = self.rootView.bounds.size.height / 2;

    CGPoint translation = [sender translationInView:sender.view];

    if (sender.state == UIGestureRecognizerStateBegan) {
        self.menuView.hidden = NO;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.rootView.center = CGPointMake(lastCenterPoint.x + translation.x/2, centerY + translation.y/10.0);
        CGFloat scale = MAX(0.7, self.rootView.center.x / centerX);
        self.rootView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);

        self.menuView.frame = CGRectMake(self.rootView.frame.size.width, self.rootView.frame.origin.y, self.menuView.frame.size.width,  self.menuView.frame.size.height);
        // scale is in range of 0.7-1
        // 1.1 - scale produces in range of 0.4-0.1
        // result in transform scale range of 1-0.25
        self.menuView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1.1-scale)*2.5, (1.1-scale)*2.5);
    } else {
        CGPoint velocity = [sender velocityInView:sender.view];
        CGFloat scale = (velocity.x >= 0) ? 1 : 0.7;

        // calculate duration to produce smooth movement
        // FIXME: any better way?
        CGFloat duration = fabs(self.rootView.center.x - centerX * scale) / centerX + 0.1;
        duration = MIN(0.4, duration);
        //(110 - MIN(100, fabs(velocity.x))) / 100

        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut
 animations:^{
            lastCenterPoint.x = centerX * scale;
            self.rootView.center = CGPointMake(lastCenterPoint.x, centerY);
            self.rootView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            self.menuView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1.1-scale)*2.5, (1.1-scale)*2.5);
            self.menuView.frame = CGRectMake(self.rootView.frame.size.width, self.rootView.frame.origin.y, self.menuView.frame.size.width, self.menuView.frame.size.height);
        } completion:^(BOOL finished) {
            self.menuView.hidden = scale == 1.0;
        }];
    }
}

- (void)actionForceClose {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
        message:NSLocalizedString(@"game.menu.confirm.force_close", nil)
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];

    UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.rootView.center = CGPointMake(self.rootView.bounds.size.width/-2, self.rootView.center.y);
            self.menuView.frame = CGRectMake(self.view.frame.size.width, 0, 0, 0);
        } completion:^(BOOL finished) {
            exit(0);
        }];
    }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)actionOpenPreferences {
    LauncherPreferencesViewController2 *vc = [[LauncherPreferencesViewController2 alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)actionToggleLogOutput {
    self.logOutputView.hidden = !self.logOutputView.hidden;
    // TODO impl log enable/disable
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    if (@available(iOS 13.0, *)) {
        cell.backgroundColor = UIColor.systemFillColor;
    } else {
        cell.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }

    cell.textLabel.text = NSLocalizedString(self.menuArray[indexPath.row], nil);

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self actionForceClose];
            break;
        case 1:
            [self actionOpenPreferences];
            break;
        case 2:
            [self actionToggleLogOutput];
            break;
    }
}


#pragma mark - Input: send touch utilities

- (BOOL)isTouchInactive:(UITouch *)touch {
    return touch == nil || touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled;
}


- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    if (!isGrabbing) {
        screenScale *= resolutionScale;
        if (virtualMouseEnabled) {
            if (event == ACTION_MOVE) {
                virtualMouseFrame.origin.x += (location.x - lastVirtualMousePoint.x) * self.mouseSpeed;
                virtualMouseFrame.origin.y += (location.y - lastVirtualMousePoint.y) * self.mouseSpeed;
            } else if (event == ACTION_MOVE_MOTION) {
                event = ACTION_MOVE;
                virtualMouseFrame.origin.x += location.x * self.mouseSpeed;
                virtualMouseFrame.origin.y += location.y * self.mouseSpeed;
            }
            virtualMouseFrame.origin.x = clamp(virtualMouseFrame.origin.x, 0, self.view.frame.size.width);
            virtualMouseFrame.origin.y = clamp(virtualMouseFrame.origin.y, 0, self.view.frame.size.height);
            lastVirtualMousePoint = location;
            self.mousePointerView.frame = virtualMouseFrame;
            callback_SurfaceViewController_onTouch(event, virtualMouseFrame.origin.x * screenScale, virtualMouseFrame.origin.y * screenScale);
            return;
        }
        lastVirtualMousePoint = location;
    }
    callback_SurfaceViewController_onTouch(event, location.x * screenScale, location.y * screenScale);
}

#pragma mark - Input: on-surface functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)sendTouchEvent:(UITouch *)touchEvent withUIEvent:(UIEvent *)uievent withEvent:(int)event
{
    CGPoint locationInView = [touchEvent locationInView:self.rootView];

    //if (touchEvent.view == self.surfaceView) {
        switch (event) {
            case ACTION_DOWN:
                self.clickRange = CGRectMake(locationInView.x - 2, locationInView.y - 2, 5, 5);
                self.shouldTriggerClick = YES;

                break;

            case ACTION_MOVE:
                if (self.shouldTriggerClick && !CGRectContainsPoint(self.clickRange, locationInView)) {
                    self.shouldTriggerClick = NO;
                }
                break;
        }

        if (touchEvent == self.hotbarTouch && slideableHotbar && ![self isTouchInactive:self.hotbarTouch]) {
            CGFloat screenScale = [[UIScreen mainScreen] scale];
            int slot = callback_SurfaceViewController_touchHotbar(locationInView.x * screenScale, locationInView.y * screenScale);
            
            if (slot != -1 && currentHotbarSlot != slot && (event == ACTION_DOWN || currentHotbarSlot != -1)) {
                currentHotbarSlot = slot;
                CallbackBridge_nativeSendKey(slot, 0, 1, 0);
                CallbackBridge_nativeSendKey(slot, 0, 0, 0);
                return;
            } /* else if ((event == ACTION_MOVE || event == ACTION_UP) && slot == -1 && currentHotbarSlot != -1) {
                return;
            } */
            
            if (event == ACTION_DOWN && slot == -1) {
                currentHotbarSlot = -1;
            }
            /*
            if (currentHotbarSlot != -1) {
                return;
            }
            */
            return;
        }

        if (touchEvent == self.primaryTouch) {
            if ([self isTouchInactive:self.primaryTouch]) return; // FIXME: should be? ACTION_UP will never be sent
            [self sendTouchPoint:locationInView withEvent:event];
        }
    //}
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    BOOL handled = NO;

    if (@available(iOS 13.4, *)) {
        for (UIPress *press in presses) {
            if (press.key != nil && [KeyboardInput sendKeyEvent:press.key down:YES]) {
                handled = YES;
            }
        }
    }

    if (!handled) {
        [super pressesBegan:presses withEvent:event];
    }
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    BOOL handled = NO;

    if (@available(iOS 13.4, *)) {
        for (UIPress *press in presses) {
            if (press.key != nil && [KeyboardInput sendKeyEvent:press.key down:NO]) {
                handled = YES;
            }
        }
    }

    if (!handled) {
        [super pressesEnded:presses withEvent:event];
    }
}

- (BOOL)prefersPointerLocked {
    return isGrabbing;
}

- (void)registerMouseCallbacks:(GCMouse *)mouse API_AVAILABLE(ios(14.0)) {
    NSLog(@"Input: Got mouse %@", mouse);
    mouse.mouseInput.mouseMovedHandler = ^(GCMouseInput * _Nonnull mouse, float deltaX, float deltaY) {
        if (!isGrabbing) return;
        [self sendTouchPoint:CGPointMake(deltaX / 2.5, -deltaY / 2.5) withEvent:ACTION_MOVE_MOTION];
    };

    mouse.mouseInput.leftButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, pressed, 0);
    };
    mouse.mouseInput.middleButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_MIDDLE, pressed, 0);
    };
    mouse.mouseInput.rightButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_RIGHT, pressed, 0);
    };

    mouse.mouseInput.scroll.xAxis.valueChangedHandler = ^(GCControllerAxisInput * _Nonnull axis, float value) {
        CallbackBridge_nativeSendScroll(value, 0);
    };
    mouse.mouseInput.scroll.yAxis.valueChangedHandler = ^(GCControllerAxisInput * _Nonnull axis, float value) {
        CallbackBridge_nativeSendScroll(0, value);
    };
}

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (!self.shouldTriggerClick) return;

    if (sender.state == UIGestureRecognizerStateRecognized) {
        if (currentHotbarSlot == -1) {
            inputTextLength = 0;

            CallbackBridge_nativeSendMouseButton(isGrabbing == JNI_TRUE ?
                GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 1, 0);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 33 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                CallbackBridge_nativeSendMouseButton(isGrabbing == JNI_TRUE ?
                    GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 0, 0);
            });
        } else {
            CallbackBridge_nativeSendKey(currentHotbarSlot, 0, 1, 0);
            CallbackBridge_nativeSendKey(currentHotbarSlot, 0, 0, 0);
        }
    }
}

- (void)surfaceOnDoubleClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized && isGrabbing) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint point = [sender locationInView:self.rootView];
        int hotbarSlot = callback_SurfaceViewController_touchHotbar(point.x * screenScale, point.y * screenScale);
        if (hotbarSlot != -1 && currentHotbarSlot == hotbarSlot) {
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 1, 0);
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 0, 0);
        }
    }
}

- (void)surfaceOnHover:(UIHoverGestureRecognizer *)sender API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 14.0, *)) {
        if (isGrabbing) return;
    }
    CGPoint point = [sender locationInView:self.rootView];
    // NSLog(@"Mouse move!!");
    // NSLog(@"Mouse pos = %f, %f", point.x, point.y);
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self sendTouchPoint:point withEvent:ACTION_DOWN];
            break;
        case UIGestureRecognizerStateChanged:
            [self sendTouchPoint:point withEvent:ACTION_MOVE];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self sendTouchPoint:point withEvent:ACTION_UP];
            break;
        default:
            // point = CGPointMake(-1, -1);
            break;
    }
}

-(void)surfaceOnLongpress:(UILongPressGestureRecognizer *)sender
{
    if (!slideableHotbar) {
        CGPoint location = [sender locationInView:self.rootView];
        CGFloat screenScale = UIScreen.mainScreen.scale;
        currentHotbarSlot = callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.shouldTriggerClick = NO;
        if (currentHotbarSlot == -1) {
            inputTextLength = 0;

            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, 1, 0);
        } else {
            CallbackBridge_nativeSendKey(GLFW_KEY_Q, 0, 1, 0);
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        // Nothing to do here, already handled in touchesMoved
    } else {
        if (sender.state == UIGestureRecognizerStateCancelled
            || sender.state == UIGestureRecognizerStateFailed
            || sender.state == UIGestureRecognizerStateEnded)
        {
            if (currentHotbarSlot == -1) {
                CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, 0, 0);
            } else {
                
CallbackBridge_nativeSendKey(GLFW_KEY_Q, 0, 0, 0);
            }
        }
    }
}

- (void)surfaceOnTouchesScroll:(UIPanGestureRecognizer *)sender {
    if (isGrabbing) return;
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged ||
        sender.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [sender velocityInView:self.rootView];
        if (velocity.x != 0.0f || velocity.y != 0.0f) {
            CallbackBridge_nativeSendScroll(velocity.x/100.0, velocity.y/100.0);
        }
    }
}

- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)){
    return nil;
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region  API_AVAILABLE(ios(13.4)){
    return [UIPointerStyle hiddenPointerStyle];
}

#pragma mark - Input view stuff

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    CallbackBridge_nativeSendKey(GLFW_KEY_ENTER, 0, 1, 0);
    CallbackBridge_nativeSendKey(GLFW_KEY_ENTER, 0, 0, 0);
    textField.text = @" ";
    return YES;
}

#pragma mark - On-screen button functions

int currentVisibility = 1;
- (void)executebtn:(UIButton *)sender withAction:(int)action {
    ControlButton *button = (ControlButton *)sender;
    int held = action == ACTION_DOWN;
    for (int i = 0; i < 4; i++) {
        int keycode = ((NSNumber *)button.properties[@"keycodes"][i]).intValue;
        if (keycode < 0) {
            switch (keycode) {
                case SPECIALBTN_KEYBOARD:
                    if (held == 0) {
                        if (self.inputView.isFirstResponder) {
                            [self.inputView resignFirstResponder];
                            self.inputView.alpha = 1.0f;
                        } else {
                            [self.inputView becomeFirstResponder];
                            // Insert an undeletable space
                            self.inputView.text = @" ";
                            inputTextLength = 0;
                        }
                    }
                    break;

                case SPECIALBTN_MOUSEPRI:
                    CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, held, 0);
                    break;

                case SPECIALBTN_MOUSESEC:
                    CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_RIGHT, held, 0);
                    break;

                case SPECIALBTN_MOUSEMID:
                    CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_MIDDLE, held, 0);
                    break;

                case SPECIALBTN_TOGGLECTRL:
                    [self executebtn_special_togglebtn:held];
                    break;

                case SPECIALBTN_SCROLLDOWN:
                    if (!held) {
                        CallbackBridge_nativeSendScroll(0.0, 1.0);
                    }
                    break;

                case SPECIALBTN_SCROLLUP:
                    if (!held) {
                        CallbackBridge_nativeSendScroll(0.0, -1.0);
                    }
                    break;

                case SPECIALBTN_VIRTUALMOUSE:
                    if (!isGrabbing && !held) {
                        virtualMouseEnabled = !virtualMouseEnabled;
                        self.mousePointerView.hidden = !virtualMouseEnabled;
                        setPreference(@"virtmouse_enable", @(virtualMouseEnabled));
                    }
                    break;

                default:
                    NSLog(@"Warning: button %@ sent unknown special keycode: %d", button.titleLabel.text, keycode);
                    break;
            }
        } else if (keycode > 0) {
            // there's no key id 0, but we accidentally used -1 as a special key id, so we had to do that
            // if (keycode == 0) { keycode = -1; }
            // at the moment, send unknown keycode does nothing, may even cause performance issue, so ignore it
            
CallbackBridge_nativeSendKey(keycode, 0, held, 0);
        }
    }
}

- (void)executebtn_down:(ControlButton *)sender
{
    if (sender.savedBackgroundColor == nil) {
        [self executebtn:sender withAction:ACTION_DOWN];
    }
    if ([self.swipeableButtons containsObject:sender]) {
        self.swipingButton = sender;
    }
}

- (void)executebtn_swipe:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded) {
        [self executebtn_up:self.swipingButton isOutside:NO];
        return;
    }
    CGPoint location = [sender locationInView:self.ctrlView];
    for (ControlButton *button in self.swipeableButtons) {
        if (CGRectContainsPoint(button.frame, location) && (ControlButton *)self.swipingButton != button) {
            [self executebtn_up:self.swipingButton isOutside:NO];
            self.swipingButton = (ControlButton *)button;
            [self executebtn:self.swipingButton withAction:ACTION_DOWN];
            break;
        }
    }
}

- (void)executebtn_up:(ControlButton *)sender isOutside:(BOOL)isOutside
{
    if (self.swipingButton == sender) {
        [self executebtn:self.swipingButton withAction:ACTION_UP];
        self.swipingButton = nil;
    } else if (sender.savedBackgroundColor == nil) {
        [self executebtn:sender withAction:ACTION_UP];
        return;
    }

    if (isOutside || sender.savedBackgroundColor == nil) {
        return;
    }

    sender.isToggleOn = !sender.isToggleOn;
    if (sender.isToggleOn) {
        sender.backgroundColor = [self.view.tintColor colorWithAlphaComponent:CGColorGetAlpha(sender.savedBackgroundColor.CGColor)];
        [self executebtn:sender withAction:ACTION_DOWN];
    } else {
        sender.backgroundColor = sender.savedBackgroundColor;
        [self executebtn:sender withAction:ACTION_UP];
    }
}

- (void)executebtn_up_inside:(ControlButton *)sender {
    [self executebtn_up:sender isOutside:NO];
}

- (void)executebtn_up_outside:(ControlButton *)sender {
    [self executebtn_up:sender isOutside:YES];
}

- (void)executebtn_special_togglebtn:(int)held {
    if (held == 0) {
        currentVisibility = !currentVisibility;
        for (UIView *view in self.ctrlView.subviews) {
            ControlButton *button = (ControlButton *)view;
            if (button.canBeHidden) {
                if (!currentVisibility && ![button isKindOfClass:[ControlSubButton class]]) {
                    button.hidden = currentVisibility;
                    if ([button isKindOfClass:[ControlDrawer class]]) {
                        [(ControlDrawer *)button restoreButtonVisibility];
                    }
                } else if (currentVisibility) {
                    button.hidden = currentVisibility;
                }
            }
        }

#ifndef DEBUG_VISIBLE_TEXT_FIELD
        self.inputView.hidden = currentVisibility;
#endif
    }
}

#pragma mark - Input: On-screen touch events

int touchesMovedCount;
// Equals to Android ACTION_DOWN
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    int i = 0;
    for (UITouch *touch in touches) {
        if (@available(iOS 14.0, *)) { // 13.4
            if (touch.type == UITouchTypeIndirectPointer) {
                continue; // handle this in a different place
            }
        }
        CGPoint locationInView = [touch locationInView:self.rootView];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        currentHotbarSlot = callback_SurfaceViewController_touchHotbar(locationInView.x * screenScale, locationInView.y * screenScale);
        if ([self isTouchInactive:self.hotbarTouch] && currentHotbarSlot != -1) {
            self.hotbarTouch = touch;
        }
        if ([self isTouchInactive:self.primaryTouch] && currentHotbarSlot == -1) {
            self.primaryTouch = touch;
        }
        [self sendTouchEvent:touch withUIEvent:event withEvent:ACTION_DOWN];
        break;
    }
}

// Equals to Android ACTION_MOVE
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    for (UITouch *touch in touches) {
        if (@available(iOS 14.0, *)) { // 13.4
            if (isGrabbing && touch.type == UITouchTypeIndirectPointer) {
                continue; // handle this in a different place
            }
        }
        if (self.hotbarTouch != touch && [self isTouchInactive:self.primaryTouch]) {
            // Replace the inactive touch with the current active touch
            self.primaryTouch = touch;
            [self sendTouchEvent:touch withUIEvent:event withEvent:ACTION_DOWN];
        }
        [self sendTouchEvent:touch withUIEvent:event withEvent:ACTION_MOVE];
    }
}

// For ACTION_UP and ACTION_CANCEL
- (void)touchesEndedGlobal:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        if (@available(iOS 14.0, *)) { // 13.4
            if (touch.type == UITouchTypeIndirectPointer) {
                continue; // handle this in a different place
            }
        }
        [self sendTouchEvent:touch withUIEvent:event withEvent:ACTION_UP];
    }
}

// Equals to Android ACTION_UP
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self touchesEndedGlobal:touches withEvent:event];
}

// Equals to Android ACTION_CANCEL
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self touchesEndedGlobal:touches withEvent:event];
}

@end
