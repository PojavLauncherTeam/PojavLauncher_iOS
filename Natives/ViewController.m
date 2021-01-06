#import "ViewController.h"
#include "utils.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ViewController () {
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];

    if (!self.context) {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0.1, 0.1f, 0.1f, 1.0f);
}

#pragma mark - GLKView and GLKViewController delegate methods

int called = 0;
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (!called) {
        called = 1;
        glClear(GL_COLOR_BUFFER_BIT);
        callback_AppDelegate_didFinishLaunching(rect.size.width, rect.size.height);
        self.paused = YES;
    }
}

@end
