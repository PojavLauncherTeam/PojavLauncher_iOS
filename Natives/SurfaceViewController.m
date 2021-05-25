#import "SurfaceViewController.h"
#import "egl_bridge_ios.h"
#import "ios_uikit_bridge.h"

#import "customcontrols/ControlButton.h"

#include "glfw_keycodes.h"
#include "utils.h"

#include "EGL/egl.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"

#define SPECIALBTN_KEYBOARD -1
#define SPECIALBTN_TOGGLECTRL -2
#define SPECIALBTN_MOUSEPRI -3
#define SPECIALBTN_MOUSESEC -4
#define SPECIALBTN_VIRTUALMOUSE -5
#define SPECIALBTN_MOUSEMID -6
#define SPECIALBTN_SCROLLUP -7
#define SPECIALBTN_SCROLLDOWN -8


// Debugging purposes
// #define DEBUG_VISIBLE_TEXT_FIELD

#define ADD_BUTTON(NAME, KEY, RECT, VISIBLE) \
    ControlButton *button_##KEY = [ControlButton initWithName:NAME keycode:KEY rect:CGRectOffset(RECT, notchOffset, 0) transparency:0.0f]; \
    [button_##KEY addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown]; \
    [button_##KEY addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpInside]; \
    [button_##KEY addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpOutside]; \
    [self.view addSubview:button_##KEY]; \
    if (VISIBLE == YES) { \
        togglableVisibleButtons[++togglableVisibleButtonIndex] = button_##KEY; \
    }

#define INPUT_SPACE_CHAR @"                    "
#define INPUT_SPACE_LENGTH 20

int togglableVisibleButtonIndex = -1;
ControlButton* togglableVisibleButtons[100];

UIView *touchView;
#ifdef DEBUG_VISIBLE_TEXT_FIELD
UILabel *inputLengthView;
#endif
UITextField *inputView;
int inputTextLength;

BOOL shouldTriggerClick = NO;
int notchOffset;

// TODO: key modifiers impl

@interface SurfaceViewController ()<UITextFieldDelegate, UIPointerInteractionDelegate> {
}

@property (strong, nonatomic) MGLContext *context;

- (void)setupGL;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    
    savedWidth = roundf(width * screenScale);
    savedHeight = roundf(height * screenScale);

    // get both left and right for just in case orientation is changed
    notchOffset = insets.left + insets.right;
    width = width - notchOffset * 2;
    
    touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [touchView addGestureRecognizer:tapGesture];

    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(surfaceOnLongpress:)];
    longpressGesture.minimumPressDuration = 0.4;
    [touchView addGestureRecognizer:longpressGesture];

    [self.view addSubview:touchView];
    
    if (@available(iOS 13.4, *)) {
        [touchView addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];

        UIPanGestureRecognizer *mouseWheelGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(surfaceOnMouseScroll:)];
        mouseWheelGesture.allowedScrollTypesMask = UIScrollTypeMaskDiscrete;
        mouseWheelGesture.allowedTouchTypes = @[ @(UITouchTypeIndirectPointer) ];
        mouseWheelGesture.cancelsTouchesInView = NO;
        mouseWheelGesture.delaysTouchesBegan = NO;
        mouseWheelGesture.delaysTouchesEnded = NO;
        [touchView addGestureRecognizer:mouseWheelGesture];
    }

    CGFloat rectBtnWidth = 80.0;
    CGFloat rectBtnHeight = 30.0;
    CGFloat squareBtnSize = 50.0;

#ifndef DEBUG_VISIBLE_TEXT_FIELD
    inputView = [[UITextField alloc] initWithFrame:CGRectMake(5 * 3 + rectBtnWidth * 2, 5, rectBtnWidth, rectBtnHeight)];
    inputView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
#else
    inputView = [[UITextField alloc] initWithFrame:CGRectMake(5 * 3 + rectBtnWidth * 2, 5 * 2 + rectBtnHeight, 200, rectBtnHeight)];
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

    // Temporary fallback controls
    BOOL cc_fallback = YES;
    
    FILE *cc_file = fopen("/var/mobile/Documents/.pojavlauncher/controlmap/default.json", "r");

    // 100kb (might not safe)
    char cc_data[102400];
    long cc_size;
    if (cc_file) {
        fseek(cc_file, 0L, SEEK_END);
        cc_size = ftell(cc_file);
        rewind(cc_file);
    }

    NSError *cc_error;
    if (cc_size > 102400) {
        NSLog(@"Error: control data is too big (over 100kb).");
        fclose(cc_file);
    } else if (!cc_file || !fread(cc_data, cc_size, 1, cc_file)) {
        NSLog(@"Error: could not read \"default.json\", falling back to default control, error: %s", strerror(errno));
        fclose(cc_file);
    } else {
        fclose(cc_file);
        NSData* cc_objc_data = [@(cc_data) dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *cc_dictionary = [NSJSONSerialization JSONObjectWithData:cc_objc_data options:kNilOptions error:&cc_error];
        if (cc_error != nil) {
            showDialog(self, @"Error parsing JSON", cc_error.localizedDescription);
        } else {
            NSArray *cc_controlDataList = (NSArray *) [cc_dictionary valueForKey:@"mControlDataList"];
            for (int i = 0; i < (int) cc_controlDataList.count; i++) {
                ControlButton *button = [ControlButton initWithProperties:(NSMutableDictionary *)cc_controlDataList[i]];
                [button addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown];
                [button addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpInside];
                [button addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpOutside];
                [self.view addSubview:button];
                if ([(NSNumber *) [button.properties valueForKey:@"keycode"] intValue] != SPECIALBTN_TOGGLECTRL) {
                    togglableVisibleButtons[++togglableVisibleButtonIndex] = button;
                }
            }
            cc_fallback = NO;
        }
    }

    if (cc_fallback == YES) {
        ADD_BUTTON(@"GUI", SPECIALBTN_TOGGLECTRL, CGRectMake(5, height - 5 - 50, squareBtnSize, squareBtnSize), NO);
        ADD_BUTTON(@"Keyboard", SPECIALBTN_KEYBOARD, CGRectMake(5 * 3 + rectBtnWidth * 2, 5, rectBtnWidth, rectBtnHeight), YES);

        ADD_BUTTON(@"Pri", SPECIALBTN_MOUSEPRI, CGRectMake(5, height - 5 * 3 - 50 * 3, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"Sec", SPECIALBTN_MOUSESEC, CGRectMake(5 * 3 + 50 * 2, height - 5 * 3 - 50 * 3, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"Debug", GLFW_KEY_F3, CGRectMake(5, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Chat", GLFW_KEY_T, CGRectMake(5 * 2 + rectBtnWidth, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Tab", GLFW_KEY_TAB, CGRectMake(5 * 4 + rectBtnWidth * 3, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Opti-Zoom", GLFW_KEY_C, CGRectMake(5 * 5 + rectBtnWidth * 4, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"Offhand", GLFW_KEY_F, CGRectMake(5 * 6 + rectBtnWidth * 5, 5, rectBtnWidth, rectBtnHeight), YES);
        ADD_BUTTON(@"3rd", GLFW_KEY_F5, CGRectMake(5, 5 * 2 + rectBtnHeight, rectBtnWidth, rectBtnHeight), YES);

        ADD_BUTTON(@"▲", GLFW_KEY_W, CGRectMake(5 * 2 + 50, height - 5 * 3 - 50 * 3, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"◀", GLFW_KEY_A, CGRectMake(5, height - 5 * 2 - 50 * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"▼", GLFW_KEY_S, CGRectMake(5 * 2 + 50, height - 5 - 50, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"▶", GLFW_KEY_D, CGRectMake(5 * 3 + 50 * 2, height - 5 * 2 - 50 * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"◇", GLFW_KEY_LEFT_SHIFT, CGRectMake(5 * 2 + 50, height - 5 * 2 - 50 * 2, squareBtnSize, squareBtnSize), YES);
        ADD_BUTTON(@"Inv", GLFW_KEY_E, CGRectMake(5 * 3 + 50 * 2, height - 5 - 50, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"⬛", GLFW_KEY_SPACE, CGRectMake(width - 5 * 2 - 50 * 2, height - 5 * 2 - 50 * 2, squareBtnSize, squareBtnSize), YES);

        ADD_BUTTON(@"Esc", GLFW_KEY_ESCAPE, CGRectMake(width - 5 - rectBtnWidth, height - 5 - rectBtnHeight, rectBtnWidth, rectBtnHeight), YES);

        // ADD_BUTTON(@"Fullscreen", f11, CGRectMake(width - 5 - rectBtnWidth, 5, rectBtnWidth, rectBtnHeight), YES);
    }
    
    [self.view addSubview:inputView];

    [self executebtn_special_togglebtn:0];

    viewController = self;

    MGLKView *view = glView = (MGLKView *) self.view;
    view.drawableDepthFormat = MGLDrawableDepthFormat24;
    view.enableSetNeedsDisplay = YES;
    // [self setPreferredFramesPerSecond:1000];

    // Init GLES
    self.context = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES3];

    if (!self.context) {
        self.context = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES2];
    }

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.context = self.context;
#ifndef USE_EGL
    glContext = self.context;
#endif

    [MGLContext setCurrentContext:self.context];

    [self setupGL];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

#pragma mark - MetalANGLE stuff

- (void)dealloc
{
    if ([MGLContext currentContext] == self.context) {
        [MGLContext setCurrentContext:nil];
    }
}

- (void)setupGL
{
    [MGLContext setCurrentContext:self.context];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width * screenScale);
    int height = (int) roundf(screenBounds.size.height * screenScale);
    callback_SurfaceViewController_launchMinecraft(width, height);
}

BOOL isNotifRemoved;
- (void)mglkView:(MGLKView *)view drawInRect:(CGRect)rect
{
    // glClearColor(0.6f, 0.6f, 0.6f, 1.0f);
    // glClear(GL_COLOR_BUFFER_BIT);
    // [self setNeedsDisplay]
    // NSLog(@"swapbuffer");

    // Remove notifications, so rendering will be manually controlled!
    if (isNotifRemoved == NO) {
        isNotifRemoved = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:self
        name:MGLKApplicationWillResignActiveNotification
        object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
        name:MGLKApplicationDidBecomeActiveNotification
        object:nil];
    }
        
    [super pause];

    // Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorPos(NULL, NULL, location.x * screenScale, location.y * screenScale);
}

#pragma mark - Input: send touch utilities

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    if (callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale) == -1) {
        callback_SurfaceViewController_onTouch(event, location.x * screenScale, location.y * screenScale);
    }
}

- (void)sendTouchEvent:(NSSet *)touches withUIEvent:(UIEvent *)uievent withEvent:(int)event
{
    UITouch* touchEvent = [touches anyObject];
    
    BOOL isTouchTypeIndirect = NO;
    if (@available(iOS 13.4, *)) {
        if (touchEvent.type == UITouchTypeIndirectPointer) {
            isTouchTypeIndirect = YES;
        }
    }

    if ([touchEvent view] == touchView) {
        CGPoint locationInView = [touchEvent locationInView:touchView];
        [self sendTouchPoint:locationInView withEvent:event];
    }

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
        // Recheck @available for fix compile warnings

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
        CGPoint point = [sender locationInView:touchView];
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
    int hotbarItem = callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
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
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendScroll(NULL, NULL, (jdouble) velocity.x, (jdouble) velocity.y);
        }
    }
}

- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)) API_AVAILABLE(ios(13.4)){
    if (request != nil) {
        CGPoint origin = touchView.bounds.origin;
        CGPoint point = request.location;

        point.x -= origin.x;
        point.y -= origin.y;
        
        NSLog(@"UIPointerInteraction pos changed: x=%d, y=%d", (int) point.x, (int) point.y);

        // TODO FIXME
        callback_SurfaceViewController_onTouch(ACTION_DOWN, (int)point.x, (int)point.y);
    }
    return [UIPointerRegion regionWithRect:touchView.bounds identifier:nil];
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
            // Directly convert unichar to jchar which both are in UTF-16 encoding.
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(NULL, NULL, (jchar) [newText characterAtIndex:i] /* charText[i] */, /* mods */ 0);
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
- (void) executebtn:(UIButton *)sender withAction:(int)action {
    ControlButton *button = (ControlButton *)sender;
    int held = action == ACTION_DOWN;
    int keycode = [(NSNumber *) [button.properties valueForKey:@"keycode"] intValue];
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
        }
    } else {
        Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, keycode, 0, held, 0);
    }
}

- (void) executebtn_down:(UIButton *)sender {
    [self executebtn:sender withAction:ACTION_DOWN];
}

- (void) executebtn_up:(UIButton *)sender {
    [self executebtn:sender withAction:ACTION_UP];
}

- (void) executebtn_special_togglebtn:(int)held {
    if (held == 0) {
        currentVisibility = !currentVisibility;
        for (int i = 0; i < togglableVisibleButtonIndex + 1; i++) {
            togglableVisibleButtons[i].hidden = currentVisibility;
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
    [super touchesBegan: touches withEvent: event];
    [self sendTouchEvent: touches withUIEvent: event withEvent: ACTION_DOWN];
}

// Equals to Android ACTION_MOVE
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved: touches withEvent: event];
    [self sendTouchEvent: touches withUIEvent: event withEvent: ACTION_MOVE];
}

// Equals to Android ACTION_UP
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded: touches withEvent: event];
    [self sendTouchEvent: touches withUIEvent: event withEvent: ACTION_UP];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled: touches withEvent: event];
    [self sendTouchEvent: touches withUIEvent: event withEvent: ACTION_UP];
}

@end
