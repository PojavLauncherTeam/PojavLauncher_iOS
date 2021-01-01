//
//  main.m
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include "JavaLauncher.h"

int launchUI(int argc, char *argv[]) {
  @autoreleasepool {
      return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
