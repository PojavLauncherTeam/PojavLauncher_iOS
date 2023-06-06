#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefManageJREViewController.h"
#import "NSFileManager+NRFileManager.h"
#import "UIKit+hook.h"
#import "utils.h"
#include <objc/runtime.h>

// 0 is reserved for default pickers
// INT_MAX is reserved for invalid runtimes
#define DEFAULT_JRE 0
#define INVALID_JRE INT_MAX

@interface LauncherPrefManageJREViewController ()<UIContextMenuInteractionDelegate>
@property(nonatomic) NSMutableDictionary<NSNumber *, NSMutableArray *> *javaRuntimes;
@property(nonatomic) NSMutableArray<NSNumber *> *sortedJavaVersions;
@property(nonatomic) NSArray<NSString *> *selectedRTTags;
@property(nonatomic) NSMutableDictionary<NSString *, NSString *> *selectedRuntimes;
@property(nonatomic) UIMenu* currentMenu;
@end

@implementation LauncherPrefManageJREViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:localize(@"preference.title.manage_runtime", nil)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    self.javaRuntimes = @{
        @(DEFAULT_JRE): @[@"preference.manage_runtime.default.1165", @"preference.manage_runtime.default.117", @"launcher.menu.install_jar"]
    }.mutableCopy;
    self.sortedJavaVersions = @[@(DEFAULT_JRE)].mutableCopy;

    self.selectedRTTags = @[@"1_16_5_older", @"1_17_newer", @"install_jar"];
    self.selectedRuntimes = getPreference(@"java_homes");

    NSString *internalPath = [NSString stringWithFormat:@"%s/java_runtimes", getenv("BUNDLE_PATH")];
    NSString *externalPath = [NSString stringWithFormat:@"%s/java_runtimes", getenv("POJAV_HOME")];
    [self listJREInPath:internalPath markInternal:YES];
    [self listJREInPath:externalPath markInternal:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sortedJavaVersions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSNumber *version = self.sortedJavaVersions[section];
    switch (self.sortedJavaVersions[section].intValue) {
        case DEFAULT_JRE: return localize(@"preference.manage_runtime.header.default", nil);
        case INVALID_JRE: return localize(@"preference.manage_runtime.header.invalid", nil);
        default: return [NSString stringWithFormat:@"Java %@", self.sortedJavaVersions[section]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (self.sortedJavaVersions[section].intValue) {
        case DEFAULT_JRE: return localize(@"preference.manage_runtime.footer.default", nil);
        case 8: return localize(@"preference.manage_runtime.footer.java8", nil);
        case 17: return localize(@"preference.manage_runtime.footer.java17", nil);
        default: return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.javaRuntimes[self.sortedJavaVersions[section]].count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: return [self tableView:tableView cellForDefaultRowAtIndexPath:indexPath];
        default: return [self tableView:tableView cellForRuntimeRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForDefaultRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DefaultCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = localize(self.javaRuntimes[@DEFAULT_JRE][indexPath.row], nil);
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Java %@",
        ((NSDictionary *)self.selectedRuntimes[@"0"])[self.selectedRTTags[indexPath.row]]];
    return cell;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRuntimeRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RTCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"RTCell"];
    }
    NSNumber *version = self.sortedJavaVersions[indexPath.section];
    NSString *name = self.javaRuntimes[version][indexPath.row];
    BOOL isInternal = [objc_getAssociatedObject(name, @"internalJRE") boolValue];
    if (isInternal) {
        cell.textLabel.text = [NSString stringWithFormat:@"[Internal] %@", name];
    } else {
        cell.textLabel.text = name;
    }

    // Set checkmark; with internal runtime it's a bit tricky to check
    if ([self.selectedRuntimes[version.stringValue] isEqualToString:name] ||
      (isInternal && [self.selectedRuntimes[version.stringValue] isEqualToString:@"internal"])) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Display size
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        unsigned long long folderSize = 0;
        NSString *directory = [NSString stringWithFormat:@"%s/java_runtimes/%@",
            getenv(isInternal ? "BUNDLE_PATH" : "POJAV_HOME"),
            name];
        [NSFileManager.defaultManager nr_getAllocatedSize:&folderSize ofDirectoryAtURL:[NSURL fileURLWithPath:directory] error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                [self javaVersionForPath:directory],
                [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleMemory]];
        });
    });

    /*
    if ([getPreference(@"game_directory") isEqualToString:self.array[indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
*/
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        [self tableView:tableView openPickerAtIndexPath:indexPath
            minVersion:(indexPath.row==1 ? 17 : 8)];
        return;
    } else if (self.sortedJavaVersions[indexPath.section].intValue == INVALID_JRE) {
        // TODO: do something, like alert explaining that the runtime has missing files
        return;
    }

    // Update preference
    NSNumber *version = self.sortedJavaVersions[indexPath.section];
    NSString *name = self.javaRuntimes[version][indexPath.row];
    BOOL isInternal = [objc_getAssociatedObject(name, @"internalJRE") boolValue];
    if (isInternal) {
        self.selectedRuntimes[version.stringValue] = @"internal";
    } else {
        self.selectedRuntimes[version.stringValue] = name;
    }
    setPreference(@"java_homes", self.selectedRuntimes);

    // Update checkmark
    NSInteger runtimeCount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    for (int i = 0; i < runtimeCount; i++) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        if (i == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark Context Menu configuration

- (void)tableView:(UITableView *)tableView openPickerAtIndexPath:(NSIndexPath *)indexPath minVersion:(NSInteger)minVer {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];

    NSMutableArray *menuItems = [NSMutableArray new];
    for (int i = 1; i < self.sortedJavaVersions.count; i++) {
        if (self.sortedJavaVersions[i].intValue < minVer ||
            self.sortedJavaVersions[i].intValue == INVALID_JRE) {
            continue;
        }
        NSString *version = [self tableView:tableView titleForHeaderInSection:i];
        [menuItems addObject:[UIAction
            actionWithTitle:version
            image:nil
            identifier:nil
            handler:^(UIAction *action) {
                cell.detailTextLabel.text = version;
                ((NSMutableDictionary *)self.selectedRuntimes[@"0"])[self.selectedRTTags[indexPath.row]] = self.sortedJavaVersions[i].stringValue;
                setPreference(@"java_homes", self.selectedRuntimes);
            }]];
    }

    cell.detailTextLabel.interactions = [NSArray new];

    if (menuItems.count == 0) {
        [menuItems addObject:[UIAction
            actionWithTitle:localize(@"None", nil)
            image:nil
            identifier:nil
            handler:^(UIAction *action){}]];
    }

    self.currentMenu = [UIMenu menuWithTitle:cell.textLabel.text children:menuItems];
    UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [cell.detailTextLabel addInteraction:interaction];
    [interaction _presentMenuAtLocation:CGPointZero];
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location
{
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        return self.currentMenu;
    }];
}

- (_UIContextMenuStyle *)_contextMenuInteraction:(UIContextMenuInteraction *)interaction
styleForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
{
    _UIContextMenuStyle *style = [_UIContextMenuStyle defaultStyle];
    style.preferredLayout = 3; // _UIContextMenuLayoutCompactMenu
    return style;
}

#pragma mark Version parser

- (NSString *)javaVersionForPath:(NSString *)path {
    path = [path stringByAppendingPathComponent:@"release"];
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    }

    content = [content componentsSeparatedByString:@"JAVA_VERSION=\""][1];
    content = [content componentsSeparatedByString:@"\""][0];
    return content;
}

- (NSNumber *)majorVersionForFullVersion:(NSString *)version {
    if ([version hasPrefix:@"1.8.0"]) {
        return @8;
    } else if ([version hasPrefix:@"Error: "]){
        return @(INVALID_JRE);
    } else {
        return @([version componentsSeparatedByString:@"."][0].intValue);
    }
}
- (NSNumber *)majorVersionForPath:(NSString *)path {
    return [self majorVersionForFullVersion:[self javaVersionForPath:path]];
}

- (void)listJREInPath:(NSString *)path markInternal:(BOOL)markInternal {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
    BOOL isDir;
    for (NSString *file in files) {
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir) {
            continue;
        }
        NSNumber *majorVer = [self majorVersionForPath:[path stringByAppendingPathComponent:file]];
        if (!self.javaRuntimes[majorVer]) {
            self.javaRuntimes[majorVer] = [NSMutableArray new];
            [self.sortedJavaVersions addObject:majorVer];
            [self.sortedJavaVersions sortUsingSelector:@selector(compare:)];
        }
        objc_setAssociatedObject(file, @"internalJRE", @(markInternal), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.javaRuntimes[majorVer] addObject:file];
    }
}

@end
