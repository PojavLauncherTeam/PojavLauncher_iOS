#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferencesViewController.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+AFNetworking.h"
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
@property(nonatomic) NSArray<UIViewController*> *options;
@property(nonatomic) UIButton *accountButton;
@property(nonatomic) UIBarButtonItem *accountBtnItem;
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
    ]; 
    self.options[0].title = localize(@"News", nil);
    self.options[1].title = localize(@"Settings", nil);

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

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

    // Put a close button, as iOS does not have a dedicated back button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"❌" style:UIBarButtonItemStyleDone target:self.splitViewController action:@selector(dismissViewController)];
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
    vc.whenItemSelected = ^void(NSString* name) {
        // TODO: perform token refreshing
        [BaseAuthenticator loadSavedName:name];
        [self updateAccountInfo];
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

@end
