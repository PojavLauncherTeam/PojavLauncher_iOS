#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>
#import "LauncherNewsViewController.h"

@interface LauncherNewsViewController()<WKNavigationDelegate>
@end

@implementation LauncherNewsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // TODO: replace temp changelog
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://khanhduytran0.github.io/PojavLauncher/changelog.ios.html"]];

    WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webConfig];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.navigationDelegate = self;
    [webView loadRequest:request];
    [self.view addSubview:webView];
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
