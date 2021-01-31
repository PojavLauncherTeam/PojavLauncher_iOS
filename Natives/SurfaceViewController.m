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
    button_##KEY.frame = RECT; \
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
        sendData(EVENT_TYPE_KEY, KEYCODE, 0, held, 0); \
    }

#define BTN_RECT 80.0, 30.0
#define BTN_SQUARE 50.0, 50.0

int togglableVisibleButtonIndex = -1;
UIButton* togglableVisibleButtons[100];

@interface SurfaceViewController () {
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

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);

    // Custom button
    // ADD_BUTTON(@"F1", f1, CGRectMake(5, 5, width, height));

    // TODO
    ADD_BUTTON(@"GUI", special_togglebtn, CGRectMake(5, height - 5 - 50, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Keyboard", special_keyboard, CGRectMake(5 * 3 + 80 * 2, 5, BTN_RECT));

    ADD_BUTTON_VISIBLE(@"Pri", special_mouse_pri, CGRectMake(5, height - 5 * 3 - 50 * 3, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Sec", special_mouse_sec, CGRectMake(5 * 3 + 50 * 2, height - 5 * 3 - 50 * 3, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"Debug", f3, CGRectMake(5, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Chat", t, CGRectMake(5 * 2 + 80, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"Tab", tab, CGRectMake(5 * 4 + 80 * 3, 5, BTN_RECT));
    ADD_BUTTON_VISIBLE(@"3rd", f5, CGRectMake(5, 5 * 2 + 30.0, BTN_RECT));

    ADD_BUTTON_VISIBLE(@"▲", w, CGRectMake(5 * 2 + 50, height - 5 * 3 - 50 * 3, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"◀", a, CGRectMake(5, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"▼", s, CGRectMake(5 * 2 + 50, height - 5 - 50, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"▶", d, CGRectMake(5 * 3 + 50 * 2, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"◇", left_shift, CGRectMake(5 * 2 + 50, height - 5 * 2 - 50 * 2, BTN_SQUARE));
    ADD_BUTTON_VISIBLE(@"Inv", e, CGRectMake(5 * 3 + 50 * 2, height - 5 - 50, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"⬛", space, CGRectMake(width - 5 * 2 - 50 * 2, height - 5 * 2 - 50 * 2, BTN_SQUARE));

    ADD_BUTTON_VISIBLE(@"Esc", escape, CGRectMake(width - 5 - 80, height - 5 - 30, BTN_RECT));

    // ADD_BUTTON_VISIBLE(@"Enter", enter, CGRectMake(5, 70.0, BTN_SQUARE));

    [self executebtn_special_togglebtn:0];

    viewController = self;

    MGLKView *view = glView = (MGLKView *) self.view;
    view.drawableDepthFormat = MGLDrawableDepthFormat24;
    view.enableSetNeedsDisplay = YES;

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

// sendData: type, keycode, scancode, action, mods

int currentVisibility = 1;
ADD_BUTTON_DEF(special_togglebtn) {
    if (held == 0) {
        currentVisibility = !currentVisibility;
        for (int i = 0; i < togglableVisibleButtonIndex + 1; i++) {
            togglableVisibleButtons[i].hidden = currentVisibility;
        }
    }
}

ADD_BUTTON_DEF(special_keyboard) {
    // TODO
}

ADD_BUTTON_DEF(special_mouse_pri) {
    // TODO
}

ADD_BUTTON_DEF(special_mouse_sec) {
    // TODO
}

ADD_BUTTON_DEF_KEY(f3, GLFW_KEY_F3)
ADD_BUTTON_DEF_KEY(f5, GLFW_KEY_F5)
ADD_BUTTON_DEF_KEY(t, GLFW_KEY_T)
ADD_BUTTON_DEF_KEY(tab, GLFW_KEY_TAB)

ADD_BUTTON_DEF_KEY(w, GLFW_KEY_W)
ADD_BUTTON_DEF_KEY(a, GLFW_KEY_A)
ADD_BUTTON_DEF_KEY(s, GLFW_KEY_S)
ADD_BUTTON_DEF_KEY(d, GLFW_KEY_D)
ADD_BUTTON_DEF_KEY(e, GLFW_KEY_E)

ADD_BUTTON_DEF_KEY(left_shift, GLFW_KEY_LEFT_SHIFT)

ADD_BUTTON_DEF_KEY(space, GLFW_KEY_SPACE)
ADD_BUTTON_DEF_KEY(escape, GLFW_KEY_ESCAPE)

/*
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
*/

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

- (void)mglkView:(MGLKView *)view drawInRect:(CGRect)rect {
    // glClearColor(0.6f, 0.6f, 0.6f, 1.0f);
    // glClear(GL_COLOR_BUFFER_BIT);
    // [self setNeedsDisplay]
    // NSLog(@"swapbuffer");

    [super pause];
}

- (void)sendTouchEvent:(NSSet *)touches withEvent:(int)event
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    UITouch* touchEvent = [touches anyObject];
    CGPoint locationInView = [touchEvent locationInView:self.view];
    // CGPoint normalizedPoint = getNormalizedPoint(self.view, locationInView);
    callback_SurfaceViewController_onTouch(event, locationInView.x * screenScale, locationInView.y * screenScale /* normalizedPoint.x, normalizedPoint.y */);
}

// Equals to Android ACTION_DOWN
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_DOWN];
}

// Equals to Android ACTION_MOVE
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_MOVE];
}

// Equals to Android ACTION_UP
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded: touches withEvent: event];
    [self sendTouchEvent: touches withEvent: ACTION_UP];
}

// #pragma mark - GLKView and GLKViewController delegate methods
@end
