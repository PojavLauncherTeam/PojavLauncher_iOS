#include <dirent.h>
#include <stdio.h>

#import "AFNetworking.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "authenticator/BaseAuthenticator.h"

#import "AppDelegate.h"
#import "AboutLauncherViewController.h"
#import "AccountListViewController.h"
#import "LauncherFAQViewController.h"
#import "LauncherSplitViewController.h"
#import "LoginViewController.h"
#import "UpdateHistoryViewController.h"

#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#define TYPE_SELECTACC 0
#define TYPE_MICROSOFT 1
#define TYPE_OFFLINE 2

extern NSMutableDictionary *prefDict;

#pragma mark - LoginViewController
@interface LoginViewController () <ASWebAuthenticationPresentationContextProviding> {}
@property(nonatomic) ASWebAuthenticationSession *authVC;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    setViewBackgroundColor(self.view);

    setDefaultValueForPref(prefDict, @"control_safe_area", NSStringFromCGRect(getDefaultSafeArea()));

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msaLoginCallback:) name:@"MSALoginCallback" object:nil];

    CGRect screenBounds = UIScreen.mainScreen.bounds;

    CGFloat width = screenBounds.size.width;
    CGFloat height = screenBounds.size.height - self.navigationController.navigationBar.frame.size.height;
    CGFloat rawHeight = screenBounds.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:scrollView];
    
    if(roundf([[NSProcessInfo processInfo] physicalMemory] / 1048576) < 1900 && [getPreference(@"unsupported_warn_counter") intValue] == 0) {
        UIAlertController *RAMAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"login.warn.title.a7", nil) message:NSLocalizedString(@"login.warn.message.a7", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
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
        UIAlertController *ramalert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"login.warn.title.ram_unjb", nil) message:NSLocalizedString(@"login.warn.message.ram_unjb", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:ramalert animated:YES completion:nil];
        [ramalert addAction:ok];
        setPreference(@"ram_unjb_warn", @NO);
    }

    CGFloat widthSplit = width / 4.0;
    CGFloat widthSplit2 = width / 2.0;

    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppLogo"]];
    logoView.frame = CGRectMake(0, (rawHeight / 2) - 35, width, 70);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:logoView];

    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd"];
    NSString* date = [dateFormatter stringFromDate:[NSDate date]];
    
    if(@available(iOS 14.0, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"info.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(aboutLauncher)];
        UIAction *option1 = [UIAction actionWithTitle:NSLocalizedString(@"login.menu.about", nil) image:[[UIImage systemImageNamed:@"eyes.inverse"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self aboutLauncher];}];
        UIAction *option2 = [UIAction actionWithTitle:NSLocalizedString(@"login.menu.sendlogs", nil) image:[[UIImage systemImageNamed:@"square.and.arrow.up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self latestLogShare];}];
        UIAction *option3 = [UIAction actionWithTitle:NSLocalizedString(@"login.menu.updates", nil) image:[[UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self updateHistory];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option1, option2, option3]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"login.menu.about", nil) style:UIBarButtonItemStyleDone target:self action:@selector(aboutLauncher)];
    }

    UIButton *button_faq = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(button_faq);
    [button_faq setTitle:NSLocalizedString(@"FAQ", @"Frequently asked questions") forState:UIControlStateNormal];
    button_faq.frame = CGRectMake(widthSplit2 - (((width - widthSplit * 2.0) / 2) / 2), (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        button_faq.backgroundColor = [UIColor colorWithRed:67/255.0 green:0/255.0 blue:8/255.0 alpha:1.0];
    } else {
        button_faq.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    }
    button_faq.layer.cornerRadius = 5;
    [button_faq setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_faq addTarget:self action:@selector(showFAQ) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 13.0, *)) {
        button_faq.imageView.image = [[UIImage systemImageNamed:@"doc.text"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_faq setTintColor:UIColor.whiteColor];
        [button_faq setImage:button_faq.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_faq];

    UIButton *button_login = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(button_login);
    [button_login setTitle:NSLocalizedString(@"Sign in", nil) forState:UIControlStateNormal];
    button_login.frame = CGRectMake(button_faq.frame.origin.x - button_faq.frame.size.width - 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        button_login.backgroundColor = [UIColor colorWithRed:67/255.0 green:0/255.0 blue:8/255.0 alpha:1.0];
    } else {
        button_login.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    }
    button_login.layer.cornerRadius = 5;
    [button_login setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login addTarget:self action:@selector(accountType:) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 14.0, *)) {
        UIAction *option1 = [UIAction actionWithTitle:NSLocalizedString(@"login.option.microsoft", nil) image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAction *option3 = [UIAction actionWithTitle:NSLocalizedString(@"login.option.demo", nil) image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginDemo:button_login];}];
        UIAction *option4 = [UIAction actionWithTitle:NSLocalizedString(@"login.option.local", nil) image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginOffline:button_login];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option4, option3, option1]];
        button_login.menu = menu;
        button_login.showsMenuAsPrimaryAction = YES;
    }
    if(@available (iOS 13.0, *)) {
        button_login.imageView.image = [[UIImage systemImageNamed:@"person.crop.circle.badge.plus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_login setTintColor:UIColor.whiteColor];
        [button_login setImage:button_login.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_login];

    UIButton *button_accounts = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(button_accounts);
    [button_accounts setTitle:NSLocalizedString(@"Accounts", nil) forState:UIControlStateNormal];
    button_accounts.frame = CGRectMake(button_faq.frame.origin.x + button_faq.frame.size.width + 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        button_accounts.backgroundColor = [UIColor colorWithRed:67/255.0 green:0/255.0 blue:8/255.0 alpha:1.0];
    } else {
        button_accounts.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    }
    button_accounts.layer.cornerRadius = 5;
    [button_accounts setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_accounts addTarget:self action:@selector(loginAccount:) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 13.0, *)) {
        button_accounts.imageView.image = [[UIImage systemImageNamed:@"person.crop.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_accounts setTintColor:UIColor.whiteColor];
        [button_accounts setImage:button_accounts.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_accounts];
    
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        UILabel *technoNote = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, width, 40.0)];
        technoNote.text = @"Technoblade never dies!";
        technoNote.lineBreakMode = NSLineBreakByWordWrapping;
        technoNote.numberOfLines = 1;
        [technoNote setFont:[UIFont boldSystemFontOfSize:10]];
        technoNote.textAlignment = NSTextAlignmentCenter;
        [scrollView addSubview:technoNote];
    }

    if (!getEntitlementValue(@"dynamic-codesigning")) {
        if (isJITEnabled()) {
            self.title = NSLocalizedString(@"login.jit.enabled", nil);
        } else { 
            [self enableJITWithJitStreamer];
        }
    }
}

- (void)displayProgress:(NSString *)title {
    self.title = title;
    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
        style = UIActivityIndicatorViewStyleMedium;
    } else {
        style = UIActivityIndicatorViewStyleGray;
    } 
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    [indicator startAnimating];
}

- (void)accountType:(UIButton *)sender {
    if(@available (iOS 14.0, *)) {
        // UIMenu
    } else {
        UIAlertController *fullAlert = [UIAlertController alertControllerWithTitle:@"Let's get you signed in." message:@"What account do you use to log into Minecraft?" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *microsoft = [UIAlertAction actionWithTitle:NSLocalizedString(@"login.option.microsoft", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAlertAction *offline = [UIAlertAction actionWithTitle:NSLocalizedString(@"login.option.local", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginOffline:sender];}];
        UIAlertAction *demo = [UIAlertAction actionWithTitle:NSLocalizedString(@"login.option.demo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginDemo:sender];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(NSLocalizedString(@"Cancel", nil), nil) style:UIAlertActionStyleCancel handler:nil];
        [self setPopoverProperties:fullAlert.popoverPresentationController sender:sender];
        [self presentViewController:fullAlert animated:YES completion:nil];
        [fullAlert addAction:microsoft];
        [fullAlert addAction:demo];
        [fullAlert addAction:offline];
        [fullAlert addAction:cancel];
    }
}

- (void)loginAccountInput:(int)type data:(NSString *)data {
    __block BOOL shouldDismiss = NO;
    UIAlertController *alert;
    BaseAuthenticator *auth;

    switch (type) {
        case TYPE_MICROSOFT:
            auth = [[MicrosoftAuthenticator alloc] initWithInput:data];
            break;
        case TYPE_OFFLINE:
            auth = [[LocalAuthenticator alloc] initWithInput:data];
            break;
        case TYPE_SELECTACC: {
            NSString *fileContent = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), data] encoding:NSUTF8StringEncoding error:nil];
            shouldDismiss = [fileContent rangeOfString:@"\"accessToken\": \"0\","].location != NSNotFound;
            auth = [BaseAuthenticator loadSavedName:data];
            } break;
    }

    if (auth == nil) return;

    if (type != TYPE_OFFLINE && !shouldDismiss) {
        [self displayProgress:NSLocalizedString(@"login.progress.title", nil)];
    }

    id callback = ^(BOOL success) {
        self.title = @"";
        self.navigationItem.leftBarButtonItem = nil;
        if (!success) return;

        LauncherSplitViewController *splitVc;
        if (@available(iOS 14.0, tvOS 14.0, *)) {
            splitVc = [[LauncherSplitViewController alloc] initWithStyle:UISplitViewControllerStyleDoubleColumn];
        } else {
            splitVc = [[LauncherSplitViewController alloc] init];
        }
        splitVc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:splitVc animated:YES completion:nil];
    };
    if (type == TYPE_SELECTACC) {
        [auth refreshTokenWithCallback:callback];
    } else {
        [auth loginWithCallback:callback];
    }
}

- (void)loginMicrosoft {
    NSURL *url = [NSURL URLWithString:@"https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL&redirect_url=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf"];

    self.authVC =
        [[ASWebAuthenticationSession alloc] initWithURL:url
        callbackURLScheme:@"ms-xal-00000000402b5328"
        completionHandler:^(NSURL * _Nullable callbackURL,
        NSError * _Nullable error) {
            if (callbackURL != nil) {
                NSString *urlString = [callbackURL absoluteString];
                // NSLog(@"URL returned = %@", [callbackURL absoluteString]);

                if ([urlString containsString:@"/auth/?code="] == YES) {
                    NSArray *components = [urlString componentsSeparatedByString:@"/auth/?code="];
                    [self loginAccountInput:TYPE_MICROSOFT data:components[1]];
                } else {
                    NSArray *components = [urlString componentsSeparatedByString:@"/auth/?error="];
                    if ([components[1] hasPrefix:@"access_denied"] == NO) {
                        NSString *outError = [components[1]
                            stringByReplacingOccurrencesOfString:@"&error_description=" withString:@": "];
                        outError = [outError stringByRemovingPercentEncoding];
                        showDialog(self, NSLocalizedString(@"Error", nil), outError);
                    }
                }
            } else {
                if (error.code != ASWebAuthenticationSessionErrorCodeCanceledLogin) {
                    showDialog(self, NSLocalizedString(@"Error", nil), error.localizedDescription);
                }
            }
        }];

    if (@available(iOS 13.0, *)) {
        self.authVC.prefersEphemeralWebBrowserSession = YES;
        self.authVC.presentationContextProvider = self;
    }

    if ([self.authVC start] == NO) {
        showDialog(self, NSLocalizedString(@"Error", nil), @"Unable to open Safari");
    }
}

- (void)loginOffline:(UIButton *)sender {
    if ([getPreference(@"local_warn") boolValue] == YES) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"login.warn.title.localmode", nil) message:NSLocalizedString(@"login.warn.message.localmode", nil) preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginOffline:sender];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
        [self presentViewController:offlineAlert animated:YES completion:nil];
        [offlineAlert addAction:ok];
        [offlineAlert addAction:cancel];
        setPreference(@"local_warn", @NO);
    } else {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sign in", nil) message:NSLocalizedString(@"login.option.local", nil) preferredStyle:UIAlertControllerStyleAlert];
        [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"login.alert.field.username", nil);
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.borderStyle = UITextBorderStyleRoundedRect;
        }];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray *textFields = controller.textFields;
            UITextField *usernameField = textFields[0];
            if (usernameField.text.length < 3 || usernameField.text.length > 16) {
                controller.message = NSLocalizedString(@"login.error.username.outOfRange", nil);
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                [self loginAccountInput:TYPE_OFFLINE data:usernameField.text];
            }
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)loginDemo:(UIButton *)sender {
    if ([getPreference(@"demo_warn") boolValue] == YES) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"login.warn.title.demomode", nil) message:NSLocalizedString(@"login.warn.message.demomode", nil) preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
        [self presentViewController:offlineAlert animated:YES completion:nil];
        [offlineAlert addAction:ok];
        [offlineAlert addAction:cancel];
        setPreference(@"demo_warn", @NO);
    } else {
        [self loginMicrosoft];
    }
}

- (void)loginAccount:(UIButton *)sender {
    AccountListViewController *vc = [[AccountListViewController alloc] init];
/*
    vc.whenDelete = ^void(NSString* name) {
        UIAlertController* alert = showLoadingDialog(vc, @"Logging out...");
    };
*/
    vc.whenItemSelected = ^void(NSString* name) {
        [self loginAccountInput:TYPE_SELECTACC data:name];
    };
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);
    
    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    [self setPopoverProperties:popoverController sender:sender];
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = vc;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)enableJITWithJitStreamer
{
    [self displayProgress:NSLocalizedString(@"login.jit.checking", nil)];

    // TODO: customizable address
    NSString *address = @"69.69.0.1";

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer = AFHTTPResponseSerializer.serializer;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    [manager GET:[NSString stringWithFormat:@"http://%@/version", address] parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSData *response) {
        NSString *version = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"Found JitStreamer %@", version);
        self.title = NSLocalizedString(@"login.jit.found.JitStreamer", nil);
        manager.requestSerializer.timeoutInterval = 0;
        manager.responseSerializer = AFJSONResponseSerializer.serializer;
        void(^handleResponse)(NSURLSessionDataTask *task, id response) = ^void(NSURLSessionDataTask *task, id response){
            self.navigationItem.leftBarButtonItem = nil;
            NSDictionary *responseDict;
            // FIXME: successful response may fail due to serialization issues
            if ([response isKindOfClass:NSError.class]) {
                NSLog(@"Error?: %@", responseDict);
                NSData *errorData = ((NSError *)response).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                responseDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
            } else {
                responseDict = response;
            }
            if ([responseDict[@"success"] boolValue]) {
                self.title = NSLocalizedString(@"login.jit.enabled", nil);
            } else {
                self.title = [NSString stringWithFormat:NSLocalizedString(@"login.jit.fail.JitStreamer", nil), responseDict[@"message"]];
                showDialog(self, NSLocalizedString(@"Error", nil), responseDict[@"message"]);
                // TODO: [self enableJITWithAltJIT];
            }
        };
        [manager POST:[NSString stringWithFormat:@"http://%@/attach/%d/", address, getpid()] parameters:nil headers:nil progress:nil success:handleResponse failure:handleResponse];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        self.title = @"";
        self.navigationItem.leftBarButtonItem = nil;
        //showDialog(self, @"Error", [NSString stringWithFormat:@"%@", error]);
        // TODO: [self enableJITWithAltJIT];
    }];
}

- (void)aboutLauncher
{
    AboutLauncherViewController *vc = [[AboutLauncherViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showFAQ
{
    LauncherFAQViewController *vc = [[LauncherFAQViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)latestLogShare
{
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
    NSLog(@"Path is %@", latestlogPath);
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];

    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)updateHistory {
    UpdateHistoryViewController *vc = [[UpdateHistoryViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setPopoverProperties:(UIPopoverPresentationController *)controller sender:(UIButton *)sender {
    if (controller != nil) {
        controller.sourceView = sender;
        controller.sourceRect = sender.bounds;
    }
}

#pragma mark - ASWebAuthenticationPresentationContextProviding
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session  API_AVAILABLE(ios(13.0)){
    return UIApplication.sharedApplication.windows.firstObject;
}

@end
