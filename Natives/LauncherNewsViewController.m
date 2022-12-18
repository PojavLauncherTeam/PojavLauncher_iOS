#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "utils.h"

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
    webView.scrollView.delegate = self;
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *nozoom = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [webView.configuration.userContentController addUserScript:nozoom];
    [webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [webView loadRequest:request];
    [self.view addSubview:webView];
    
    if(roundf([[NSProcessInfo processInfo] physicalMemory] / 1048576) < 1900 && [getPreference(@"unsupported_warn_counter") intValue] == 0) {
        UIAlertController *RAMAlert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.a7", nil) message:localize(@"login.warn.message.a7", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:RAMAlert animated:YES completion:nil];
        [RAMAlert addAction:ok];
    }
    
    int launchNum = [getPreference(@"unsupported_warn_counter") intValue];
    if(launchNum > 0) {
        setPreference(@"unsupported_warn_counter", @(launchNum - 1));
    } else {
        setPreference(@"unsupported_warn_counter", @(30));
    }

    if(!getenv("POJAV_DETECTEDJB") && [getPreference(@"ram_unjb_warn") boolValue] == YES && [getPreference(@"auto_ram") boolValue] == NO) {
        UIAlertController *ramalert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.ram_unjb", nil) message:localize(@"login.warn.message.ram_unjb", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:ramalert animated:YES completion:nil];
        [ramalert addAction:ok];
        setPreference(@"ram_unjb_warn", @NO);
    }
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
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:navigationAction.request.URL];
        [self presentViewController:vc animated:YES completion:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
