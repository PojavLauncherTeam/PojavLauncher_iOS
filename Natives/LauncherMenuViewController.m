#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferencesViewController2.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface LauncherMenuViewController () {
}

@property NSArray<UIViewController*> *options;
@end

@implementation LauncherMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // View controllers are put into an array to keep its state
    self.options = @[
        [[LauncherNewsViewController alloc] init],
        [[LauncherPreferencesViewController2 alloc] init]
    ];
    self.options[0].title = NSLocalizedString(@"News", nil);
    self.options[1].title = NSLocalizedString(@"Settings", nil);
    //@[@"News", @"Development Console", @"Crash logs"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventTouchUpInside];
    titleButton.frame = self.navigationController.navigationBar.frame;
    titleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        // On iOS 14+, a special button is displayed to toggle the visibility of the master view controller.
        // It creates a bit more offset while in the process of swipe/animation. Therefore the left inset
        // has to be increased a bit for this button.
        titleButton.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 8);
    } else {
        titleButton.contentEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 8);
    } 
    titleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    titleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    titleButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.navigationItem.titleView = titleButton;

    [self updateAccountInfo];
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *selected = self.options[indexPath.row];
    [self.splitViewController.viewControllers[1] setViewControllers:@[selected] animated:NO]; //YES?

    if (@available(iOS 14.0, tvOS 14.0, *)) {
        // It is unnecessary to put the toggle button as it is automated on iOS 14+
    } else {
        selected.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        selected.navigationItem.leftItemsSupplementBackButton = true;
    }

    // Put a close button, as iOS does not have a dedicated back button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"❌" style:UIBarButtonItemStyleDone target:self.splitViewController action:@selector(dismissViewController)];
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
        subtitle = NSLocalizedString(@"login.option.demo", nil);
    } else if (selected[@"xboxGamertag"] == nil) {
        subtitle = NSLocalizedString(@"login.option.local", nil);
    } else {
        // Display the Xbox gamertag for online accounts
        subtitle = selected[@"xboxGamertag"];
    }
    subtitle = [[NSAttributedString alloc] initWithString:subtitle attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
    [title appendAttributedString:subtitle];
    [(UIButton *)self.navigationItem.titleView setAttributedTitle:title forState:UIControlStateNormal];

    NSURL *url = [NSURL URLWithString:[selected[@"profilePicURL"] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]];
    UIImage *placeholder = [UIImage imageNamed:@"default_account_pfp"];
    [(UIButton *)self.navigationItem.titleView setImageForState:UIControlStateNormal withURL:url placeholderImage:placeholder];
    [((UIButton *)self.navigationItem.titleView).imageView setImageWithURL:url placeholderImage:placeholder];
}

@end
