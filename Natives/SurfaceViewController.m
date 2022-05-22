#import <GameController/GameController.h>

#import "LauncherPreferences.h"
#import "SurfaceViewController.h"
#import "egl_bridge.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/ControlButton.h"
#import "customcontrols/ControlDrawer.h"
#import "customcontrols/ControlSubButton.h"
#import "customcontrols/CustomControlsUtils.h"

#import "KeyboardInput.h"

#include "glfw_keycodes.h"
#include "utils.h"

#include "EGL/egl.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"

// Debugging only
// #define DEBUG_VISIBLE_TEXT_FIELD
// #define DEBUG_VISIBLE_TOUCH

#define INPUT_SPACE_CHAR @"                                        "
#define INPUT_FULL_LENGTH 40
#define INPUT_SPACE_LENGTH 20

#ifdef DEBUG_VISIBLE_TEXT_FIELD
UILabel *inputLengthView;
#endif
int inputTextLength;

int notchOffset;

int currentHotbarSlot = -1;
BOOL slideableHotbar;

// TODO: key modifiers impl

#pragma mark Class GameSurfaceView
@implementation GameSurfaceView
const void * _CGDataProviderGetBytePointerCallbackOSMESA(void *info) {
	return gbuffer;
}

- (void)displayLayer {
    CGDataProviderRef bitmapProvider = CGDataProviderCreateDirect(NULL, savedWidth * savedHeight * 4, &callbacks);
    CGImageRef bitmap = CGImageCreate(savedWidth, savedHeight, 8, 32, 4 * savedWidth, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder16Little, bitmapProvider, NULL, FALSE, kCGRenderingIntentDefault);     

    self.layer.contents = (__bridge id) bitmap;
    CGImageRelease(bitmap);
    CGDataProviderRelease(bitmapProvider);
   //  CGColorSpaceRelease(colorSpace);
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if ([getPreference(@"renderer") hasPrefix:@"libOSMesaOverride"]) {
        self.layer.opaque = YES;

        colorSpace = CGColorSpaceCreateDeviceRGB();

        callbacks.version = 0;
        callbacks.getBytePointer = _CGDataProviderGetBytePointerCallbackOSMESA;
        callbacks.releaseBytePointer = _CGDataProviderReleaseBytePointerCallback;
        callbacks.getBytesAtPosition = NULL;
        callbacks.releaseInfo = NULL;
    }

    return self;
}

+ (Class)layerClass {
    if ([getPreference(@"renderer") hasPrefix:@"libOSMesa"]) {
        return CALayer.class;
    } else {
        return CAMetalLayer.class;
    }
}

@end


#pragma mark Class TrackedTextField
@interface TrackedTextField : UITextField
@property int lastPosition;
@property UITextPosition* lockPos;
@end

@implementation TrackedTextField
- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    UITextPosition *position = [super closestPositionToPoint:point];
    int start = [self offsetFromPosition:self.beginningOfDocument toPosition:position];
    if (start - self.lastPosition != 0) {
        int key = (start - self.lastPosition > 0) ? GLFW_KEY_DPAD_RIGHT : GLFW_KEY_DPAD_LEFT;
        CallbackBridge_nativeSendKey(key, 0, 1, 0);
        CallbackBridge_nativeSendKey(key, 0, 0, 0);
    }
    self.lastPosition = start;
    return [self positionFromPosition:self.beginningOfDocument offset:clamp(start, 20, self.text.length - 20)];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.lockPos = [self positionFromPosition:self.beginningOfDocument offset:20];
    self.selectedTextRange = [self textRangeFromPosition:self.lockPos toPosition:self.lockPos];
}
@end


#pragma mark Class SurfaceViewController
@interface SurfaceViewController ()<UITextFieldDelegate, UIPointerInteractionDelegate, UIGestureRecognizerDelegate> {
}

@property TrackedTextField *inputView;
@property(nonatomic, strong) NSMutableDictionary* cc_dictionary;
@property(nonatomic, strong) NSMutableArray* swipeableButtons;
@property(nonatomic, strong) NSMutableArray* togglableVisibleButtons;
@property ControlButton* swipingButton;
@property UITouch *primaryTouch, *hotbarTouch;
@property id mouseConnectCallback, mouseDisconnectCallback;

@property CGRect clickRange;
@property BOOL shouldTriggerClick;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    isControlModifiable = NO;

    setPreference(@"internal_launch_on_boot", @(NO));
    isUseStackQueueCall = [getPreference(@"internal_useStackQueue") boolValue];
    setPreference(@"internal_useStackQueue", nil);

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    resolutionScale = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;
    slideableHotbar = [getPreference(@"slideable_hotbar") boolValue];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);

    savedWidth = roundf(width * screenScale);
    savedHeight = roundf(height * screenScale);

    self.surfaceView = [[GameSurfaceView alloc] initWithFrame:self.view.frame];
    self.surfaceView.multipleTouchEnabled = YES;
    self.surfaceView.layer.contentsScale = screenScale * resolutionScale;
    self.surfaceView.layer.magnificationFilter = self.surfaceView.layer.minificationFilter = kCAFilterNearest;
    [self.view addSubview:self.surfaceView];

    notchOffset = insets.left;
    width = width - notchOffset * 2;
    CGFloat buttonScale = [getPreference(@"button_scale") floatValue] / 100.0;

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
    longpressGesture.minimumPressDuration = [getPreference(@"time_longPressTrigger") floatValue] / 1000;
    [self.surfaceView addGestureRecognizer:longpressGesture];
    
    self.scrollPanGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnTouchesScroll:)];
    self.scrollPanGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.scrollPanGesture.delegate = self;
    self.scrollPanGesture.minimumNumberOfTouches = 2;
    self.scrollPanGesture.maximumNumberOfTouches = 2;

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
    [self.view addSubview:self.mousePointerView];

#ifndef DEBUG_VISIBLE_TEXT_FIELD
    self.inputView = [[TrackedTextField alloc] initWithFrame:CGRectMake(0, -1, 1, 1)];
#else
    self.inputView = [[TrackedTextField alloc] initWithFrame:CGRectMake(5 * 2 + 160.0, 5 * 2 + 30.0, 200.0, 30.0)];
    self.inputView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    self.inputView.font = [self.inputView.font fontWithSize:20];

    inputLengthView = [[UILabel alloc] initWithFrame:CGRectMake(5 * 2 + 80.0, 5 * 2 + 30.0, 80.0, 30.0)];
    inputLengthView.text = @"length=?";
    inputLengthView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.6f];
    [self.view addSubview:inputLengthView];
#endif
    self.inputView.delegate = self;
    self.inputView.lastPosition = 20;
    [self.inputView addTarget:self action:@selector(inputViewDidChange) forControlEvents:UIControlEventEditingChanged];

    NSString *controlFilePath = [NSString stringWithFormat:@"%s/%@", getenv("POJAV_PATH_CONTROL"), (NSString *)getPreference(@"default_ctrl")];

    NSError *cc_error;
    NSString *cc_data = [NSString stringWithContentsOfFile:controlFilePath encoding:NSUTF8StringEncoding error:&cc_error];

    self.swipeableButtons = [[NSMutableArray alloc] init];
    self.togglableVisibleButtons = [[NSMutableArray alloc] init];
    if (cc_error) {
        NSLog(@"Error: could not read %@: %@", controlFilePath, cc_error.localizedDescription);
        showDialog(self, @"Error", [NSString stringWithFormat:@"Could not read %@: %@", controlFilePath, cc_error.localizedDescription]);
    } else {
        NSData* cc_objc_data = [cc_data dataUsingEncoding:NSUTF8StringEncoding];
        self.cc_dictionary = [NSJSONSerialization JSONObjectWithData:cc_objc_data options:NSJSONReadingMutableContainers error:&cc_error];
        if (cc_error != nil) {
            showDialog(self, @"Error parsing JSON", cc_error.localizedDescription);
        } else {
            CGFloat currentScale = [self.cc_dictionary[@"scaledAt"] floatValue];
            CGFloat savedScale = [getPreference(@"button_scale") floatValue];
            loadControlObject(self.view, self.cc_dictionary, ^void(ControlButton* button) {
                BOOL isSwipeable = [button.properties[@"isSwipeable"] boolValue];

                BOOL isToggleCtrlBtn = NO;
                for (int i = 0; i < 4; i++) {
                    int keycodeInt = [button.properties[@"keycodes"][i] intValue];
                    if (keycodeInt == SPECIALBTN_TOGGLECTRL) {
                        isToggleCtrlBtn = YES;
                    }
                }

                [button addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown];
                [button addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];

                if (isSwipeable) {
                    UIPanGestureRecognizer *panRecognizerButton = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(executebtn_swipe:)];
                    panRecognizerButton.delegate = self;
                    [button addGestureRecognizer:panRecognizerButton];
                    [self.swipeableButtons addObject:button];
                }
                if (!isToggleCtrlBtn) {
                    [self.togglableVisibleButtons addObject:button];
                }
            });

            self.cc_dictionary[@"scaledAt"] = @(savedScale);
        }
    }

    [KeyboardInput initKeycodeTable];
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        self.mouseConnectCallback = [[NSNotificationCenter defaultCenter] addObserverForName:GCMouseDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Input: Mouse connected!");
            GCMouse* mouse = note.object;
            [self registerMouseCallbacks: mouse];
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

    [self.view addSubview:self.inputView];

    [self executebtn_special_togglebtn:0];

    // [self setPreferredFramesPerSecond:1000];

    callback_SurfaceViewController_launchMinecraft(savedWidth * resolutionScale, savedHeight * resolutionScale);
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
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
                virtualMouseFrame.origin.x += location.x - lastVirtualMousePoint.x;
                virtualMouseFrame.origin.y += location.y - lastVirtualMousePoint.y;
            } else if (event == ACTION_MOVE_MOTION) {
                event = ACTION_MOVE;
                virtualMouseFrame.origin.x += location.x;
                virtualMouseFrame.origin.y += location.y;
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
    CGPoint locationInView = [touchEvent locationInView:self.view];

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
            self.inputView.text = INPUT_SPACE_CHAR;
            inputTextLength = 0;

            CallbackBridge_nativeSendMouseButton(
                isGrabbing == JNI_TRUE ? GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 1, 0);
            CallbackBridge_nativeSendMouseButton(
                isGrabbing == JNI_TRUE ? GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 0, 0);
        } else {
            CallbackBridge_nativeSendKey(currentHotbarSlot, 0, 1, 0);
            CallbackBridge_nativeSendKey(currentHotbarSlot, 0, 0, 0);
        }
    }
}

- (void)surfaceOnDoubleClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized && isGrabbing) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint point = [sender locationInView:self.view];
        int hotbarSlot = callback_SurfaceViewController_touchHotbar(point.x * screenScale * resolutionScale, point.y * screenScale * resolutionScale);
        if (hotbarSlot != -1 && currentHotbarSlot == hotbarSlot) {
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 1, 0);
            CallbackBridge_nativeSendKey(GLFW_KEY_F, 0, 0, 0);
        }
    }
}

- (void)surfaceOnHover:(UIHoverGestureRecognizer *)sender API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 13.0, *)) {
        if (isGrabbing && @available(iOS 14.0, *)) {
            return;
        }
        CGPoint point = [sender locationInView:self.view];
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
}

-(void)surfaceOnLongpress:(UILongPressGestureRecognizer *)sender
{
    if (!slideableHotbar) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:self.view];
        currentHotbarSlot = callback_SurfaceViewController_touchHotbar(location.x * screenScale * resolutionScale, location.y * screenScale * resolutionScale);
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.shouldTriggerClick = NO;
        if (currentHotbarSlot == -1) {
            self.inputView.text = INPUT_SPACE_CHAR;
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
                self.inputView.text = INPUT_SPACE_CHAR;
                inputTextLength = 0;

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
        CGPoint velocity = [sender velocityInView:self.view];
        if (velocity.x != 0.0f || velocity.y != 0.0f) {
            CallbackBridge_nativeSendScroll((CGFloat) (velocity.x/10.0), (CGFloat) (velocity.y/10.0));
        }
    }
}

// FIXME: incomplete
- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)){
    NSLog(@"regionForRequest called");
    return nil;
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region  API_AVAILABLE(ios(13.4)){
    NSLog(@"styleForRegion called");
    return [UIPointerStyle hiddenPointerStyle];
}

#pragma mark - Input view stuff

NSString* inputStringBefore;
int inputStringLength = INPUT_FULL_LENGTH;
-(void)inputViewDidChange {
    int typedLength = (int)self.inputView.text.length - inputStringLength;
    if (typedLength < 0) {
        for (int i = 0; i < -typedLength; i++) {
            if (self.inputView.text.length < INPUT_FULL_LENGTH) {
                self.inputView.text = [@" " stringByAppendingString:self.inputView.text];
            }
            CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 1, 0);
            CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 0, 0);
            if (inputTextLength > 0) {
                --inputTextLength;
            }
        }

#ifdef DEBUG_VISIBLE_TEXT_FIELD
        inputLengthView.text = [@"length=" stringByAppendingFormat:@"%i", 
            inputTextLength];
#endif
    } else if (typedLength > 0) {
        int index = [self.inputView offsetFromPosition:self.inputView.beginningOfDocument toPosition:self.inputView.selectedTextRange.start];
        NSString *newText = [self.inputView.text substringWithRange:NSMakeRange(index - typedLength, typedLength)];
        int charLength = (int) [newText length];
        for (int i = 0; i < charLength; i++) {
            // Directly convert unichar to jchar since both are in UTF-16 encoding.

            jchar theChar = (jchar) [newText characterAtIndex:i];
            if (isUseStackQueueCall) {
                CallbackBridge_nativeSendCharMods(theChar, /* mods */ 0);
            } else {
                CallbackBridge_nativeSendChar(theChar);
            }

            ++inputTextLength;
#ifdef DEBUG_VISIBLE_TEXT_FIELD
            inputLengthView.text = [@"length=" stringByAppendingFormat:@"%i", 
            inputTextLength];
#endif
        }
        inputStringBefore = self.inputView.text;
        // [self.inputView.text substringFromIndex:inputTextLength - 1];
    } else {
#ifdef DEBUG_VISIBLE_TEXT_FIELD
        NSLog(@"Compare \"%@\" vs \"%@\"", self.inputView.text, inputStringBefore);
#endif
        for (int i = 0; i < INPUT_FULL_LENGTH; i++) {
            if ([self.inputView.text characterAtIndex:i] != [inputStringBefore characterAtIndex:i]) {
                NSString *inputStringNow = [self.inputView.text substringFromIndex:i];
/*
                self.inputView.text = [self.inputView.text substringToIndex:i];
                // self notify
                [self inputViewDidChange];
                
                self.inputView.text = [self.inputView.text stringByAppendingString:inputStringNow];
                // self notify
                [self inputViewDidChange];
*/
                
                for (int i2 = 0; i2 < [inputStringNow length]; i2++) {
                    CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 1, 0);
                    CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 0, 0);
                }
                
                for (int i2 = 0; i2 < [inputStringNow length]; i2++) {
                    CallbackBridge_nativeSendCharMods((jchar) [inputStringNow characterAtIndex:i2], /* mods */ 0);
                }

                break;
            }
        }

#ifdef DEBUG_VISIBLE_TEXT_FIELD
        inputLengthView.text = @"length =";
#endif
        inputStringBefore = self.inputView.text;
    }

    inputStringLength = (int)self.inputView.text.length;

    // Reset to default value
    // self.inputView.text = INPUT_SPACE_CHAR;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    CallbackBridge_nativeSendKey(GLFW_KEY_ENTER, 0, 1, 0);
    CallbackBridge_nativeSendKey(GLFW_KEY_ENTER, 0, 0, 0);
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
                            self.inputView.text = @"";
                        } else {
                            [self.inputView becomeFirstResponder];
                            // Empty the input field so that user will no longer able to select text inside.
                            self.inputView.text = INPUT_SPACE_CHAR;
                            inputStringLength = INPUT_FULL_LENGTH;
                            
#ifndef DEBUG_VISIBLE_TEXT_FIELD
                            self.inputView.alpha = 0.0f;
#endif
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

                case SPECIALBTN_VIRTUALMOUSE:
                    if (!isGrabbing && !held) {
                        virtualMouseEnabled = !virtualMouseEnabled;
                        self.mousePointerView.hidden = !virtualMouseEnabled;
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
    [self executebtn:sender withAction:ACTION_DOWN];
    if ([self.swipeableButtons containsObject:sender]) {
        self.swipingButton = sender;
    }
}

- (void)executebtn_swipe:(UIPanGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self.view];
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded) {
        [self executebtn_up:self.swipingButton];
        return;
    }
    for (ControlButton *button in self.swipeableButtons) {
        if (CGRectContainsPoint(button.frame, location) && (ControlButton *)self.swipingButton != button) {
            [self executebtn:self.swipingButton withAction:ACTION_UP];
            self.swipingButton = (ControlButton *)button;
            [self executebtn:self.swipingButton withAction:ACTION_DOWN];
            break;
        }
    }
}

- (void)executebtn_up:(ControlButton *)sender
{
    if (self.swipingButton == sender) {
        [self executebtn:self.swipingButton withAction:ACTION_UP];
        self.swipingButton = nil;
    } else {
        [self executebtn:sender withAction:ACTION_UP];
    }
}

- (void)executebtn_special_togglebtn:(int)held {
    if (held == 0) {
        currentVisibility = !currentVisibility;
        for (ControlButton *button in self.togglableVisibleButtons) {
            if (!currentVisibility && ![button isKindOfClass:[ControlSubButton class]]) {
                button.hidden = currentVisibility;
                if ([button isKindOfClass:[ControlDrawer class]]) {
                    [(ControlDrawer *)button restoreButtonVisibility];
                }
            } else if (currentVisibility) {
                button.hidden = currentVisibility;
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
        CGPoint locationInView = [touch locationInView:self.view];
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

@end
