#import <WebKit/WebKit.h>
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "utils.h"

#define sidebarNavController ((UINavigationController *)self.splitViewController.viewControllers[0])
#define sidebarViewController ((LauncherMenuViewController *)sidebarNavController.viewControllers[0])

@interface LauncherNewsViewController()<WKNavigationDelegate>
@end

@implementation LauncherNewsViewController
WKWebView *webView;
UIEdgeInsets insets;

- (NSString *)imageName {
    return @"MenuNews";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL isVersionLegacy = UIDevice.currentDevice.systemVersion.floatValue < 14;
    
    CGSize size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://pojavlauncherteam.github.io/changelogs/IOS.html"]];

    WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webConfig];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.opaque = NO;
    [self adjustWebViewForSize:size];
    webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *nozoom = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [webView.configuration.userContentController addUserScript:nozoom];
    [webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [webView loadRequest:request];
    [self.view addSubview:webView];

    if(isVersionLegacy) {
        if(getenv("POJAV_DETECTED_LEGACY") && [getPreference(@"legacy_device_warn") boolValue]) {
            // "The next release of PojavLauncher will not be compatible with this device."
            UIAlertController *deviceWarn = [UIAlertController
                                        alertControllerWithTitle:localize(@"login.warn.title.legacy_device", nil)
                                        message:localize(@"login.warn.message.legacy_device", nil)
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* deviceAction = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                    setPreference(@"legacy_device_warn", @NO);
            }];
            deviceWarn.popoverPresentationController.sourceView = self.view;
            deviceWarn.popoverPresentationController.sourceRect = self.view.bounds;
            [deviceWarn addAction:deviceAction];
            [self presentViewController:deviceWarn animated:YES completion:nil];
            setPreference(@"legacy_device_warn", @NO);
        } else {
            if([getPreference(@"legacy_version_counter") intValue] == 0) {
                // "The next release of PojavLauncher will require a system update."
                UIAlertController *versionWarn = [UIAlertController
                                            alertControllerWithTitle:localize(@"login.warn.title.legacy_version", nil)
                                            message:localize(@"login.warn.message.legacy_version", nil)
                                            preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *versionAction = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                versionWarn.popoverPresentationController.sourceView = self.view;
                versionWarn.popoverPresentationController.sourceRect = self.view.bounds;
                [versionWarn addAction:versionAction];
                [self presentViewController:versionWarn animated:YES completion:nil];
            }
        }
    } else {
        if(!getenv("POJAV_DETECTEDJB") && [getPreference(@"limited_ram_warn") boolValue] == YES && (roundf(NSProcessInfo.processInfo.physicalMemory / 1048576) < 3900)) {
            // "This device has a limited amount of memory available."
            UIAlertController *ramWarn = [UIAlertController
                                        alertControllerWithTitle:localize(@"login.warn.title.limited_ram", nil)
                                        message:localize(@"login.warn.message.limited_ram", nil)
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ramAction = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                    setPreference(@"limited_ram_warn", @NO);
            }];
            ramWarn.popoverPresentationController.sourceView = self.view;
            ramWarn.popoverPresentationController.sourceRect = self.view.bounds;
            [ramWarn addAction:ramAction];
            [self presentViewController:ramWarn animated:YES completion:nil];
            setPreference(@"limited_ram_warn", @NO);
        }
    }
       
    int launchNum = [getPreference(@"legacy_version_counter") intValue];
    if(launchNum > 0) {
       setPreference(@"legacy_version_counter", @(launchNum - 1));
    } else {
       setPreference(@"legacy_version_counter", @(30));
    }
    
    self.title = localize(@"News", nil);
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.rightBarButtonItem = [sidebarViewController drawAccountButton];
    self.navigationItem.leftItemsSupplementBackButton = true;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x > 0)
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self adjustWebViewForSize:size];
}

- (void)adjustWebViewForSize:(CGSize)size {
    BOOL isPortrait = size.height > size.width;
    if (isPortrait) {
        webView.scrollView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height + insets.top, 0, self.navigationController.navigationBar.frame.size.height + insets.bottom, 0);
    } else {
        webView.scrollView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, self.navigationController.navigationBar.frame.size.height, 0);
    }
}

- (void)webView:(WKWebView *)webView 
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction 
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
     if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        openLink(self, navigationAction.request.URL);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
