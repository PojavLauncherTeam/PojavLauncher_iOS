#include <dirent.h>
#include <stdio.h>

#import <AuthenticationServices/AuthenticationServices.h>

#import "AppDelegate.h"
#import "LauncherViewController.h"
#import "LoginViewController.h"
#import "AboutLauncherViewController.h"
#import "LauncherFAQViewController.h"
#import "LauncherPreferences.h"
#import "UpdateHistoryViewController.h"

#include "ios_uikit_bridge.h"
#include "utils.h"

#define TYPE_SELECTACC 0
#define TYPE_MICROSOFT 1
#define TYPE_MOJANG 2
#define TYPE_OFFLINE 3

void loginAccountInput(UINavigationController *controller, int type, const char* data_c) {
    JNIEnv *env;
    (*runtimeJavaVMPtr)->AttachCurrentThread(runtimeJavaVMPtr, &env, NULL);

    jstring data = (*env)->NewStringUTF(env, data_c);

    jclass clazz = (*env)->FindClass(env, "net/kdt/pojavlaunch/uikit/AccountJNI");
    assert(clazz);

    jmethodID method = (*env)->GetStaticMethodID(env, clazz, "loginAccount", "(ILjava/lang/String;)Z");
    assert(method);

    jboolean result = (*env)->CallStaticBooleanMethod(env, clazz, method, type, data);

    (*runtimeJavaVMPtr)->DetachCurrentThread(runtimeJavaVMPtr);

    if (result == JNI_TRUE) {
        if ([NSThread isMainThread]) {
            LauncherViewController *vc = [[LauncherViewController alloc] init];
            [controller pushViewController:vc animated:YES];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                LauncherViewController *vc = [[LauncherViewController alloc] init];
                [controller pushViewController:vc animated:YES];
            });
        }
    }
}

#pragma mark - LoginViewController
@interface LoginViewController () <ASWebAuthenticationPresentationContextProviding, UIPopoverPresentationControllerDelegate>{
}
@property (nonatomic, strong) ASWebAuthenticationSession *authVC;
@property (nonatomic, strong) UIActivityViewController *activityViewController;
@end

@implementation LoginViewController
@synthesize authVC;
@synthesize activityViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    viewController = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msaLoginCallback:) name:@"MSALoginCallback" object:nil];

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    int rawHeight = (int) roundf(screenBounds.size.height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:scrollView];

    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    if(getenv("POJAV_DETECTEDJB")) {
        if(![[NSFileManager defaultManager] fileExistsAtPath:@"/.procursus_strapped"] && [getPreference(@"jb_warn") boolValue] == YES) {
            NSString *jbMessage = [NSString stringWithFormat:@"Your current jailbreak (%s) does not have the Procursus bootstrap, which means that certain issues may occur that cannot be fixed. Please switch to a completely supported jailbreak, if possible.", getenv("POJAV_DETECTEDJB")];
            UIAlertController *jbAlert = [UIAlertController alertControllerWithTitle:@"Jailbreak not completely supported." message:jbMessage preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:jbAlert animated:YES completion:nil];
            [jbAlert addAction:ok];
            setPreference(@"jb_warn", @NO);
        }
    }

    CGFloat widthSplit = width / 4.0;
    CGFloat widthSplit2 = width / 2.0;

    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchScreen"]];
    logoView.frame = CGRectMake((width / 4) - 50, 0, (width / 2) / 4, rawHeight);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:logoView];

    UILabel *logoWaterView = [[UILabel alloc] initWithFrame:CGRectMake(logoView.frame.origin.x + logoView.frame.size.width + 30, 0, width - ((width / 2) / 4), rawHeight)];
    logoWaterView.text = @"PojavLauncher";
    logoWaterView.lineBreakMode = NSLineBreakByWordWrapping;
    logoWaterView.adjustsFontSizeToFitWidth = YES;
    logoWaterView.numberOfLines = 1;
    logoWaterView.minimumScaleFactor = 20./logoWaterView.font.pointSize;
    [self.view addSubview:logoWaterView];
    [logoWaterView setFont:[UIFont boldSystemFontOfSize:(logoView.frame.size.width / 2.0)]];



    if(@available (iOS 14.0, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"info.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(aboutLauncher)];
        UIAction *option1 = [UIAction actionWithTitle:@"About PojavLauncher" image:[[UIImage systemImageNamed:@"eyes.inverse"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self aboutLauncher];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Send your logs" image:[[UIImage systemImageNamed:@"square.and.arrow.up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self latestLogShare];}];
        UIAction *option3 = [UIAction actionWithTitle:@"Recent updates" image:[[UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self updateHistory];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option1, option2, option3]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStyleDone target:self action:@selector(aboutLauncher)];
    }

    UIButton *button_faq = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_faq setTitle:@"  FAQ" forState:UIControlStateNormal];
    button_faq.frame = CGRectMake(widthSplit2 - (((width - widthSplit * 2.0) / 2) / 2), (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    button_faq.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_faq.layer.cornerRadius = 5;
    [button_faq setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_faq addTarget:self action:@selector(showFAQ) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 13.0, *)) {
        button_faq.imageView.image = [[UIImage systemImageNamed:@"doc.text"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_faq setTintColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
        [button_faq setImage:button_faq.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_faq];

    UIButton *button_login = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login setTitle:@"  Sign In" forState:UIControlStateNormal];
    button_login.frame = CGRectMake(button_faq.frame.origin.x - button_faq.frame.size.width - 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    button_login.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login.layer.cornerRadius = 5;
    [button_login setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login addTarget:self action:@selector(accountType:) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 14.0, *)) {
        UIAction *option1 = [UIAction actionWithTitle:@"Microsoft account" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Mojang account" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginUsername:TYPE_MOJANG];}];
        UIAction *option3 = [UIAction actionWithTitle:@"Demo account" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginDemo:button_login];}];
        UIAction *option4 = [UIAction actionWithTitle:@"Local account" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self loginOffline:button_login];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option4, option3, option2, option1]];
        button_login.menu = menu;
        button_login.showsMenuAsPrimaryAction = YES;
    }
    if(@available (iOS 13.0, *)) {
        button_login.imageView.image = [[UIImage systemImageNamed:@"person.crop.circle.badge.plus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_login setTintColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
        [button_login setImage:button_login.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_login];

    UIButton *button_accounts = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_accounts setTitle:@"  Accounts" forState:UIControlStateNormal];
    button_accounts.frame = CGRectMake(button_faq.frame.origin.x + button_faq.frame.size.width + 20, (height - 80.0), (width - widthSplit * 2.0) / 2, 40.0);
    button_accounts.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_accounts.layer.cornerRadius = 5;
    [button_accounts setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_accounts addTarget:self action:@selector(loginAccount:) forControlEvents:UIControlEventTouchUpInside];
    if(@available (iOS 13.0, *)) {
        button_accounts.imageView.image = [[UIImage systemImageNamed:@"person.crop.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button_accounts setTintColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
        [button_accounts setImage:button_accounts.imageView.image forState:UIControlStateNormal];
    }
    [scrollView addSubview:button_accounts];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)accountType:(UIButton *)sender {
    if(@available (iOS 14.0, *)) {
        // UIMenu
    } else {
        UIAlertController *fullAlert = [UIAlertController alertControllerWithTitle:@"Let's get you signed in." message:@"What account do you use to log into Minecraft?"preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *mojang = [UIAlertAction actionWithTitle:@"Mojang account" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginUsername:TYPE_MOJANG];}];
        UIAlertAction *microsoft = [UIAlertAction actionWithTitle:@"Microsoft account" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginMicrosoft];}];
        UIAlertAction *offline = [UIAlertAction actionWithTitle:@"Local account"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginOffline:sender];}];
        UIAlertAction *demo = [UIAlertAction actionWithTitle:@"Demo account" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginDemo:sender];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [self setPopoverProperties:fullAlert.popoverPresentationController sender:sender];
        [self presentViewController:fullAlert animated:YES completion:nil];
        [fullAlert addAction:microsoft];
        [fullAlert addAction:mojang];
        [fullAlert addAction:demo];
        [fullAlert addAction:offline];
        [fullAlert addAction:cancel];
    }
}

- (void)loginUsername:(int)type {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle: @"Login"
        message: @(type == TYPE_MOJANG ?
        "Account type: Mojang" : "Account type: Local")
        preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        if (type == TYPE_MOJANG) {
            textField.placeholder = @"Email or username";
        } else {
            textField.placeholder = @"Username";
        }
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    if (type == TYPE_MOJANG) {
        [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Password";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.secureTextEntry = YES;
        }];
    }
    [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = controller.textFields;
        UITextField *usernameField = textFields[0];

        const char *username = [usernameField.text UTF8String];
        if (type == TYPE_MOJANG) {
            [self loginMojangWithUsername:usernameField.text password:((UITextField *) textFields[1]).text];
        } else {
            if (usernameField.text.length < 3 || usernameField.text.length > 16) {
                controller.message = @"Username must be at least 3 characters and maximum 16 characters";
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    loginAccountInput(self.navigationController, TYPE_OFFLINE, username);
                });
            }
        }
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)loginMojang {
    [self loginUsername:TYPE_MOJANG];
}

- (void)loginMicrosoft {
    NSURL *url = [NSURL URLWithString:@"https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL&redirect_url=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf"];

    authVC =
        [[ASWebAuthenticationSession alloc] initWithURL:url
        callbackURLScheme:@"ms-xal-00000000402b5328"
        completionHandler:^(NSURL * _Nullable callbackURL,
        NSError * _Nullable error) {
            if (callbackURL != nil) {
                NSString *urlString = [callbackURL absoluteString];
                // NSLog(@"URL returned = %@", [callbackURL absoluteString]);

                if ([urlString containsString:@"/auth/?code="] == YES) {
                    NSArray *components = [urlString componentsSeparatedByString:@"/auth/?code="];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        loginAccountInput(self.navigationController, TYPE_MICROSOFT, [components[1] UTF8String]);
                    });
                } else {
                    NSArray *components = [urlString componentsSeparatedByString:@"/auth/?error="];
                    if ([components[1] hasPrefix:@"access_denied"] == NO) {
                        NSString *outError = [components[1]
                            stringByReplacingOccurrencesOfString:@"&error_description=" withString:@": "];
                        outError = [outError stringByRemovingPercentEncoding];
                        showDialog(self, @"Error", outError);
                    }
                }
            } else {
                if (error.code != ASWebAuthenticationSessionErrorCodeCanceledLogin) {
                    showDialog(self, @"Error", error.localizedDescription);
                }
            }
        }];

    if (@available(iOS 13.0, *)) {
        authVC.presentationContextProvider = self;
    }

    if ([authVC start] == NO) {
        showDialog(self, @"Error", @"Unable to open Safari");
    }
}

- (void)loginOffline:(UIButton *)sender {
    if ([getPreference(@"local_warn") boolValue] == YES) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:@"Offline mode is now Local mode." message:@"You can continue to play installed versions, but you can no longer download Minecraft without a paid account. No support will be provided for issues with local accounts, or other means of acquiring Minecraft. See our website for more information."preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self loginUsername:TYPE_OFFLINE];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
        [self presentViewController:offlineAlert animated:YES completion:nil];
        [offlineAlert addAction:ok];
        [offlineAlert addAction:cancel];
        setPreference(@"local_warn", @NO);
    } else {
        [self loginUsername:(TYPE_OFFLINE)];
    }
}

- (void)loginDemo:(UIButton *)sender {
    UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:@"This option is currently unavailable." message:@"It will be fully implemented in a future update." preferredStyle:UIAlertControllerStyleActionSheet];
    [self setPopoverProperties:offlineAlert.popoverPresentationController sender:sender];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self accountType:sender];}];
    [self presentViewController:offlineAlert animated:YES completion:nil];
    [offlineAlert addAction:ok];
}

- (void)loginAccount:(UIButton *)sender {
    LoginListViewController *vc = [[LoginListViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);
    
    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    [self setPopoverProperties:popoverController sender:sender];
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)loginMojangWithUsername:(NSString*)input_username password:(NSString*)input_password {
    NSString *input_uuid = [[NSUUID UUID] UUIDString];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:@"https://authserver.mojang.com/authenticate"];
    NSMutableURLRequest *request = 
      [[NSMutableURLRequest alloc] initWithURL:[NSURL
      URLWithString:@"https://authserver.mojang.com/authenticate"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSString *jsonString = [NSString stringWithFormat:@"{\"agent\": {\"name\": \"Minecraft\", \"version\": 1}, \"username\": \"%@\", \"password\": \"%@\", \"clientToken\": \"%@\"}", input_username, input_password, input_uuid];
    // NSLog(jsonString);
    [request setValue:[NSString stringWithFormat:@"%d",
      (int) [jsonString length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        long statusCode = (long)[httpResponse statusCode];

        NSString *dataStr = [NSString stringWithUTF8String:[data bytes]];
        

        // NSLog(@"status=%ld, data=%@, response=%@, error=%@", statusCode, dataStr, httpResponse, error);
        NSError *jsonError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

        if (jsonError != nil) {
            NSLog(@"Error parsing JSON: %@", jsonError.localizedDescription);
            showDialog(self, @"Error parsing JSON", jsonError.localizedDescription);
        } else if (statusCode == 200) {
            NSArray *selectedProfile = [jsonArray valueForKey:@"selectedProfile"];
            if (selectedProfile == nil) {
                // NSLog(@"DBG: can't login demo account!");
                showDialog(self, @"Error", @"Can't login a demo account!");
            } else {
/*
                NSString *out_accessToken = [jsonArray valueForKey:@"accessToken"];
                NSString *out_clientToken = [jsonArray valueForKey:@"clientToken"];
                NSString *out_profileID = [selectedProfile valueForKey:@"id"];
                NSString *out_username = [selectedProfile valueForKey:@"name"];
                NSLog(@"DBG: Login succeed: %@, %@, %@, %@", out_accessToken, out_clientToken, out_profileID, out_username);
*/
                
                loginAccountInput(self.navigationController, TYPE_MOJANG, [dataStr UTF8String]);
            }
        } else {
            NSString *err_title = [jsonArray valueForKey:@"error"];
            NSString *err_msg = [jsonArray valueForKey:@"errorMessage"];
            // NSLog(@"DBG Error: %@: %@", err_title, err_msg);
            showDialog(self, err_title, err_msg);
        }
    }];
    [postDataTask resume];
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
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/Documents/.pojavlauncher/latestlog.old.txt", getenv("HOME")];
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]] applicationActivities:nil];

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

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - ASWebAuthenticationPresentationContextProviding
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session  API_AVAILABLE(ios(13.0)){
    return UIApplication.sharedApplication.windows.firstObject;
}

@end

#pragma mark - LoginListViewController
@interface LoginListViewController () {
}

@property(nonatomic, strong) NSMutableArray *accountList;

@end

@implementation LoginListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"Select account"];

    if (self.accountList == nil) {
        self.accountList = [NSMutableArray array];
    } else {
        [self.accountList removeAllObjects];
    }
    
    // List accounts
    // TODO: convert to objc
    DIR *d;
    struct dirent *dir;
    char accPath[2048];
    sprintf(accPath, "%s/accounts", getenv("POJAV_HOME"));
    d = opendir(accPath);
    if (d) {
        int i = 0;
        while ((dir = readdir(d)) != NULL) {
            // Skip "." and ".."
            if (i < 2) {
                i++;
                continue;
            } else if ([@(dir->d_name) hasSuffix:@".json"]) {
                NSString *trimmedName= [@(dir->d_name) substringToIndex:((int)[@(dir->d_name) length] - 5)];
                [self.accountList addObject:trimmedName];
            }
        }
        closedir(d);
    }

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.accountList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *simpleTableIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
 
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
 
    cell.textLabel.text = [self.accountList objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];

    NSString *str = [self.accountList objectAtIndex:indexPath.row];
    loginAccountInput((UINavigationController *)self.presentingViewController, TYPE_SELECTACC, [str UTF8String]);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *str = [self.accountList objectAtIndex:indexPath.row];
        char accPath[2048];
        sprintf(accPath, "%s/accounts/%s.json", getenv("POJAV_HOME"), [str UTF8String]);
        remove(accPath);
        [self.accountList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
