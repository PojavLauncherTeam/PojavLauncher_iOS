#import "SurfaceViewController.h"
#import "egl_bridge_ios.h"
#import "ios_uikit_bridge.h"

#include "glfw_keycodes.h"
#include "utils.h"

#include "EGL/egl.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"

#define ADD_BUTTON(NAME, KEY, RECT) \
    UIButton *button_##KEY = [UIButton buttonWithType:UIButtonTypeRoundedRect]; \
    button_##KEY.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth; \
    [button_##KEY setTitle:NAME forState:UIControlStateNormal]; \
    button_##KEY.frame = CGRectOffset(RECT, notchOffset, 0); \
    [button_##KEY addTarget:self action:@selector(executebtn_##KEY##_down) forControlEvents:UIControlEventTouchDown]; \
    [button_##KEY addTarget:self action:@selector(executebtn_##KEY##_up) forControlEvents:UIControlEventTouchUpInside]; \
    button_##KEY.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f]; \
    button_##KEY.tintColor = [UIColor whiteColor]; \
    [self.view addSubview:button_##KEY];

#define ADD_BUTTON_VISIBLE(NAME, KEY, RECT) \
    ADD_BUTTON(NAME, KEY, RECT); \
    togglableVisibleButtons[++togglableVisibleButtonIndex] = button_##KEY;
    
    
#define ADD_BUTTON_DEF(KEY) \
    - (void)executebtn_##KEY##_down { \
        [self executebtn_##KEY:1]; \
    } \
    - (void)executebtn_##KEY##_up { \
        [self executebtn_##KEY:0]; \
    } \
    - (void)executebtn_##KEY:(int)held

#define ADD_BUTTON_DEF_KEY(KEY, KEYCODE) \
    ADD_BUTTON_DEF(KEY) { \
        Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, KEYCODE, 0, held, 0); \
    }

#define BTN_RECT 80.0, 30.0
#define BTN_SQUARE 50.0, 50.0

int togglableVisibleButtonIndex = -1;
UIButton* togglableVisibleButtons[100];
UIView *touchView;
UITextField *inputView;
BOOL shouldTriggerClick = NO;
int notchOffset;

// TODO: key modifiers impl

@interface SurfaceViewController ()<UITextFieldDelegate> {
}

@property (strong, nonatomic) MGLContext *context;

- (void)setupGL;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    UIEdgeInsets insets = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    
    savedWidth = roundf(width * screenScale);
    savedHeight = roundf(height * screenScale);

    width = width - insets.left - insets.right;
    height = height - insets.bottom;
    notchOffset = insets.left;
    
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
    
    inputView = [[UITextField alloc] initWithFrame:CGRectMake(5 * 3 + 80 * 2, 5, BTN_RECT)];
    inputView.delegate = self;
    inputView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
    [inputView addTarget:self action:@selector(inputViewDidChange) forControlEvents:UIControlEventEditingChanged];
    [inputView addTarget:self action:@selector(inputViewDidClick) forControlEvents:UIControlEventTouchDown];

    // Custom button
    // ADD_BUTTON(@"F1", f1, CGRectMake(5, 5, width, height));

    ADD_BUTTON(@"GUI", special_togglebtn, CGRectMake(5, height - 5 - 50, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Keyboard", special_keyboard, CGRectMake(5 * 3 + 80 * 2, 5, BTN_RECT));

    ADD_BUTTON_VISIBLE(@"Pri", special_mouse_pri, CGRectMake(5, height - 5 * 3 - 50 * 3, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Sec", special_mouse_sec, CGRectMake(5 * 3 + 50 * 2, height - 5 * 3 - 50 * 3, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"Debug", f3, CGRectMake(5, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Chat", t, CGRectMake(5 * 2 + 80, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Tab", tab, CGRectMake(5 * 4 + 80 * 3, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Opti-Zoom", c, CGRectMake(5 * 5 + 80 * 4, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Offhand", f, CGRectMake(5 * 6 + 80 * 5, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"3rd", f5, CGRectMake(5, 5 * 2 + 30.0, BTN_RECT));

    ADD_BUTTON_VISIBLE(@"▲", w, CGRectMake(5 * 2 + 50, height - 5 * 3 - 50 * 3, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"◀", a, CGRectMake(5, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"▼", s, CGRectMake(5 * 2 + 50, height - 5 - 50, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"▶", d, CGRectMake(5 * 3 + 50 * 2, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"◇", left_shift, CGRectMake(5 * 2 + 50, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Inv", e, CGRectMake(5 * 3 + 50 * 2, height - 5 - 50, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"⬛", space, CGRectMake(width - 5 * 2 - 50 * 2, height - 5 * 2 - 50 * 2, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"Esc", escape, CGRectMake(width - 5 - 80, height - 5 - 30, BTN_RECT));

    // ADD_BUTTON_VISIBLE(@"Fullscreen", f11, CGRectMake(width - 5 - 80, 5, BTN_RECT));
    
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

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized &&
      shouldTriggerClick == YES) {
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:[sender.view superview]];
        int hotbarItem = callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
        
        if (hotbarItem == -1) {
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

-(void)surfaceOnLongpress:(UILongPressGestureRecognizer *)sender
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGPoint location = [sender locationInView:[sender.view superview]];
    int hotbarItem = callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale);
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (hotbarItem == -1) {
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
                Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_LEFT, 0, 0);
            } else {
                Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_Q, 0, 0, 0);
            }
        }
    }
}

-(void)inputViewDidChange {
    if ([inputView.text length] <= 1) {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 1, 0);
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_BACKSPACE, 0, 0, 0);
    } else {
        NSString *newText = [inputView.text substringFromIndex:2];
        int charLength = [newText length];
        for (int i = 0; i < charLength; i++) {
            // Directly convert unichar to jchar which both are in UTF-16 encoding.
            Java_org_lwjgl_glfw_CallbackBridge_nativeSendCharMods(NULL, NULL, (jchar) [newText characterAtIndex:i] /* charText[i] */, /* mods */ 0);
        }
    }

    // Reset to default value
    inputView.text = @"  ";
}

-(void)inputViewDidClick {
    // Zero the input field so user will no longer able to select text inside.
    inputView.alpha = 0.0f;
    inputView.text = @"  ";
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_ENTER, 0, 1, 0);
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendKey(NULL, NULL, GLFW_KEY_ENTER, 0, 0, 0);
    return YES;
}

int currentVisibility = 1;
ADD_BUTTON_DEF(special_togglebtn) {
    if (held == 0) {
        currentVisibility = !currentVisibility;
        for (int i = 0; i < togglableVisibleButtonIndex + 1; i++) {
            togglableVisibleButtons[i].hidden = currentVisibility;
        }
        
        inputView.hidden = currentVisibility;
    }
}

ADD_BUTTON_DEF(special_keyboard) {
    if (held == 0) {
        [inputView resignFirstResponder];
        inputView.alpha = 1.0f;
        inputView.text = @"";
    }
}

ADD_BUTTON_DEF(special_mouse_pri) {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_LEFT, held, 0);
}

ADD_BUTTON_DEF(special_mouse_sec) {
    Java_org_lwjgl_glfw_CallbackBridge_nativeSendMouseButton(NULL, NULL, GLFW_MOUSE_BUTTON_RIGHT, held, 0);
}

ADD_BUTTON_DEF_KEY(f3, GLFW_KEY_F3)
ADD_BUTTON_DEF_KEY(f5, GLFW_KEY_F5)
ADD_BUTTON_DEF_KEY(f11, GLFW_KEY_F11)
ADD_BUTTON_DEF_KEY(t, GLFW_KEY_T)
ADD_BUTTON_DEF_KEY(c, GLFW_KEY_C)
ADD_BUTTON_DEF_KEY(f, GLFW_KEY_F)
ADD_BUTTON_DEF_KEY(tab, GLFW_KEY_TAB)

ADD_BUTTON_DEF_KEY(w, GLFW_KEY_W)
ADD_BUTTON_DEF_KEY(a, GLFW_KEY_A)
ADD_BUTTON_DEF_KEY(s, GLFW_KEY_S)
ADD_BUTTON_DEF_KEY(d, GLFW_KEY_D)
ADD_BUTTON_DEF_KEY(e, GLFW_KEY_E)

ADD_BUTTON_DEF_KEY(left_shift, GLFW_KEY_LEFT_SHIFT)

ADD_BUTTON_DEF_KEY(space, GLFW_KEY_SPACE)
ADD_BUTTON_DEF_KEY(escape, GLFW_KEY_ESCAPE)

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
- (void)mglkView:(MGLKView *)view drawInRect:(CGRect)rect {
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
}

- (void)sendTouchEvent:(NSSet *)touches withEvent:(int)event
{
    UITouch* touchEvent = [touches anyObject];
    if ([touchEvent view] == touchView) {
        CGPoint locationInView = [touchEvent locationInView:touchView];
        [self sendTouchPoint:locationInView withEvent:event];
    }
}

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    if (callback_SurfaceViewController_touchHotbar(location.x * screenScale, location.y * screenScale) == -1) {
        callback_SurfaceViewController_onTouch(event, location.x * screenScale, location.y * screenScale);
    }
    
    // Java_org_lwjgl_glfw_CallbackBridge_nativeSendCursorPos(NULL, NULL, location.x * screenScale, location.y * screenScale);
}

int touchesMovedCount;
// Equals to Android ACTION_DOWN
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_DOWN];
    touchesMovedCount = 0;
    shouldTriggerClick = YES;
}

// Equals to Android ACTION_MOVE
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_MOVE];
    if (touchesMovedCount >= 1) {
        shouldTriggerClick = NO;
    } else ++touchesMovedCount;
}

// Equals to Android ACTION_UP
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_UP];
}

@end
