#import <AVFoundation/AVFoundation.h>
#import <GameController/GameController.h>
#import <objc/runtime.h>

#import "authenticator/BaseAuthenticator.h"
#import "customcontrols/ControlButton.h"
#import "customcontrols/ControlDrawer.h"
// Incomplete
#ifdef INTERNAL_VIRTUAL_JOYSTICK
#import "customcontrols/ControlJoystick.h"
#endif
#import "customcontrols/ControlSubButton.h"
#import "customcontrols/CustomControlsUtils.h"

#import "input/ControllerInput.h"
#import "input/GyroInput.h"
#import "input/KeyboardInput.h"

#import "JavaLauncher.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceUtils.h"
#import "SurfaceViewController.h"
#import "TrackedTextField.h"
#import "UIKit+hook.h"

#import "ios_uikit_bridge.h"

#include "glfw_keycodes.h"
#include "utils.h"

int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);
#define MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT        6

// Debugging only
// #define DEBUG_VISIBLE_TOUCH

int inputTextLength;

int currentHotbarSlot = -1;
BOOL slideableHotbar;

// TODO: key modifiers impl


@interface SurfaceViewController ()<UITextFieldDelegate, UIPointerInteractionDelegate, UIGestureRecognizerDelegate> {
}

@property(nonatomic) TrackedTextField *inputTextField;
@property(nonatomic) NSMutableArray* swipeableButtons;
@property(nonatomic) ControlButton* swipingButton;
@property(nonatomic) UITouch *primaryTouch, *hotbarTouch;

@property(nonatomic) UILongPressGestureRecognizer* longPressGesture;
@property(nonatomic) UITapGestureRecognizer *tapGesture, *doubleTapGesture;

@property(nonatomic) id mouseConnectCallback, mouseDisconnectCallback;
@property(nonatomic) id controllerConnectCallback, controllerDisconnectCallback;

@property(nonatomic) CGFloat screenScale;
@property(nonatomic) CGFloat mouseSpeed;
@property(nonatomic) CGRect clickRange;
@property(nonatomic) BOOL shouldTriggerClick;

@property(nonatomic) BOOL enableMouseGestures, enableHotbarGestures;

@property(nonatomic) UIImpactFeedbackGenerator *lightHaptic;
@property(nonatomic) UIImpactFeedbackGenerator *mediumHaptic;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    isControlModifiable = NO;
    
    self.lightHaptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleLight)];
    self.mediumHaptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleMedium)];

    setPreference(@"internal_launch_on_boot", @(NO));
    isUseStackQueueCall = [getPreference(@"internal_useStackQueue") boolValue];
    setPreference(@"internal_useStackQueue", nil);

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    BOOL isTVOS = realUIIdiom == UIUserInterfaceIdiomTV;
    if (!isTVOS) {
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }

    // Perform Gamepad joystick ticking, while also controlling frame rate?
    id tickInput = ^{
        [GyroInput tick];
        [ControllerInput tick];
    };
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:tickInput selector:@selector(invoke)];
    if (@available(iOS 15.0, tvOS 15.0, *)) {
        if([getPreference(@"max_framerate") boolValue]) {
            displayLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 120, 120);
        } else {
            displayLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
        }
    }
    [displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];

    CGFloat screenScale = UIScreen.mainScreen.scale;

    [self updateSavedResolution];

    self.rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 30.0, self.view.frame.size.height)];
    [self.view addSubview:self.rootView];

    self.ctrlView = [[ControlLayout alloc] initWithFrame:getSafeArea()];

    [self performSelector:@selector(initCategory_Navigation)];
    
    self.surfaceView = [[GameSurfaceView alloc] initWithFrame:self.view.frame];
    self.surfaceView.layer.contentsScale = screenScale * resolutionScale;
    self.surfaceView.layer.magnificationFilter = self.surfaceView.layer.minificationFilter = kCAFilterNearest;
    self.surfaceView.multipleTouchEnabled = YES;

    self.touchView = [[UIView alloc] initWithFrame:self.view.frame];
    self.touchView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    self.touchView.multipleTouchEnabled = YES;
    [self.touchView addSubview:self.surfaceView];

    [self.rootView addSubview:self.touchView];
    [self.rootView addSubview:self.ctrlView];

    [self performSelector:@selector(setupCategory_Navigation)];

    self.tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    self.tapGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.tapGesture.delegate = self;
    self.tapGesture.numberOfTapsRequired = 1;
    self.tapGesture.numberOfTouchesRequired = 1;
    self.tapGesture.cancelsTouchesInView = NO;
    [self.touchView addGestureRecognizer:self.tapGesture];

    self.doubleTapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnDoubleClick:)];
    self.doubleTapGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.doubleTapGesture.delegate = self;
    self.doubleTapGesture.numberOfTapsRequired = 2;
    self.doubleTapGesture.numberOfTouchesRequired = 1;
    self.doubleTapGesture.cancelsTouchesInView = NO;
    [self.touchView addGestureRecognizer:self.doubleTapGesture];

    if (@available(iOS 13.0, *)) {
        if (@available(iOS 14.0, *)) {
            // Hover is handled in GCMouse callback
        } else {
            UIHoverGestureRecognizer *hoverGesture = [[UIHoverGestureRecognizer alloc]
            initWithTarget:self action:@selector(surfaceOnHover:)];
            [self.touchView addGestureRecognizer:hoverGesture];
        }
    }

    self.longPressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnLongpress:)];
    self.longPressGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.longPressGesture.cancelsTouchesInView = NO;
    self.longPressGesture.delegate = self;
    [self.touchView addGestureRecognizer:self.longPressGesture];

    self.scrollPanGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnTouchesScroll:)];
    self.scrollPanGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.scrollPanGesture.delegate = self;
    self.scrollPanGesture.minimumNumberOfTouches = 2;
    self.scrollPanGesture.maximumNumberOfTouches = 2;
    [self.touchView addGestureRecognizer:self.scrollPanGesture];

    if (@available(iOS 13.4, *)) {
        if (!isTVOS) {
            [self.touchView addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
        }
    }

    // Virtual mouse
    virtualMouseEnabled = [getPreference(@"virtmouse_enable") boolValue];
    virtualMouseFrame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 18, 27);
    self.mousePointerView = [[UIImageView alloc] initWithFrame:virtualMouseFrame];
    self.mousePointerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin;
    self.mousePointerView.hidden = !virtualMouseEnabled;
    self.mousePointerView.image = [UIImage imageNamed:@"MousePointer"];
    self.mousePointerView.userInteractionEnabled = NO;
    [self.touchView addSubview:self.mousePointerView];

    self.inputTextField = [[TrackedTextField alloc] initWithFrame:CGRectMake(0, -32.0, self.view.frame.size.width, 30.0)];
    if (@available(iOS 13.0, *)) {
        self.inputTextField.backgroundColor = UIColor.secondarySystemBackgroundColor;
    } else {
        self.inputTextField.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }
    self.inputTextField.delegate = self;
    self.inputTextField.font = [UIFont fontWithName:@"Menlo-Regular" size:20];
    self.inputTextField.clearsOnBeginEditing = YES;
    self.inputTextField.textAlignment = NSTextAlignmentCenter;
    self.inputTextField.sendChar = ^(jchar keychar){
        CallbackBridge_nativeSendChar(keychar);
    };
    self.inputTextField.sendCharMods = ^(jchar keychar, int mods){
        CallbackBridge_nativeSendCharMods(keychar, mods);
    };
    self.inputTextField.sendKey = ^(int key, int scancode, int action, int mods) {
        CallbackBridge_nativeSendKey(key, scancode, action, mods);
    };

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/controlmap/%@", getenv("POJAV_HOME"), (NSString *)getPreference(@"default_ctrl")];

    self.swipeableButtons = [[NSMutableArray alloc] init];

    [KeyboardInput initKeycodeTable];
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        self.mouseConnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCMouseDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Input: Mouse connected!");
            GCMouse* mouse = note.object;
            [self registerMouseCallbacks:mouse];
            self.mousePointerView.hidden = isGrabbing;
            virtualMouseEnabled = YES;
            [self setNeedsUpdateOfPrefersPointerLocked];
            if([getPreference(@"hardware_hide") boolValue]) {
                self.ctrlView.hidden = YES;
            }
        }];
        self.mouseDisconnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCMouseDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Input: Mouse disconnected!");
            GCMouse* mouse = note.object;
            mouse.mouseInput.mouseMovedHandler = nil;
            mouse.mouseInput.leftButton.pressedChangedHandler = nil;
            mouse.mouseInput.middleButton.pressedChangedHandler = nil;
            mouse.mouseInput.rightButton.pressedChangedHandler = nil;
            [self setNeedsUpdateOfPrefersPointerLocked];
            if([getPreference(@"hardware_hide") boolValue]) {
                self.ctrlView.hidden = NO;
            }
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
        self.mousePointerView.hidden = isGrabbing;
        virtualMouseEnabled = YES;
        if([getPreference(@"hardware_hide") boolValue]) {
            self.ctrlView.hidden = YES;
        }
    }];
    self.controllerDisconnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSLog(@"Input: Controller disconnected!");
        GCController* controller = note.object;
        [ControllerInput unregisterControllerCallbacks:controller];
        if([getPreference(@"hardware_hide") boolValue]) {
            self.ctrlView.hidden = NO;
        }
    }];
    if (GCController.controllers.count == 1) {
        [ControllerInput registerControllerCallbacks:GCController.controllers.firstObject];
    }

    [self.rootView addSubview:self.inputTextField];

    [self performSelector:@selector(initCategory_LogView)];

    // [self setPreferredFramesPerSecond:1000];
    [self updateJetsamControl];
    [self updatePreferenceChanges];
    [self executebtn_special_togglebtn:0];

#ifdef INTERNAL_VIRTUAL_JOYSTICK
    // just for testing
    ControlJoystick *joystick = ControlJoystick.buttonWithDefaultProperties;
    [self.ctrlView addSubview:joystick];
    [joystick update];
#endif

    if (@available(iOS 13.0, *)) {
        if (UIApplication.sharedApplication.connectedScenes.count > 1 &&
            [getPreference(@"fullscreen_airplay") boolValue]) {
            [self switchToExternalDisplay];
        }
    }

    [self launchMinecraft];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 14.0, *)) {
        [self setNeedsUpdateOfPrefersPointerLocked];
    }
}

- (void)updateAudioSettings {
    NSError *sessionError = nil;
    AVAudioSessionCategory category;
    AVAudioSessionCategoryOptions options;
    if([getPreference(@"silence_with_switch") boolValue]) {
        category = AVAudioSessionCategorySoloAmbient;
    } else {
        category = AVAudioSessionCategoryPlayback;
    }
    if([getPreference(@"silence_other_audio") boolValue]) {
        options = 0;
    } else {
        options = AVAudioSessionCategoryOptionMixWithOthers;
    }
    [[AVAudioSession sharedInstance] setCategory:category withOptions:options error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
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
    // Update UITextField auto correction
    if ([getPreference(@"debug_auto_correction") boolValue]) {
        self.inputTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
    } else {
        self.inputTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    }

    BOOL gyroEnabled = [getPreference(@"gyroscope_enable") boolValue];
    BOOL gyroInvertX = [getPreference(@"gyroscope_invert_x_axis") boolValue];
    int gyroSensitivity = [getPreference(@"gyroscope_sensitivity") intValue];
    [GyroInput updateSensitivity:gyroEnabled?gyroSensitivity:0 invertXAxis:gyroInvertX];

    self.mouseSpeed = [getPreference(@"mouse_speed") floatValue] / 100.0;

    virtualMouseEnabled = [getPreference(@"virtmouse_enable") boolValue];
    self.mousePointerView.hidden = isGrabbing || !virtualMouseEnabled;

    // Update virtual mouse scale
    CGFloat mouseScale = [getPreference(@"mouse_scale") floatValue] / 100.0;
    virtualMouseFrame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 18.0 * mouseScale, 27 * mouseScale);
    self.mousePointerView.frame = virtualMouseFrame;

    self.ctrlView.frame = getSafeArea();
    [self loadCustomControls];

    // Update gestures state
    slideableHotbar = [getPreference(@"slideable_hotbar") boolValue];
    self.enableMouseGestures = [getPreference(@"gesture_mouse") boolValue];
    self.enableHotbarGestures = [getPreference(@"gesture_hotbar") boolValue];

    self.scrollPanGesture.enabled = self.enableMouseGestures;
    self.doubleTapGesture.enabled = self.enableHotbarGestures;
    self.longPressGesture.minimumPressDuration = [getPreference(@"press_duration") floatValue] / 1000.0;

    // Update audio settings
    [self updateAudioSettings];
    // Update resolution
    [self updateSavedResolution];
}

- (void)updateSavedResolution {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes.allObjects) {
            self.screenScale = scene.screen.scale;
            if (scene.session.role != UIWindowSceneSessionRoleApplication) {
                break;
            }
        }
    } else {
        self.screenScale = UIScreen.mainScreen.scale;
    }

    if (self.surfaceView.superview != nil) {
        self.surfaceView.frame = self.surfaceView.superview.frame;
    }

    resolutionScale = [getPreference(@"resolution") floatValue] / 100.0;
    self.surfaceView.layer.contentsScale = self.screenScale * resolutionScale;

    physicalWidth = roundf(self.surfaceView.frame.size.width * self.screenScale);
    physicalHeight = roundf(self.surfaceView.frame.size.height * self.screenScale);
    windowWidth = roundf(physicalWidth * resolutionScale);
    windowHeight = roundf(physicalHeight * resolutionScale);
    // Resolution should not be odd
    if ((windowWidth % 2) != 0) {
        --windowWidth;
    }
    if ((windowHeight % 2) != 0) {
        --windowHeight;
    }
    CallbackBridge_nativeSendScreenSize(windowWidth, windowHeight);
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
    self.edgeGesture.enabled = YES;
    [self.swipeableButtons removeAllObjects];
    [self.ctrlView loadControlFile:getPreference(@"default_ctrl")];
    for (ControlButton *button in self.ctrlView.subviews) {
        BOOL isSwipeable = [button.properties[@"isSwipeable"] boolValue];

        button.canBeHidden = YES;
        BOOL isMenuButton = NO;
        for (int i = 0; i < 4; i++) {
            int keycodeInt = [button.properties[@"keycodes"][i] intValue];
            button.canBeHidden &= keycodeInt != SPECIALBTN_TOGGLECTRL;
            isMenuButton |= keycodeInt == SPECIALBTN_MENU;
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

        if (@available(iOS 14, *)) {
            if (!isMenuButton) continue;
            NSMutableArray *items = [NSMutableArray new];
            for (int i = 0; i < self.menuArray.count; i++) {
                UIAction *item = [UIAction actionWithTitle:localize(self.menuArray[i], nil) image:nil identifier:nil
                    handler:^(id action) {[self didSelectMenuItem:i];}];
                [items addObject:item];
            }
            button.menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline children:items];
            button.showsMenuAsPrimaryAction = YES;
            self.edgeGesture.enabled = NO;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.rootView.bounds = CGRectMake(0, 0, size.width + 30.0, size.height);

        CGRect frame = self.view.frame;
        frame.size = size;
        self.touchView.frame = frame;
        self.inputTextField.frame = CGRectMake(0, -32.0, size.width, 30.0);
        [self viewWillTransitionToSize_LogView:frame];
        [self viewWillTransitionToSize_Navigation:frame];

        // Update custom controls button position
        self.ctrlView.frame = getSafeArea();
        [self.ctrlView.subviews makeObjectsPerformSelector:@selector(update)];

        // Update game resolution
        [self updateSavedResolution];
        [GyroInput updateOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        virtualMouseFrame = self.mousePointerView.frame;
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Input: send touch utilities

- (BOOL)isTouchInactive:(UITouch *)touch {
    return touch == nil || touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled;
}

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event
{
    CGFloat screenScale = self.screenScale;
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
            virtualMouseFrame.origin.x = clamp(virtualMouseFrame.origin.x, 0, self.surfaceView.frame.size.width);
            virtualMouseFrame.origin.y = clamp(virtualMouseFrame.origin.y, 0, self.surfaceView.frame.size.height);
            lastVirtualMousePoint = location;
            self.mousePointerView.frame = virtualMouseFrame;
            CallbackBridge_nativeSendCursorPos(event, virtualMouseFrame.origin.x * screenScale, virtualMouseFrame.origin.y * screenScale);
            return;
        }
        lastVirtualMousePoint = location;
    }
    CallbackBridge_nativeSendCursorPos(event, location.x * screenScale, location.y * screenScale);
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
            int slot = self.enableHotbarGestures ?
            callback_SurfaceViewController_touchHotbar(locationInView.x * screenScale, locationInView.y * screenScale) : -1;
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
            if (event == ACTION_MOVE && isGrabbing) {
                event = ACTION_MOVE_MOTION;
                CGPoint prevLocationInView = [touchEvent previousLocationInView:self.rootView];
                locationInView.x -= prevLocationInView.x;
                locationInView.y -= prevLocationInView.y;
            }
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
    return GCMouse.mice.count > 0;
}

- (void)registerMouseCallbacks:(GCMouse *)mouse API_AVAILABLE(ios(14.0)) {
    NSLog(@"Input: Got mouse %@", mouse);
    mouse.mouseInput.mouseMovedHandler = ^(GCMouseInput * _Nonnull mouse, float deltaX, float deltaY) {
        if (!self.view.window.windowScene.pointerLockState.locked) {
            return;
        }
        [self sendTouchPoint:CGPointMake(deltaX * 2.0 / 3.0, -deltaY * 2.0 / 3.0) withEvent:ACTION_MOVE_MOTION];
    };

    mouse.mouseInput.leftButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        if (!self.view.window.windowScene.pointerLockState.locked) {
            return;
        }
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, pressed, 0);
    };
    mouse.mouseInput.middleButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        if (!self.view.window.windowScene.pointerLockState.locked) {
            return;
        }
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_MIDDLE, pressed, 0);
    };
    mouse.mouseInput.rightButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_RIGHT, pressed, 0);
    };

    mouse.mouseInput.scroll.xAxis.valueChangedHandler = ^(GCControllerAxisInput * _Nonnull axis, float value) {
        // Workaround MC-121772 (macOS/iOS feature)
        CallbackBridge_nativeSendScroll(value, value);
    };
    mouse.mouseInput.scroll.yAxis.valueChangedHandler = ^(GCControllerAxisInput * _Nonnull axis, float value) {
        // Workaround MC-121772 (macOS/iOS feature)
        CallbackBridge_nativeSendScroll(-value, -value);
    };
}

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded){
        [self.lightHaptic impactOccurred];
    }
    
    if (!self.shouldTriggerClick) return;

    if (sender.state == UIGestureRecognizerStateRecognized) {
        if (currentHotbarSlot == -1) {
            inputTextLength = 0;

            if (!self.enableMouseGestures) return;
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
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded){
        [self.lightHaptic impactOccurred];
    }
    
    if (sender.state == UIGestureRecognizerStateRecognized && isGrabbing) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint point = [sender locationInView:self.rootView];
        int hotbarSlot = self.enableHotbarGestures ?
            callback_SurfaceViewController_touchHotbar(point.x * screenScale, point.y * screenScale) : -1;
        if (hotbarSlot != -1 && currentHotbarSlot == hotbarSlot) {
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 1, 0);
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 0, 0);
        }
    }
}

- (void)surfaceOnHover:(UIHoverGestureRecognizer *)sender API_AVAILABLE(ios(13.0)) {
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded){
        [self.lightHaptic impactOccurred];
    }
    
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
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded){
        [self.mediumHaptic impactOccurred];
    }
    
    if (!slideableHotbar) {
        CGPoint location = [sender locationInView:self.rootView];
        CGFloat screenScale = UIScreen.mainScreen.scale;
        currentHotbarSlot = self.enableHotbarGestures ?
            callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale) : -1;
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.shouldTriggerClick = NO;
        if (currentHotbarSlot == -1) {
            inputTextLength = 0;

            if (self.enableMouseGestures)
                CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, 1, 0);
        } else {
            CallbackBridge_nativeSendKey(GLFW_KEY_Q, 0, 1, 0);
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        // Nothing to do here, already handled in touchesMoved
    } else if (sender.state == UIGestureRecognizerStateCancelled
        || sender.state == UIGestureRecognizerStateFailed
            || sender.state == UIGestureRecognizerStateEnded)
    {
        if (currentHotbarSlot == -1) {
            if (self.enableMouseGestures)
                CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, 0, 0);
        } else {
            CallbackBridge_nativeSendKey(GLFW_KEY_Q, 0, 0, 0);
        }
    }
}

- (void)surfaceOnTouchesScroll:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded){
        [self.lightHaptic impactOccurred];
    }
    
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
- (void)executebtn:(ControlButton *)sender withAction:(int)action {
    int held = action == ACTION_DOWN;
    for (int i = 0; i < 4; i++) {
        int keycode = ((NSNumber *)sender.properties[@"keycodes"][i]).intValue;
        if (keycode < 0) {
            switch (keycode) {
                case SPECIALBTN_KEYBOARD:
                    if (held == 0) {
                        if (self.inputTextField.isFirstResponder) {
                            [self.inputTextField resignFirstResponder];
                            self.inputTextField.alpha = 1.0f;
                        } else {
                            [self.inputTextField becomeFirstResponder];
                            // Insert an undeletable space
                            self.inputTextField.text = @" ";
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

                case SPECIALBTN_MENU:
                    if (!held) {
                        [self actionOpenNavigationMenu];
                    }
                    break;

                default:
                    NSLog(@"Warning: button %@ sent unknown special keycode: %d", sender.titleLabel.text, keycode);
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
    [self.lightHaptic impactOccurred];
    
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
    
    [self.lightHaptic impactOccurred];
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
        currentHotbarSlot = self.enableHotbarGestures ?
            callback_SurfaceViewController_touchHotbar(locationInView.x * screenScale, locationInView.y * screenScale) : -1;
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
            if (touch.type == UITouchTypeIndirectPointer) {
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

+ (BOOL)isRunning {
    return [currentWindow().rootViewController isKindOfClass:SurfaceViewController.class];
}

@end
