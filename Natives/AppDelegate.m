//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "JavaLauncher.h"

#import <Foundation/Foundation.h>
#import <math.h>

#include "utils.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  NSLog(@"Hello from app launch!");
  int width_c = (int) roundf([[UIScreen mainScreen] bounds].size.width);
  int height_c = (int) roundf([[UIScreen mainScreen] bounds].size.height);
  callback_AppDelegate_didFinishLaunching(width_c, height_c);

  return YES;
}

@end
