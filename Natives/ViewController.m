#import "ViewController.h"
#include "utils.h"

#include "GLES2/gl2.h"
#include "GLES2/gl2ext.h"

@interface ViewController () {
}

@property (strong, nonatomic) MGLContext *context;

- (void)setupGL;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES3];

    if (!self.context) {
        self.context = [[MGLContext alloc] initWithAPI:kMGLRenderingAPIOpenGLES2];
    }

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    MGLKView *view = (MGLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = MGLDrawableDepthFormat24;

    //[view bindDrawable];

    [self setupGL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [view setPaused:YES];
    [view setResumeOnDidBecomeActive:NO];
}

- (void)dealloc
{
    if ([MGLContext currentContext] == self.context) {
        [MGLContext setCurrentContext:nil];
    }
}

- (void)setupGL
{
    [MGLContext setCurrentContext:self.context];
    
    // glClearColor(0.1, 0.1f, 0.1f, 1.0f);
    // glClear(GL_COLOR_BUFFER_BIT);

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width_c = (int) roundf(screenBounds.size.width * screenScale);
    int height_c = (int) roundf(screenBounds.size.height * screenScale);
    // glViewport(0, 0, width_c, height_c);
    callback_AppDelegate_didFinishLaunching(width_c, height_c);
}

- (void)sendTouchEvent:(NSSet *)touches withEvent:(int)event
{
    UITouch* touchEvent = [touches anyObject];
    CGPoint locationInView = [touchEvent locationInView:self.view];
    // CGPoint normalizedPoint = getNormalizedPoint(self.view, locationInView);
    callback_ViewController_onTouch(event, locationInView.x, locationInView.y /* normalizedPoint.x, normalizedPoint.y */);
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
