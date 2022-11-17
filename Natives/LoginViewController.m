#include <dirent.h>
#include <stdio.h>

#import "AFNetworking.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "authenticator/BaseAuthenticator.h"
#import "ALTServerConnection.h"

#import "AppDelegate.h"
#import "AccountListViewController.h"
#import "LauncherSplitViewController.h"
#import "LoginViewController.h"

#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#import "log.h"

#define AUTORESIZE_BTN UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin
#define AUTORESIZE AUTORESIZE_BTN | UIViewAutoresizingFlexibleBottomMargin

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

    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height; // - self.navigationController.navigationBar.frame.size.height;
    CGFloat rawHeight = self.view.frame.size.height;

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

    CGFloat widthSplit = width / 4.0;
    CGFloat widthSplit2 = width / 2.0;
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppLogo-Vector"]];
    logoView.frame = CGRectMake(0, (rawHeight / 2) - 125, width, 250);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    logoView.autoresizingMask = AUTORESIZE;
    [self.view addSubview:logoView];

    UIImageView *workMarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppLogo"]];
    workMarkView.frame = CGRectMake(0, (rawHeight / 2) - 35, width, 70);
    [workMarkView setContentMode:UIViewContentModeScaleAspectFit];
    workMarkView.autoresizingMask = AUTORESIZE;
    [self.view addSubview:workMarkView];

    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd"];
    NSString* date = [dateFormatter stringFromDate:[NSDate date]];
    
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction
            target:self action:@selector(latestLogShare)],
        // There's no better way to put both title+icon for both iOS 12 and 13+, so do this
        [[UIBarButtonItem alloc]
            initWithTitle:localize(@"login.menu.sendlogs", nil)
            style:UIBarButtonItemStyleDone
            target:self action:@selector(latestLogShare)]
    ];

    CGRect frame = CGRectMake(widthSplit2 - (((width - widthSplit * 2.0) / 2) / 2), (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    
    UIButton *button_login = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(button_login);
    [button_login setTitle:localize(@"Sign in", nil) forState:UIControlStateNormal];
    button_login.autoresizingMask = AUTORESIZE_BTN;
    button_login.frame = CGRectMake(frame.origin.x - frame.size.width - 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        button_login.backgroundColor = [UIColor colorWithRed:67/255.0 green:0/255.0 blue:8/255.0 alpha:1.0];
    } else {
        button_login.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    }
    button_login.layer.cornerRadius = 5;
    [button_login setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login addTarget:self action:@selector(accountType:) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 14.0, *)) {
        UIAction *option1 = [UIAction actionWithTitle:localize(@"login.option.microsoft", nil) image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAction *option3 = [UIAction actionWithTitle:localize(@"login.option.demo", nil) image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginDemo:button_login];}];
        UIAction *option4 = [UIAction actionWithTitle:localize(@"login.option.local", nil) image:nil identifier:nil
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
    [self.view addSubview:button_login];

    UIButton *button_accounts = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(button_accounts);
    [button_accounts setTitle:localize(@"Accounts", nil) forState:UIControlStateNormal];
    button_accounts.autoresizingMask = AUTORESIZE_BTN;
    button_accounts.frame = CGRectMake(frame.origin.x + frame.size.width + 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
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
    [self.view addSubview:button_accounts];
    
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        UILabel *technoNote = [[UILabel alloc] initWithFrame:CGRectMake(0, height - 60, width, 40.0)];
        technoNote.text = @"Technoblade never dies!";
        technoNote.lineBreakMode = NSLineBreakByWordWrapping;
        technoNote.numberOfLines = 1;
        [technoNote setFont:[UIFont boldSystemFontOfSize:10]];
        technoNote.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:technoNote];
    }

    if (!getEntitlementValue(@"dynamic-codesigning")) {
        if (isJITEnabled()) {
            self.title = localize(@"login.jit.enabled", nil);
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
        UIAlertAction *microsoft = [UIAlertAction actionWithTitle:localize(@"login.option.microsoft", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAlertAction *offline = [UIAlertAction actionWithTitle:localize(@"login.option.local", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginOffline:sender];}];
        UIAlertAction *demo = [UIAlertAction actionWithTitle:localize(@"login.option.demo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginDemo:sender];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(localize(@"Cancel", nil), nil) style:UIAlertActionStyleCancel handler:nil];
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
        [self displayProgress:localize(@"login.progress.title", nil)];
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
                        showDialog(self, localize(@"Error", nil), outError);
                    }
                }
            } else {
                if (error.code != ASWebAuthenticationSessionErrorCodeCanceledLogin) {
                    showDialog(self, localize(@"Error", nil), error.localizedDescription);
                }
            }
        }];

    if (@available(iOS 13.0, *)) {
        self.authVC.prefersEphemeralWebBrowserSession = YES;
        self.authVC.presentationContextProvider = self;
    }

    if ([self.authVC start] == NO) {
        showDialog(self, localize(@"Error", nil), @"Unable to open Safari");
    }
}

- (void)loginOffline:(UIButton *)sender {
    if ([getPreference(@"local_warn") boolValue] == YES) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.localmode", nil) message:localize(@"login.warn.message.localmode", nil) preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginOffline:sender];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
        [self presentViewController:offlineAlert animated:YES completion:nil];
        [offlineAlert addAction:ok];
        [offlineAlert addAction:cancel];
        setPreference(@"local_warn", @NO);
    } else {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:localize(@"Sign in", nil) message:localize(@"login.option.local", nil) preferredStyle:UIAlertControllerStyleAlert];
        [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = localize(@"login.alert.field.username", nil);
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.borderStyle = UITextBorderStyleRoundedRect;
        }];
        [controller addAction:[UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray *textFields = controller.textFields;
            UITextField *usernameField = textFields[0];
            if (usernameField.text.length < 3 || usernameField.text.length > 16) {
                controller.message = localize(@"login.error.username.outOfRange", nil);
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                [self loginAccountInput:TYPE_OFFLINE data:usernameField.text];
            }
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)loginDemo:(UIButton *)sender {
    if ([getPreference(@"demo_warn") boolValue] == YES) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:localize(@"login.warn.title.demomode", nil) message:localize(@"login.warn.message.demomode", nil) preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
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

- (void)enableJITWithAltJIT
{
    self.title = localize(@"login.jit.start.AltKit", nil);
    [ALTServerManager.sharedManager startDiscovering];
    [ALTServerManager.sharedManager autoconnectWithCompletionHandler:^(ALTServerConnection *connection, NSError *error) {
        if (error) {
            NSLog(@"[AltKit] Could not auto-connect to server. %@", error);
            self.title = localize(@"login.jit.fail.AltKit", nil);
            return;
        }
        [connection enableUnsignedCodeExecutionWithCompletionHandler:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"[AltKit] Successfully enabled JIT compilation!"); 
                [ALTServerManager.sharedManager stopDiscovering];
                self.title = localize(@"login.jit.enabled", nil);
                self.navigationItem.leftBarButtonItem = nil;
            } else {
                NSLog(@"[AltKit] Could not enable JIT compilation. %@", error);
                self.title = localize(@"login.jit.fail.AltKit", nil);
                self.navigationItem.leftBarButtonItem = nil;
                showDialog(self, localize(@"Error", nil), error.description);
            }
            [connection disconnect];
        }];
    }];
}

- (void)enableJITWithJitStreamer
{
    [self displayProgress:localize(@"login.jit.checking", nil)];

    // TODO: customizable address
    NSString *address = getPreference(@"jitstreamer_server");
    debugLog("JitStreamer server is %s, attempting to connect...", address.UTF8String);
    
    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer = AFHTTPResponseSerializer.serializer;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    [manager GET:[NSString stringWithFormat:@"http://%@/version", address] parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSData *response) {
        NSString *version = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"Found JitStreamer %@", version);
        self.title = localize(@"login.jit.found.JitStreamer", nil);
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
                self.title = localize(@"login.jit.enabled", nil);
                self.navigationItem.leftBarButtonItem = nil;
            } else {
                self.title = [NSString stringWithFormat:localize(@"login.jit.fail.JitStreamer", nil), responseDict[@"message"]];
                self.navigationItem.leftBarButtonItem = nil;
                showDialog(self, localize(@"Error", nil), responseDict[@"message"]);
                [self enableJITWithAltJIT];
            }
        };
        [manager POST:[NSString stringWithFormat:@"http://%@/attach/%d/", address, getpid()] parameters:nil headers:nil progress:nil success:handleResponse failure:handleResponse];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self enableJITWithAltJIT];
    }];
}

-(void)latestLogShare
{
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
    NSLog(@"Path is %@", latestlogPath);
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];

    [self presentViewController:activityViewController animated:YES completion:nil];
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
