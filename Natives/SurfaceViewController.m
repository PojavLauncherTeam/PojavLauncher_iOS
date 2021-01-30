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
    
#define ADD_BUTTON_DEF(KEY) \
    - (void)executebtn_##KEY##_down { \
        [self executebtn_##KEY:1]; \
    } \
    - (void)executebtn_##KEY##_up { \
        [self executebtn_##KEY:0]; \
    } \
    - (void)executebtn_##KEY:(int)held

@interface SurfaceViewController () {
}

@property (strong, nonatomic) MGLContext *context;

- (void)setupGL;

@end

@implementation SurfaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    ADD_BUTTON(@"Tab", tab, CGRectMake(10.0, 10.0, 50.0, 50.0));
    ADD_BUTTON(@"Enter", enter, CGRectMake(10.0, 70.0, 50.0, 50.0));
    ADD_BUTTON(@"Esc", escape, CGRectMake(10.0, 130.0, 50.0, 50.0));
    ADD_BUTTON(@"F3", f3, CGRectMake(10.0, 190.0, 50.0, 50.0));

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

ADD_BUTTON_DEF(tab) {
    
}

ADD_BUTTON_DEF(enter) {
    NSLog(@"Enter held state: %d", held);
}

ADD_BUTTON_DEF(escape) {
    NSLog(@"Escape held state: %d", held);
}

ADD_BUTTON_DEF(f3) {
    
}

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

    int width_c = (int) roundf(screenBounds.size.width * screenScale);
    int height_c = (int) roundf(screenBounds.size.height * screenScale);
    // glViewport(0, 0, width_c, height_c);
    callback_SurfaceViewController_launchMinecraft(width_c, height_c);
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
