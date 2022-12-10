#import <SafariServices/SafariServices.h>

#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "AFNetworking.h"
#import "ALTServerConnection.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

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
@property(nonatomic) UIButton *accountButton;
@property(nonatomic) UIBarButtonItem *accountBtnItem;
@property(nonatomic) UILabel *statusLabel;
@end

@implementation LauncherMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppLogo"]];
    [titleView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = titleView;
    [titleView sizeToFit];

    // View controllers are put into an array to keep its state
    self.options = @[
        [[LauncherNewsViewController alloc] init],
        [[LauncherPreferencesViewController alloc] init],
        [LauncherMenuCustomItem
            title:localize(@"launcher.menu.custom_controls", nil)
            imageName:@"MenuCustomControls" action:^{
            [self restoreHighlightedSelection];
            [self.splitViewController.viewControllers[1] performSelector:@selector(enterCustomControls)];
        }],
        [LauncherMenuCustomItem
            title:localize(@"launcher.menu.install_jar", nil)
            imageName:@"MenuInstallJar" action:^{
            [self restoreHighlightedSelection];
            [self.splitViewController.viewControllers[1] performSelector:@selector(enterModInstaller)];
        }],
        [LauncherMenuCustomItem
            title:localize(@"login.menu.sendlogs", nil)
            imageName:@"square.and.arrow.up" action:^{
            [self restoreHighlightedSelection];
            NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
            NSLog(@"Path is %@", latestlogPath);
            UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]]
                applicationActivities:nil];
            activityVC.popoverPresentationController.sourceView = titleView;
            activityVC.popoverPresentationController.sourceRect = titleView.bounds;

            [self presentViewController:activityVC animated:YES completion:nil];
        }]
    ].mutableCopy;
    self.options[0].title = localize(@"News", nil);
    self.options[1].title = localize(@"Settings", nil);

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM-dd";
    NSString* date = [dateFormatter stringFromDate:NSDate.date];
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        [self.options addObject:(id)[LauncherMenuCustomItem
            title:@"Technoblade never dies!"
            imageName:@"" action:^{
            SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://youtu.be/DPMluEVUqS0"]];
            [self presentViewController:vc animated:YES completion:nil];
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
    self.accountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.accountButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventTouchUpInside];
    self.accountButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.accountButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    self.accountButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.accountButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.accountBtnItem = [[UIBarButtonItem alloc] initWithCustomView:self.accountButton];

    [self updateAccountInfo];

    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    if (!getEntitlementValue(@"dynamic-codesigning")) {
        if (isJITEnabled()) {
            [self displayProgress:localize(@"login.jit.enabled", nil)];
            [self displayProgress:nil];
        } else {
            [self enableJITWithJitStreamer];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self restoreHighlightedSelection];
}

- (void)restoreHighlightedSelection {
    // workaround while investigating for issue
    if (self.splitViewController.viewControllers.count < 2) return;

    // Restore the selected row when the view appears again
    int index = [self.options indexOfObject:[self.splitViewController.viewControllers[1] viewControllers][0]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
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
    //cell.imageView.contentMode = UIViewContentModeScaleToFill;
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:[self.options[indexPath.row]
            performSelector:@selector(imageName)]];
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
        [self.splitViewController.viewControllers[1] setViewControllers:@[selected] animated:NO]; //YES?

        if (@available(iOS 14.0, tvOS 14.0, *)) {
            selected.navigationItem.leftBarButtonItem = self.accountBtnItem;
            // It is unnecessary to put the toggle button as it is automated on iOS 14+
            return;
        }
        selected.navigationItem.leftBarButtonItems = @[self.splitViewController.displayModeButtonItem, self.accountBtnItem];
        selected.navigationItem.leftItemsSupplementBackButton = true;
    } else {
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
            [sender sendActionsForControlEvents:UIControlEventTouchUpInside];
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

    if (selected == nil) {
        [self.accountButton setAttributedTitle:[[NSAttributedString alloc] initWithString:localize(@"login.option.select", nil)] forState:UIControlStateNormal];
        [self.accountButton setImage:[UIImage imageNamed:@"DefaultAccount"] forState:UIControlStateNormal];
        [self.accountButton sizeToFit];
        return;
    }

    BOOL isDemo = [selected[@"username"] hasPrefix:@"Demo."];
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[selected[@"username"] substringFromIndex:(isDemo?5:0)]];
    id subtitle;
    if (isDemo) {
        // Remove the prefix "Demo."
        subtitle = localize(@"login.option.demo", nil);
    } else if (selected[@"xboxGamertag"] == nil) {
        subtitle = localize(@"login.option.local", nil);
    } else {
        // Display the Xbox gamertag for online accounts
        subtitle = selected[@"xboxGamertag"];
    }
    subtitle = [[NSAttributedString alloc] initWithString:subtitle attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
    [title appendAttributedString:subtitle];
    [self.accountButton setAttributedTitle:title forState:UIControlStateNormal];

    NSURL *url = [NSURL URLWithString:[selected[@"profilePicURL"] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]];
    UIImage *placeholder = [UIImage imageNamed:@"DefaultAccount"];
    [self.accountButton setImageForState:UIControlStateNormal withURL:url placeholderImage:placeholder];
    [self.accountButton.imageView setImageWithURL:url placeholderImage:placeholder];
    [self.accountButton sizeToFit];
}

- (void)displayProgress:(NSString *)status {
    if (status == nil) {
        [(UIActivityIndicatorView *)self.toolbarItems[0].customView stopAnimating];
        return;
    }
    self.toolbarItems[1].title = status;
}

- (void)enableJITWithAltJIT
{
    [self displayProgress:localize(@"login.jit.start.AltKit", nil)];
    [ALTServerManager.sharedManager startDiscovering];
    [ALTServerManager.sharedManager autoconnectWithCompletionHandler:^(ALTServerConnection *connection, NSError *error) {
        if (error) {
            NSLog(@"[AltKit] Could not auto-connect to server. %@", error);
            [self displayProgress:localize(@"login.jit.fail.AltKit", nil)];
            [self displayProgress:nil];
            return;
        }
        [connection enableUnsignedCodeExecutionWithCompletionHandler:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"[AltKit] Successfully enabled JIT compilation!");
                [ALTServerManager.sharedManager stopDiscovering];
                [self displayProgress:localize(@"login.jit.enabled", nil)];
                [self displayProgress:nil];
            } else {
                NSLog(@"[AltKit] Could not enable JIT compilation. %@", error);
                [self displayProgress:localize(@"login.jit.fail.AltKit", nil)];
                [self displayProgress:nil];
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
    NSLog(@"JitStreamer server is %@, attempting to connect...", address);

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer = AFHTTPResponseSerializer.serializer;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    [manager GET:[NSString stringWithFormat:@"http://%@/version", address] parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSData *response) {
        NSString *version = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"Found JitStreamer %@", version);
        [self displayProgress:localize(@"login.jit.found.JitStreamer", nil)];
        manager.requestSerializer.timeoutInterval = 0;
        manager.responseSerializer = AFJSONResponseSerializer.serializer;
        void(^handleResponse)(NSURLSessionDataTask *task, id response) = ^void(NSURLSessionDataTask *task, id response){
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
                [self displayProgress:localize(@"login.jit.enabled", nil)];
                [self displayProgress:nil];
            } else {
                [self displayProgress:[NSString stringWithFormat:localize(@"login.jit.fail.JitStreamer", nil), responseDict[@"message"]]];
                showDialog(self, localize(@"Error", nil), responseDict[@"message"]);
                [self enableJITWithAltJIT];
            }
        };
        [manager POST:[NSString stringWithFormat:@"http://%@/attach/%d/", address, getpid()] parameters:nil headers:nil progress:nil success:handleResponse failure:handleResponse];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self enableJITWithAltJIT];
    }];
}

@end
