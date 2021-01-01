//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "JavaLauncher.h"
#import <Foundation/Foundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  NSLog(@"Hello from app launch!");
  launchJVM();

  return YES;
}

@end
