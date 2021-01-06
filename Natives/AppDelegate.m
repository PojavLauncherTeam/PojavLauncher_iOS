//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "JavaLauncher.h"

#import <Foundation/Foundation.h>
#import <math.h>

#include "utils.h"

GLKView* mGLKView;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSLog(@"Hello from app launch!");
    
    // self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    GLKView *view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.context = context;
    view.delegate = self;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self.window addSubview:view];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [EAGLContext setCurrentContext:context];

    [view bindDrawable];
        
    mGLKView = view;

    width_c = (int) roundf([[UIScreen mainScreen] bounds].size.width);
    height_c = (int) roundf([[UIScreen mainScreen] bounds].size.height);
    
    callback_AppDelegate_didFinishLaunching(width_c, height_c);
    
    return YES;
}

@end
/*
GLKView* obtainGLKView() {
    return mGLKView;
}
*/