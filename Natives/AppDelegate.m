#import "AppDelegate.h"
#import "LoginViewController.h"
#import "SceneDelegate.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available(iOS 13.0, *)) {
    } else {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        launchInitialViewController(self.window);
        [self.window makeKeyAndVisible];
    }
    
    return YES;
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSDictionary *data = [NSDictionary dictionaryWithObject:url forKey:@"url"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MSALoginCallback" object:self userInfo:data];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
        CallbackBridge_setWindowAttrib(GLFW_FOCUSED, 1);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CallbackBridge_setWindowAttrib(GLFW_VISIBLE, 0);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    CallbackBridge_setWindowAttrib(GLFW_VISIBLE, 1);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    CallbackBridge_setWindowAttrib(GLFW_FOCUSED, 0);
}

@end
