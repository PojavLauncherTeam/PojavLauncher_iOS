#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "AFNetworking.h"
#import "ALTServerConnection.h"
#import "LauncherNavigationController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "UIKit+hook.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include <dlfcn.h>

@implementation LauncherMenuCustomItem

+ (LauncherMenuCustomItem *)title:(NSString *)title imageName:(NSString *)imageName action:(id)action {
    LauncherMenuCustomItem *item = [[LauncherMenuCustomItem alloc] init];
    item.title = title;
    item.imageName = imageName;
    item.action = action;
    return item;
}

@end

@interface LauncherMenuViewController()
@property(nonatomic) NSMutableArray<UIViewController*> *options;
@property(nonatomic) UILabel *statusLabel;
@end

@implementation LauncherMenuViewController

#define contentNavigationController ((LauncherNavigationController *)self.splitViewController.viewControllers[1])

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isInitialVc = YES;

    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppLogo"]];
    [titleView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = titleView;
    [titleView sizeToFit];

    // View controllers are put into an array to keep its state
    self.options = NSMutableArray.new;
    [self.options addObject:LauncherNewsViewController.new];
    self.options[0].title = localize(@"News", nil);
    [self.options addObject:LauncherPreferencesViewController.new];
    self.options[1].title = localize(@"Settings", nil);
    if (realUIIdiom != UIUserInterfaceIdiomTV) {
        [self.options addObject:(id)[LauncherMenuCustomItem
            title:localize(@"launcher.menu.custom_controls", nil)
            imageName:@"MenuCustomControls" action:^{
            [contentNavigationController performSelector:@selector(enterCustomControls)];
        }]];
    }
    [self.options addObject:
        (id)[LauncherMenuCustomItem
            title:localize(@"launcher.menu.install_jar", nil)
            imageName:@"MenuInstallJar" action:^{
            [contentNavigationController performSelector:@selector(enterModInstaller)];
        }]];

    // TODO: Finish log-uploading service integration
    [self.options addObject:
        (id)[LauncherMenuCustomItem
            title:localize(@"login.menu.sendlogs", nil)
            imageName:@"square.and.arrow.up" action:^{
            NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
            NSLog(@"Path is %@", latestlogPath);
            UIActivityViewController *activityVC;
            if (realUIIdiom != UIUserInterfaceIdiomTV) {
                activityVC = [[UIActivityViewController alloc]
                    initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]]
                    applicationActivities:nil];
            } else {
                dlopen("/System/Library/PrivateFrameworks/SharingUI.framework/SharingUI", RTLD_GLOBAL);
                activityVC =
                    [[NSClassFromString(@"SFAirDropSharingViewControllerTV") alloc]
                    performSelector:@selector(initWithSharingItems:)
                    withObject:@[[NSURL URLWithString:latestlogPath]]];
            }
            activityVC.popoverPresentationController.sourceView = titleView;
            activityVC.popoverPresentationController.sourceRect = titleView.bounds;
            [self presentViewController:activityVC animated:YES completion:nil];
        }]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM-dd";
    NSString* date = [dateFormatter stringFromDate:NSDate.date];
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        [self.options addObject:(id)[LauncherMenuCustomItem
            title:@"Technoblade never dies!"
            imageName:@"" action:^{
            openLink(self, [NSURL URLWithString:@"https://youtu.be/DPMluEVUqS0"]);
        }]];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.navigationController.toolbarHidden = NO;
    UIActivityIndicatorViewStyle indicatorStyle;
    if (@available(iOS 13.0, *)) {
        indicatorStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicatorStyle = UIActivityIndicatorViewStyleGray;
    }
    UIActivityIndicatorView *toolbarIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    [toolbarIndicator startAnimating];
    self.toolbarItems = @[
        [[UIBarButtonItem alloc] initWithCustomView:toolbarIndicator],
        [[UIBarButtonItem alloc] init]
    ];
    if (@available(iOS 13.0, *)) {
        self.toolbarItems[1].tintColor = UIColor.labelColor;
    } else {
        self.toolbarItems[1].tintColor = UIColor.blackColor;
    }

    // Setup the account button
    self.accountBtnItem = [self drawAccountButton];

    [self updateAccountInfo];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
    if (!getEntitlementValue(@"dynamic-codesigning")) {
        if (isJITEnabled(false)) {
            [self displayProgress:localize(@"login.jit.enabled", nil)];
            [self displayProgress:nil];
        } else {
            [self enableJITWithJitStreamer:[getPreference(@"enable_altkit") boolValue]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self restoreHighlightedSelection];
}

- (UIBarButtonItem *)drawAccountButton {
    self.accountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.accountButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventPrimaryActionTriggered];
    self.accountButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.accountButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    self.accountButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.accountButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.accountBtnItem = [[UIBarButtonItem alloc] initWithCustomView:self.accountButton];

    [self updateAccountInfo];
    
    return self.accountBtnItem;
}

- (void)restoreHighlightedSelection {

    // Restore the selected row when the view appears again
    int index = [self.options indexOfObject:[contentNavigationController viewControllers][0]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:MAX(0, index) inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    cell.textLabel.text = [self.options[indexPath.row] title];
    if (@available(iOS 13.0, *)) {
        UIImage *origImage = [UIImage systemImageNamed:[self.options[indexPath.row]
            performSelector:@selector(imageName)]];
        if (origImage) {
            UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(50, 50)];
            UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext*_Nonnull myContext) {
                CGFloat scaleFactor = 50/origImage.size.height;
                [origImage drawInRect:CGRectMake(25 - origImage.size.width*scaleFactor/2, 0, origImage.size.width*scaleFactor, 50)];
            }];
            cell.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    if (cell.imageView.image == nil) {
        cell.imageView.layer.magnificationFilter = kCAFilterNearest;
        cell.imageView.layer.minificationFilter = kCAFilterNearest;
        cell.imageView.image = [UIImage imageNamed:[self.options[indexPath.row]
            performSelector:@selector(imageName)]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *selected = self.options[indexPath.row];
    
    if ([selected isKindOfClass:UIViewController.class]) {
        if(self.isInitialVc) {
            self.isInitialVc = NO;
        } else {
            [contentNavigationController setViewControllers:@[selected] animated:NO];
        }
        
        if([self.options[indexPath.row].title isEqualToString:localize(@"Settings", nil)]) {
            LauncherPreferencesViewController *vc = (LauncherPreferencesViewController *)selected;
            selected.navigationItem.rightBarButtonItems = @[self.accountBtnItem, [vc drawHelpButton]];
        } else {
            selected.navigationItem.rightBarButtonItem = self.accountBtnItem;
        }
        
        selected.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        selected.navigationItem.leftItemsSupplementBackButton = true;
    } else {
        [self restoreHighlightedSelection];
        ((LauncherMenuCustomItem *)selected).action();
    }
}

- (void)selectAccount:(UIButton *)sender {
    AccountListViewController *vc = [[AccountListViewController alloc] init];
    vc.whenDelete = ^void(NSString* name) {
        if ([name isEqualToString:getPreference(@"selected_account")]) {
            BaseAuthenticator.current = nil;
            setPreference(@"selected_account", @"");
            [self updateAccountInfo];
        }
    };
    vc.whenItemSelected = ^void() {
        setPreference(@"selected_account", BaseAuthenticator.current.authData[@"username"]);
        [self updateAccountInfo];
        if (sender != self.accountButton) {
            // Called from the play button, so call back to continue
            [sender sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
        }
    };
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);

    UIPopoverPresentationController *popoverController = vc.popoverPresentationController;
    popoverController.sourceView = sender;
    popoverController.sourceRect = sender.bounds;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = vc;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)updateAccountInfo {
    NSDictionary *selected = BaseAuthenticator.current.authData;
    CGSize size = CGSizeMake(contentNavigationController.view.frame.size.width, contentNavigationController.view.frame.size.height);
    
    if (selected == nil) {
        if((size.width / 3) > 200) {
            [self.accountButton setAttributedTitle:[[NSAttributedString alloc] initWithString:localize(@"login.option.select", nil)] forState:UIControlStateNormal];
        } else {
            [self.accountButton setAttributedTitle:(NSAttributedString *)@"" forState:UIControlStateNormal];
        }
        [self.accountButton setImage:[UIImage imageNamed:@"DefaultAccount"] forState:UIControlStateNormal];
        [self.accountButton sizeToFit];
        return;
    }

    // Remove the prefix "Demo." if there is
    BOOL isDemo = [selected[@"username"] hasPrefix:@"Demo."];
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[selected[@"username"] substringFromIndex:(isDemo?5:0)]];

    // Reset states
    unsetenv("DEMO_LOCK");
    setenv("POJAV_GAME_DIR", [NSString stringWithFormat:@"%s/Library/Application Support/minecraft", getenv("POJAV_HOME")].UTF8String, 1);

    
    id subtitle;
    if (isDemo) {
        subtitle = localize(@"login.option.demo", nil);
        setenv("DEMO_LOCK", "1", 1);
        setenv("POJAV_GAME_DIR", [NSString stringWithFormat:@"%s/.demo", getenv("POJAV_HOME")].UTF8String, 1);
    } else if (selected[@"xboxGamertag"] == nil) {
        subtitle = localize(@"login.option.local", nil);
    } else {
        // Display the Xbox gamertag for online accounts
        subtitle = selected[@"xboxGamertag"];
    }

    subtitle = [[NSAttributedString alloc] initWithString:subtitle attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
    [title appendAttributedString:subtitle];
    
    if((size.width / 3) > 200) {
        [self.accountButton setAttributedTitle:title forState:UIControlStateNormal];
    } else {
        [self.accountButton setAttributedTitle:(NSAttributedString *)@"" forState:UIControlStateNormal];
    }
    
    // TODO: Add caching mechanism for profile pictures
    NSURL *url = [NSURL URLWithString:[selected[@"profilePicURL"] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]];
    UIImage *placeholder = [UIImage imageNamed:@"DefaultAccount"];
    [self.accountButton setImageForState:UIControlStateNormal withURL:url placeholderImage:placeholder];
    [self.accountButton.imageView setImageWithURL:url placeholderImage:placeholder];
    [self.accountButton sizeToFit];

    // Update the version list, only if the selected type is Installed
    int selectedVersionType = [getPreference(@"selected_version_type") intValue];
    if (selectedVersionType == 0) {
        [contentNavigationController reloadVersionList:0];
    }
}

- (void)displayProgress:(NSString *)status {
    if (status == nil) {
        [(UIActivityIndicatorView *)self.toolbarItems[0].customView stopAnimating];
    } else {
        self.toolbarItems[1].title = status;
    }
}

- (void)enableJITWithAltKit
{
    [ALTServerManager.sharedManager startDiscovering];
    [ALTServerManager.sharedManager autoconnectWithCompletionHandler:^(ALTServerConnection *connection, NSError *error) {
        if (error) {
            NSLog(@"[AltKit] Could not auto-connect to server. %@", error.localizedRecoverySuggestion);
        }
        [connection enableUnsignedCodeExecutionWithCompletionHandler:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"[AltKit] Successfully enabled JIT compilation!");
                [ALTServerManager.sharedManager stopDiscovering];
            } else {
                NSLog(@"[AltKit] Error enabling JIT: %@", error.localizedRecoverySuggestion);
                showDialog(self, localize(@"login.jit.fail.title", nil), localize(@"login.jit.fail.description", nil));
            }
            [connection disconnect];
        }];
    }];
}

- (void)enableJITWithJitStreamer:(BOOL)shouldRunAltKit
{
    [self displayProgress:localize(@"login.jit.checking", nil)];

    // TODO: customizable address
    NSString *address = getPreference(@"jitstreamer_server");
    NSLog(@"[JitStreamer] Server is %@, attempting to connect...", address);

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer = AFHTTPResponseSerializer.serializer;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    [manager GET:[NSString stringWithFormat:@"http://%@/version", address] parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSData *response) {
        NSString *version = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"[JitStreamer] Found JitStreamer %@", version);
        manager.requestSerializer.timeoutInterval = 0;
        manager.responseSerializer = AFJSONResponseSerializer.serializer;
        void(^handleResponse)(NSURLSessionDataTask *task, id response) = ^void(NSURLSessionDataTask *task, id response){
            NSDictionary *responseDict;
            // FIXME: successful response may fail due to serialization issues
            if ([response isKindOfClass:NSError.class]) {
                NSDebugLog(@"Error?: %@", responseDict);
                NSData *errorData = ((NSError *)response).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                responseDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
            } else {
                responseDict = response;
            }
            if ([responseDict[@"success"] boolValue]) {
                [self displayProgress:localize(@"login.jit.enabled", nil)];
                [self displayProgress:nil];
            } else {
                NSLog(@"[JitStreamer] Error enabling JIT: %@", responseDict[@"message"]);
                if(shouldRunAltKit) { [self enableJITWithAltKit]; }
                else { showDialog(self, localize(@"login.jit.fail.title", nil), localize(@"login.jit.fail.description", nil)); }
            }
        };
        [manager POST:[NSString stringWithFormat:@"http://%@/attach/%d/", address, getpid()] parameters:nil headers:nil progress:nil success:handleResponse failure:handleResponse];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[JitStreamer] Server not found or VPN not connected.");
        if(shouldRunAltKit) { [self enableJITWithAltKit]; }
        else { showDialog(self, localize(@"login.jit.fail.title", nil), localize(@"login.jit.fail.description", nil)); }
    }];
}

@end
