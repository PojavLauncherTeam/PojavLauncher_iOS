#include <dirent.h>
#include <stdio.h>

#import <AuthenticationServices/AuthenticationServices.h>

#import "AppDelegate.h"
#import "LauncherViewController.h"
#import "LoginViewController.h"

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
        dispatch_async(dispatch_get_main_queue(), ^{
            LauncherViewController *vc = [[LauncherViewController alloc] init];
            [controller pushViewController:vc animated:YES];
        });
    }
}

#pragma mark - LoginViewController
@interface LoginViewController () <ASWebAuthenticationPresentationContextProviding>{
}
@property (nonatomic, strong) ASWebAuthenticationSession *authVC;
@end

@implementation LoginViewController
@synthesize authVC;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    [self setTitle:@"PojavLauncher"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msaLoginCallback:) name:@"MSALoginCallback" object:nil];

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:scrollView];

    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    CGFloat widthSplit = width / 4.0;
    
    UIButton *button_login_mojang = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_mojang setTitle:@"Mojang login" forState:UIControlStateNormal];
    button_login_mojang.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 - 4.0 - 50.0, (width - widthSplit * 2.0) / 2 - 2.0, 50.0);
    button_login_mojang.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_mojang.layer.cornerRadius = 5;
    [button_login_mojang setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_mojang addTarget:self action:@selector(loginMojang) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_mojang];
    
    UIButton *button_login_microsoft = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_microsoft setTitle:@"Microsoft login" forState:UIControlStateNormal];
    button_login_microsoft.frame = CGRectMake(widthSplit + (width - widthSplit * 2.0) / 2.0 + 2.0, (height - 50.0) / 2.0 - 4.0 - 50.0, (width - widthSplit * 2.0) / 2 - 2.0, 50.0);
    button_login_microsoft.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_microsoft.layer.cornerRadius = 5;
    [button_login_microsoft setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_microsoft addTarget:self action:@selector(loginMicrosoft) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_microsoft];
    
    UIButton *button_login_offline = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_offline setTitle:@"Offline login" forState:UIControlStateNormal];
    button_login_offline.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0, width - widthSplit * 2.0, 50.0);
    button_login_offline.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_offline.layer.cornerRadius = 5;
    [button_login_offline setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_offline addTarget:self action:@selector(loginOffline) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_offline];

    UIButton *button_login_account = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_account setTitle:@"Select account" forState:UIControlStateNormal];
    button_login_account.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 + 4.0 + 50.0, width - widthSplit * 2.0, 50.0);
    button_login_account.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_account.layer.cornerRadius = 5;
    [button_login_account setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_account addTarget:self action:@selector(loginAccount) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_account];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(13.0)) {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)loginUsername:(int)type {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle: @"Login"
        message: @(type == TYPE_MOJANG ?
        "Account type: Mojang" : "Account type: Offline")
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
                NSLog(@"URL returned = %@", [callbackURL absoluteString]);

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

- (void)loginOffline {
    [self loginUsername:TYPE_OFFLINE];
}

- (void)loginAccount {
    LoginListViewController *vc = [[LoginListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
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
      [jsonString length]] forHTTPHeaderField:@"Content-length"];
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

#pragma mark - ASWebAuthenticationPresentationContextProviding
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session  API_AVAILABLE(ios(13.0)){
    return UIApplication.sharedApplication.keyWindow;
}

@end

#pragma mark - LoginListViewController
@interface LoginListViewController () {
}

@end

@implementation LoginListViewController

NSMutableArray *accountList;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"Select account"];

    if (accountList == nil) {
        accountList = [NSMutableArray array];
    } else {
        [accountList removeAllObjects];
    }
    
    // List accounts
    DIR *d;
    struct dirent *dir;
    d = opendir("/var/mobile/Documents/.pojavlauncher/accounts");
    if (d) {
        int i = 0;
        while ((dir = readdir(d)) != NULL) {
            // Skip "." and ".."
            if (i < 2) {
                i++;
                continue;
            } else if ([@(dir->d_name) hasSuffix:@".json"]) {
                NSString *trimmedName= [@(dir->d_name) substringToIndex:((int)[@(dir->d_name) length] - 5)];
                [accountList addObject:trimmedName];
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
    return [accountList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *simpleTableIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
 
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
 
    cell.textLabel.text = [accountList objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *str = [accountList objectAtIndex:indexPath.row];
    loginAccountInput(self.navigationController, TYPE_SELECTACC, [str UTF8String]);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *str = [accountList objectAtIndex:indexPath.row];
        char accPath[1024];
        sprintf(accPath, "/var/mobile/Documents/.pojavlauncher/accounts/%s.json", [str UTF8String]);
        remove(accPath);
        [accountList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }    
}

@end
