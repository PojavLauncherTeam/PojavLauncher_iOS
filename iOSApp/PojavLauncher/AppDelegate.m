//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "CounterService.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  // Initialize the CounterService
  [CounterService init];

  return YES;
}

@end
