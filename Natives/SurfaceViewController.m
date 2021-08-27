#import "LauncherPreferences.h"
#import "SurfaceViewController.h"
#import "egl_bridge.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/ControlButton.h"
#import "customcontrols/CustomControlsUtils.h"

#include "glfw_keycodes.h"
#include "utils.h"

#include "EGL/egl.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"


// Debugging purposes
// #define DEBUG_VISIBLE_TEXT_FIELD

#define APPLY_SCALE(KEY) \
  KEY = @([(NSNumber *)KEY floatValue] * savedScale / currentScale);

#define INPUT_SPACE_CHAR @"                    "
#define INPUT_SPACE_LENGTH 20

#ifdef DEBUG_VISIBLE_TEXT_FIELD
UILabel *inputLengthView;
#endif
UITextField *inputView;
int inputTextLength;

BOOL shouldTriggerClick = NO;
int notchOffset;

// TODO: key modifiers impl

@implementation GameSurfaceView
- (id)initWithFrame:(CGRect)frame {
    return self = [super initWithFrame:frame];
}

+ (Class)layerClass {
    return MGLLayer.class;
}
@end

@interface SurfaceViewController ()<UITextFieldDelegate, UIPointerInteractionDelegate, UIGestureRecognizerDelegate> {
}

@property(nonatomic, strong) UIView* surfaceView;
@property(nonatomic, strong) NSMutableDictionary* cc_dictionary;
@property(nonatomic, strong) NSMutableArray* swipeableButtons;
@property(nonatomic, strong) NSMutableArray* togglableVisibleButtons;
@property ControlButton* swipingButton;

- (void)setupGL;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    resolutionScale = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);

    savedWidth = roundf(width * screenScale);
    savedHeight = roundf(height * screenScale);

    NSLog(@"Debug: Creating surfaceView");
    self.surfaceView = [[GameSurfaceView alloc] initWithFrame:self.view.frame];
    NSLog(@"Debug: surfaceView=%@", self.surfaceView);
    self.surfaceView.layer.contentsScale = screenScale * resolutionScale;
    [self.view addSubview:self.surfaceView];

    // Enable support for desktop GLSL
    if ([getPreference(@"disable_gl4es_shaderconv") boolValue]) {
        setenv("LIBGL_NOSHADERCONV", "1", 1);
        eglBindAPI(EGL_OPENGL_API);
        NSLog(@"eglBindAPI(EGL_OPENGL_API) error=%x", eglGetError());
    }

    notchOffset = insets.left;
    width = width - notchOffset * 2;
    CGFloat buttonScale = ((NSNumber *) getPreference(@"button_scale")).floatValue / 100.0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [self.surfaceView addGestureRecognizer:tapGesture];

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnLongpress:)];
    longpressGesture.delegate = self;
    longpressGesture.minimumPressDuration = ((NSNumber *)getPreference(@"time_longPressTrigger")).floatValue / 1000;
    [self.surfaceView addGestureRecognizer:longpressGesture];
    
    UIPanGestureRecognizer *scrollPanGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnTouchesScroll:)];
    scrollPanGesture.delegate = self;
    scrollPanGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    scrollPanGesture.minimumNumberOfTouches = 2;
    scrollPanGesture.maximumNumberOfTouches = 2;
    [self.surfaceView addGestureRecognizer:scrollPanGesture];

    if (@available(iOS 13.4, *)) {
        [self.surfaceView addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];

        UIPanGestureRecognizer *mouseWheelGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(surfaceOnMouseScroll:)];
        mouseWheelGesture.delegate = self;
        mouseWheelGesture.allowedScrollTypesMask = UIScrollTypeMaskDiscrete;
        mouseWheelGesture.allowedTouchTypes = @[@(UITouchTypeIndirectPointer)];
        mouseWheelGesture.cancelsTouchesInView = NO;
        mouseWheelGesture.delaysTouchesBegan = NO;
        mouseWheelGesture.delaysTouchesEnded = NO;
        [self.surfaceView addGestureRecognizer:mouseWheelGesture];
    }

#ifndef DEBUG_VISIBLE_TEXT_FIELD
    inputView = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    inputView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
#else
    inputView = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    inputView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];

    inputLengthView = [[UILabel alloc] initWithFrame:CGRectMake(5 * 2 + rectBtnWidth, 5 * 2 + rectBtnHeight, rectBtnWidth, rectBtnHeight)];
    inputLengthView.text = @"length=?";
    inputLengthView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.6f];
    [self.view addSubview:inputLengthView];
#endif
    inputView.delegate = self;
    [inputView addTarget:self action:@selector(inputViewDidChange) forControlEvents:UIControlEventEditingChanged];
    [inputView addTarget:self action:@selector(inputViewDidClick) forControlEvents:UIControlEventTouchDown];

    // Custom button
    // ADD_BUTTON(@"F1", f1, CGRectMake(5, 5, width, height));

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
            convertV1ToV2(self.cc_dictionary);
            NSMutableArray *cc_controlDataList = self.cc_dictionary[@"mControlDataList"];
            CGFloat currentScale = [self.cc_dictionary[@"scaledAt"] floatValue];
            CGFloat savedScale = [getPreference(@"button_scale") floatValue];
            int cc_version = [self.cc_dictionary[@"version"] intValue];
            for (NSMutableDictionary *cc_buttonDict in cc_controlDataList) {
                BOOL isSwipeable = [cc_buttonDict[@"isSwipeable"] boolValue];
                APPLY_SCALE(cc_buttonDict[@"width"]);
                APPLY_SCALE(cc_buttonDict[@"height"]);
                APPLY_SCALE(cc_buttonDict[@"strokeWidth"]);

                ControlButton *button = [ControlButton initWithProperties:cc_buttonDict];
                [button addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown];
                [button addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
                [self.view addSubview:button];

                BOOL isToggleCtrlBtn = NO;
                for (int i = 0; i < 4; i++) {
                    int keycodeInt = ((NSNumber *)cc_buttonDict[@"keycodes"][i]).intValue;
                    if (keycodeInt == SPECIALBTN_KEYBOARD) {
                        inputView.frame = button.frame;
                    }
                    if (keycodeInt == SPECIALBTN_TOGGLECTRL) {
                        isToggleCtrlBtn = YES;
                    }
                }
                if (isSwipeable) {
                    UIPanGestureRecognizer *panRecognizerButton = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(executebtn_swipe:)];
                    panRecognizerButton.delegate = self;
                    [button addGestureRecognizer:panRecognizerButton];
                    [self.swipeableButtons addObject:button];
                }
                if (!isToggleCtrlBtn) {
                    [self.togglableVisibleButtons addObject:button];
                }
            }
            self.cc_dictionary[@"scaledAt"] = @(savedScale);
        }
    }

    [self.view addSubview:inputView];

    [self executebtn_special_togglebtn:0];

    ((MGLLayer *)self.surfaceView.layer).drawableDepthFormat = MGLDrawableDepthFormat24;
    // [self setPreferredFramesPerSecond:1000];

    // Init GLES
    sharegroup = [[MGLSharegroup alloc] init];
    firstContext = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES3 sharegroup:sharegroup];
    if (!firstContext) {
        NSLog(@"Failed to create ES context");
    }

    [MGLContext setCurrentContext:firstContext forLayer:(MGLLayer *)self.surfaceView.layer];

    [self setupGL];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

#pragma mark - MetalANGLE stuff

- (void)dealloc
{
    [MGLContext setCurrentContext:nil];
}

- (void)setupGL
{
    callback_SurfaceViewController_launchMinecraft(savedWidth * resolutionScale, savedHeight * resolutionScale);
}

#pragma mark - Input: send touch utilities

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
    if (!isGrabbing) {
        screenScale *= resolutionScale;
    }
    callback_SurfaceViewController_onTouch(event, location.x * screenScale, location.y * screenScale);
}

- (void)sendTouchEvent:(NSSet *)touches withUIEvent:(UIEvent *)uievent withEvent:(int)event
{
    UITouch* touchEvent = [touches anyObject];
    CGPoint locationInView = [touchEvent locationInView:self.view];

    BOOL isTouchTypeIndirect = NO;
    if (@available(iOS 13.4, *)) {
        if (touchEvent.type == UITouchTypeIndirectPointer) {
            isTouchTypeIndirect = YES;
        }
    }

    if (touchEvent.view == self.surfaceView) {
        [self sendTouchPoint:locationInView withEvent:event];

        if (!isTouchTypeIndirect) {
            switch (event) {
                case ACTION_DOWN:
                    touchesMovedCount = 0;
                    shouldTriggerClick = YES;
                    break;

                case ACTION_MOVE:
                    // TODO: better handling this
                    if (touchesMovedCount >= 1) {
                        shouldTriggerClick = NO;
                    } else ++touchesMovedCount;
                    break;
            }
        } else if (@available(iOS 13.4, *)) {
            // Recheck @available for suppressing compile warnings

            // Mouse clicks are handled here
            int held = event == ACTION_MOVE || event == ACTION_UP;
            shouldTriggerClick = NO;
            for (int i = 1; i <= 5; ++i) {
                if ((uievent.buttonMask & (1 << ((i)-1))) != 0) {
                    // iOS button index = GLFW button index + 1;
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, i - 1, held, 0);
                }
            }
        }
    }
}

#pragma mark - Input: on-surface gestures

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized &&
      shouldTriggerClick == YES) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:[sender.view superview]];
        int hotbarItem = callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
        
        if (hotbarItem == -1) {
            inputView.text = INPUT_SPACE_CHAR;
            inputTextLength = 0;

            Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL,
                isGrabbing == JNI_TRUE ? GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 1, 0);
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL,
                isGrabbing == JNI_TRUE ? GLFW_MOUSE_BUTTON_RIGHT : GLFW_MOUSE_BUTTON_LEFT, 0, 0);
        } else {
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, hotbarItem, 0, 1, 0);
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, hotbarItem, 0, 0, 0);
        }
    }
}

- (void)surfaceOnHover:(UIHoverGestureRecognizer *)sender API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 13.0, *)) {
        CGPoint point = [sender locationInView:self.surfaceView];
        // NSLog(@"Mouse move!!");
        // NSLog(@"Mouse pos = %d, %d", point.x, point.y);
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
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGPoint location = [sender locationInView:[sender.view superview]];
    int hotbarItem = callback_SurfaceViewController_touchHotbar(location.x * screenScale * resolutionScale, location.y * screenScale * resolutionScale);
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (hotbarItem == -1) {
            inputView.text = INPUT_SPACE_CHAR;
            inputTextLength = 0;

            Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_LEFT, 1, 0);
        } else {
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_Q, 0, 1, 0);
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (hotbarItem == -1) {
            [self sendTouchPoint:location withEvent:ACTION_MOVE];
        }
    } else {
        if (sender.state == UIGestureRecognizerStateCancelled
            || sender.state == UIGestureRecognizerStateFailed
            || sender.state == UIGestureRecognizerStateEnded)
        {
            if (hotbarItem == -1) {
                inputView.text = INPUT_SPACE_CHAR;
                inputTextLength = 0;

                Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_LEFT, 0, 0);
            } else {
                Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_Q, 0, 0, 0);
            }
        }
    }
}

-(void)surfaceOnMouseScroll:(UIPanGestureRecognizer *)sender API_AVAILABLE(ios(13.4))
{
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged ||
        sender.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [sender velocityInView:self.view];

        if (velocity.x > 0.0f) {
            velocity.x = -1.0;
        } else if (velocity.x < 0.0f) {
            velocity.x = 1.0f;
        }
        if (velocity.y > 0.0f) {
            velocity.y = -1.0;
        } else if (velocity.y < 0.0f) {
            velocity.y = 1.0f;
        }
        if (velocity.x != 0.0f || velocity.y != 0.0f) {
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendScroll(NULL, NULL, (jdouble) velocity.x * 4.0, (jdouble) velocity.y * 4.0);
        }
    }
}

- (void)surfaceOnTouchesScroll:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged ||
        sender.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [sender velocityInView:self.view];
        if (velocity.x != 0.0f || velocity.y != 0.0f) {
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendScroll(NULL, NULL, (jdouble) (velocity.x/10.0), (jdouble) (velocity.y/10.0));
        }
    }
}

- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)){
    if (request != nil) {
        CGPoint origin = self.surfaceView.bounds.origin;
        CGPoint point = request.location;

        point.x -= origin.x;
        point.y -= origin.y;
        
        NSLog(@"UIPointerInteraction pos changed: x=%d, y=%d", (int) point.x, (int) point.y);

        // TODO FIXME
        callback_SurfaceViewController_onTouch(ACTION_DOWN, (int)point.x, (int)point.y);
    }
    return [UIPointerRegion regionWithRect:self.surfaceView.bounds identifier:nil];
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region  API_AVAILABLE(ios(13.4)){
    if (isGrabbing == JNI_FALSE) {
        return nil;
    } else {
        return [UIPointerStyle hiddenPointerStyle];
    }
}

#pragma mark - Input view stuff

NSString* inputStringBefore;
-(void)inputViewDidChange {
    if ([inputView.text length] < INPUT_SPACE_LENGTH) {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 1, 0);
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 0, 0);
        inputView.text = [@" " stringByAppendingString:inputView.text];

        if (inputTextLength > 0) {
            --inputTextLength;
        }

#ifdef DEBUG_VISIBLE_TEXT_FIELD
            inputLengthView.text = [@"length=" stringByAppendingFormat:@"%i", 
            inputTextLength];
#endif
    } else if ([inputView.text length] > INPUT_SPACE_LENGTH) {
        NSString *newText = [inputView.text substringFromIndex:INPUT_SPACE_LENGTH];
        int charLength = (int) [newText length];
        for (int i = 0; i < charLength; i++) {
            // Directly convert unichar to jchar since both are in UTF-16 encoding.

/*
            jchar theChar = (jchar) 
        (isUseStackQueueCall ?
                [newText UTF8String][i] : [newText characterAtIndex:i]);
*/

            jchar theChar = (jchar) [newText characterAtIndex:i];
            if (isUseStackQueueCall) {
                Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(NULL, NULL, theChar, /* mods */ 0);
            } else {
                Java_org_lwjgl_glfw_CallbackBridge_nativeSendChar(NULL, NULL, theChar);
            }

            inputView.text = [inputView.text substringFromIndex:1];
            if (inputTextLength < INPUT_SPACE_LENGTH) {
                ++inputTextLength;
            }
#ifdef DEBUG_VISIBLE_TEXT_FIELD
            inputLengthView.text = [@"length=" stringByAppendingFormat:@"%i", 
            inputTextLength];
#endif
        }
        inputStringBefore = inputView.text;
        // [inputView.text substringFromIndex:inputTextLength - 1];
    } else {
#ifdef DEBUG_VISIBLE_TEXT_FIELD
        NSLog(@"Compare \"%@\" vs \"%@\"", inputView.text, inputStringBefore);
#endif
        for (int i = 0; i < INPUT_SPACE_LENGTH; i++) {
            if ([inputView.text characterAtIndex:i] != [inputStringBefore characterAtIndex:i]) {
                NSString *inputStringNow = [inputView.text substringFromIndex:i];
/*
                inputView.text = [inputView.text substringToIndex:i];
                // self notify
                [self inputViewDidChange];
                
                inputView.text = [inputView.text stringByAppendingString:inputStringNow];
                // self notify
                [self inputViewDidChange];
*/
                
                for (int i2 = 0; i2 < [inputStringNow length]; i2++) {
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 1, 0);
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 0, 0);
                }
                
                for (int i2 = 0; i2 < [inputStringNow length]; i2++) {
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(NULL, NULL, (jchar) [inputStringNow characterAtIndex:i2], /* mods */ 0);
                }

                break;
            }
        }

#ifdef DEBUG_VISIBLE_TEXT_FIELD
        inputLengthView.text = @"length =";
#endif
        inputStringBefore = inputView.text;
        // [inputView.text substringFromIndex:inputTextLength - 1];
    }

    // Reset to default value
    // inputView.text = INPUT_SPACE_CHAR;
}

-(void)inputViewDidClick {
    // Zero the input field so user will no longer able to select text inside.
#ifndef DEBUG_VISIBLE_TEXT_FIELD
    inputView.alpha = 0.0f;
#endif
    inputView.text = INPUT_SPACE_CHAR;
    inputTextLength = 0;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_ENTER, 0, 1, 0);
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_ENTER, 0, 0, 0);
    return YES;
}

#pragma mark - On-screen button functions

int currentVisibility = 1;
- (void)executebtn:(UIButton *)sender withAction:(int)action {
    ControlButton *button = (ControlButton *)sender;
    int held = action == ACTION_DOWN;
    // TODO v2: mulitple keys support
    for (int i = 0; i < 4; i++) {
        int keycode = ((NSNumber *)button.properties[@"keycodes"][i]).intValue;
        if (keycode < 0) {
            switch (keycode) {
                case SPECIALBTN_KEYBOARD:
                    if (held == 0) {
                        [inputView resignFirstResponder];
                        inputView.alpha = 1.0f;
                        inputView.text = @"";
                    }
                    break;

                case SPECIALBTN_MOUSEPRI:
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_LEFT, held, 0);
                    break;

                case SPECIALBTN_MOUSESEC:
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_RIGHT, held, 0);
                    break;

                case SPECIALBTN_MOUSEMID:
                    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_MIDDLE, held, 0);
                    break;

                case SPECIALBTN_TOGGLECTRL:
                    [self executebtn_special_togglebtn:held];
                    break;

                case SPECIALBTN_VIRTUALMOUSE:
                case SPECIALBTN_SCROLLUP:
                case SPECIALBTN_SCROLLDOWN:
                    NSLog(@"Warning: button %@ sent unimplemented special keycode: %d", button.titleLabel.text, keycode);
                    break;

                default:
                    NSLog(@"Warning: button %@ sent unknown special keycode: %d", button.titleLabel.text, keycode);
                    break;
            }
        } else {
            // there's no key id 0, but we accidentally used -1 as a special key id, so we had to do that
            // if (keycode == 0) { keycode = -1; }
            // at the moment, send unknown keycode does nothing, may even cause performance issue, so ignore it
            if (keycode == 0) continue;
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, keycode, 0, held, 0);
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
        [self executebtn_up:nil];
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
    if (self.swipingButton) {
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
            button.hidden = currentVisibility;
        }

#ifndef DEBUG_VISIBLE_TEXT_FIELD
        inputView.hidden = currentVisibility;
#endif
    }
}

#pragma mark - Input: On-screen touch events

int touchesMovedCount;
// Equals to Android ACTION_DOWN
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self sendTouchEvent:touches withUIEvent:event withEvent:ACTION_DOWN];
}

// Equals to Android ACTION_MOVE
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self sendTouchEvent:touches withUIEvent:event withEvent:ACTION_MOVE];
}

// Equals to Android ACTION_UP
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self sendTouchEvent:touches withUIEvent:event withEvent:ACTION_UP];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self sendTouchEvent:touches withUIEvent:event withEvent:ACTION_UP];
}

@end
