//
//  main.m
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include "JavaLauncher.h"

int launchUI() {
  @autoreleasepool {
      return UIApplicationMain(first_argc, first_argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
