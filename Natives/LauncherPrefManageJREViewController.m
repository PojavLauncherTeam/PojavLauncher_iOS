#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "WFWorkflowProgressView.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefManageJREViewController.h"
#import "NSFileManager+NRFileManager.h"
#import "UIKit+hook.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include <dlfcn.h>
#include <lzma.h>
#include <objc/runtime.h>

// 0 is reserved for default pickers
// INT_MAX is reserved for invalid runtimes
#define DEFAULT_JRE 0
#define INVALID_JRE INT_MAX

// https://www.gnu.org/software/tar/manual/html_node/Standard.html
typedef struct {
    char name[100];
    char mode[8];
    char unused1[8+8];
    char size[12];
    char unused2[12+8];
    char typeflag;
    char linkname[100];
    char unused3[6+2+32+32+8+8+155+12];
} TarHeader;

static WFWorkflowProgressView* currentProgressView;

@interface LauncherPrefManageJREViewController ()<UIContextMenuInteractionDelegate, UIDocumentPickerDelegate>
@property(nonatomic) NSMutableDictionary<NSNumber *, NSMutableArray *> *javaRuntimes;
@property(nonatomic) NSMutableArray<NSNumber *> *sortedJavaVersions;
@property(nonatomic) NSArray<NSString *> *selectedRTTags;
@property(nonatomic) NSMutableDictionary<NSString *, NSString *> *selectedRuntimes;
@property(nonatomic) UIMenu* currentMenu;
@property(nonatomic, weak) NSIndexPath* installingIndexPath;
@end

@implementation LauncherPrefManageJREViewController

+ (LauncherPrefManageJREViewController *)currentInstance {
    UISplitViewController *splitVC = (id)currentVC();
    LauncherNavigationController *nav = (id)splitVC.viewControllers[1];
    if (![nav.topViewController isKindOfClass:LauncherPrefManageJREViewController.class]) {
        return nil;
    }
    return (id)nav.topViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:localize(@"preference.title.manage_runtime", nil)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(actionImportRuntime)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    self.javaRuntimes = @{
        @(DEFAULT_JRE): @[@"preference.manage_runtime.default.1165", @"preference.manage_runtime.default.117", @"launcher.menu.execute_jar"]
    }.mutableCopy;
    self.sortedJavaVersions = @[@(DEFAULT_JRE)].mutableCopy;

    self.selectedRTTags = @[@"1_16_5_older", @"1_17_newer", @"execute_jar"];
    self.selectedRuntimes = getPrefObject(@"java.java_homes");

    NSString *internalPath = [NSString stringWithFormat:@"%@/java_runtimes", NSBundle.mainBundle.bundlePath];
    NSString *externalPath = [NSString stringWithFormat:@"%s/java_runtimes", getenv("POJAV_HOME")];
    [self listJREInPath:internalPath markInternal:YES];
    [self listJREInPath:externalPath markInternal:NO];

    // Load WFWorkflowProgressView
    dlopen("/System/Library/PrivateFrameworks/WorkflowUIServices.framework/WorkflowUIServices", RTLD_GLOBAL);
}

+ (void)actionCancelImportRuntime {
    UISplitViewController *splitVC = (id)currentVC();
    LauncherNavigationController *nav = (id)splitVC.viewControllers[1];
    [nav.progressViewMain.observedProgress cancel];
}

- (void)actionImportRuntime {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[[UTType typeWithMIMEType:@"application/x-xz"]]];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    LauncherNavigationController *nav = (id)self.navigationController;
    [nav setInteractionEnabled:NO forDownloading:NO];

    [url startAccessingSecurityScopedResource];
    NSUInteger xzSize = [NSFileManager.defaultManager attributesOfItemAtPath:url.path error:nil].fileSize;

    NSProgress *totalProgress = [NSProgress progressWithTotalUnitCount:xzSize];
    NSProgress *fileProgress = [NSProgress progressWithTotalUnitCount:0];
    nav.progressViewMain.observedProgress = totalProgress;
    nav.progressViewSub.observedProgress = fileProgress;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *outPath = [NSString stringWithFormat:@"%s/java_runtimes/%@", getenv("POJAV_HOME"),
            [url.path substringToIndex:url.path.length-7].lastPathComponent];
        NSString *error = [LauncherPrefManageJREViewController extractTarXZ:url.path
        to:outPath progress:totalProgress fileProgress:fileProgress
        fileCallback:^(NSString* name) {
            NSString *completedSize = [NSByteCountFormatter stringFromByteCount:fileProgress.completedUnitCount countStyle:NSByteCountFormatterCountStyleMemory];
            NSString *totalSize = [NSByteCountFormatter stringFromByteCount:fileProgress.totalUnitCount countStyle:NSByteCountFormatterCountStyleMemory];
            nav.progressText.text = [NSString stringWithFormat:@"(%@ / %@) %@", completedSize, totalSize, name];
            currentProgressView.fractionCompleted = totalProgress.fractionCompleted;
        }];
        [url stopAccessingSecurityScopedResource];

        if (error) {
            showDialog(localize(@"Error", nil), error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            LauncherPrefManageJREViewController *vc = LauncherPrefManageJREViewController.currentInstance;
            currentProgressView = nil;

            if ((error || totalProgress.cancelled) && vc.installingIndexPath) {
                [vc removeRuntimeAtIndexPath:vc.installingIndexPath];
            } else {
                NSNumber *version = self.sortedJavaVersions[vc.installingIndexPath.section];
                NSString *name = self.javaRuntimes[version][vc.installingIndexPath.row];
                objc_setAssociatedObject(name, @"installing", @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            vc.installingIndexPath = nil;
            [vc.tableView reloadData];

            [nav setInteractionEnabled:YES forDownloading:NO];
            nav.progressViewMain.observedProgress = nil;
            nav.progressViewSub.observedProgress = nil;
            nav.progressText.text = @"";
        });
    });
}

#pragma mark Table view

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
    BOOL isInstalling = [objc_getAssociatedObject(name, @"installing") boolValue];
    if (isInternal) {
        cell.textLabel.text = [NSString stringWithFormat:@"[Internal] %@", name];
    } else {
        cell.textLabel.text = name;
    }

    if (isInstalling) {
        self.installingIndexPath = indexPath;

        LauncherNavigationController *nav = (id)self.navigationController;
        if (!currentProgressView) {
            currentProgressView = [[NSClassFromString(@"WFWorkflowProgressView") alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            currentProgressView.resolvedTintColor = self.view.tintColor;
            [currentProgressView addTarget:LauncherPrefManageJREViewController.class
                action:@selector(actionCancelImportRuntime) forControlEvents:UIControlEventPrimaryActionTriggered];
        }

        cell.accessoryView = currentProgressView;
    } else {
        cell.accessoryView = nil;
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
        NSString *directory = [NSString stringWithFormat:@"%@/java_runtimes/%@",
            isInternal ? NSBundle.mainBundle.bundlePath : @(getenv("POJAV_HOME")),
            name];
        [NSFileManager.defaultManager nr_getAllocatedSize:&folderSize ofDirectoryAtURL:[NSURL fileURLWithPath:directory] error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                [self javaVersionForPath:directory],
                [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleMemory]];
        });
    });

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
    setPrefObject(@"java.java_homes", self.selectedRuntimes);

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
                setPrefObject(@"java.java_homes", self.selectedRuntimes);
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) return;

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *title = localize(@"preference.title.confirm", nil);
    NSString *message = [NSString stringWithFormat:localize(@"preference.title.confirm.delete_runtime", nil), cell.textLabel.text];
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    confirmAlert.popoverPresentationController.sourceView = cell;
    confirmAlert.popoverPresentationController.sourceRect = cell.bounds;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSError *error;
        NSString *directory = [NSString stringWithFormat:@"%s/java_runtimes/%@", getenv("POJAV_HOME"), cell.textLabel.text];
        [NSFileManager.defaultManager removeItemAtPath:directory error:&error];
        if(!error) {
            [self removeRuntimeAtIndexPath:indexPath];
            [self.tableView reloadData];
        } else {
            showDialog(localize(@"Error", nil), error.localizedDescription);
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [confirmAlert addAction:cancel];
    [confirmAlert addAction:ok];
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *version = self.sortedJavaVersions[indexPath.section];
    NSString *name = self.javaRuntimes[version][indexPath.row];
    BOOL isInternal = [objc_getAssociatedObject(name, @"internalJRE") boolValue];
    BOOL isInstalling = [objc_getAssociatedObject(name, @"installing") boolValue] && currentProgressView.fractionCompleted > 0.0f;
    if (isInternal || isInstalling) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
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

- (void)addRuntimePath:(NSString *)path markInternal:(BOOL)markInternal {
    NSNumber *majorVer = [self majorVersionForPath:path];
    if (!self.javaRuntimes[majorVer]) {
        self.javaRuntimes[majorVer] = [NSMutableArray new];
        [self.sortedJavaVersions addObject:majorVer];
        [self.sortedJavaVersions sortUsingSelector:@selector(compare:)];
    }

    NSString *file = path.lastPathComponent;
    objc_setAssociatedObject(file, @"internalJRE", @(markInternal), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!markInternal) {
        NSString *installingDir = [path stringByAppendingPathComponent:@".installing"];
        BOOL markInstalling = [NSFileManager.defaultManager fileExistsAtPath:installingDir isDirectory:nil];
        objc_setAssociatedObject(file, @"installing", @(markInstalling), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [self.javaRuntimes[majorVer] addObject:file];
}

- (void)removeRuntimeAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSNumber *version = self.sortedJavaVersions[indexPath.section];
    NSString *name = self.javaRuntimes[version][indexPath.row];

    [self.javaRuntimes[version] removeObject:name];
    if (self.javaRuntimes[version].count == 0) {
        [self.javaRuntimes removeObjectForKey:version];
        [self.selectedRuntimes removeObjectForKey:version.stringValue];
        [self.sortedJavaVersions removeObject:version];
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        self.selectedRuntimes[version.stringValue] = self.javaRuntimes[version][0];
    }

    setPrefObject(@"java.java_homes", self.selectedRuntimes);
}

- (void)listJREInPath:(NSString *)path markInternal:(BOOL)markInternal {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
    BOOL isDir;
    for (NSString *file in files) {
        NSString *rtPath = [path stringByAppendingPathComponent:file];
        [fm fileExistsAtPath:rtPath isDirectory:&isDir];
        if (isDir) {
            [self addRuntimePath:rtPath markInternal:markInternal];
        }
    }
}

#pragma mark Extract tar.xz

+ (NSDictionary *)parseRuntimeInfo:(NSString *)path {
    NSError *error;

    NSString *releaseFile = [path stringByAppendingPathComponent:@"release"];
    NSString *content = [NSString stringWithContentsOfFile:releaseFile encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return @{@"Error": error.localizedDescription};
    }

    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (NSString *line in [content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        if (line.length > 0) {
            NSArray *keyValue = [[line substringToIndex:line.length-1] componentsSeparatedByString:@"=\""];
            dict[keyValue[0]] = keyValue[1];
        }
    }
    return dict;
}

+ (NSString *)validateRuntimeInfo:(NSString *)path {
    NSDictionary *dict = [self parseRuntimeInfo:path];

    if (dict[@"Error"]) {
        return dict[@"Error"];
    } else if (![dict[@"OS_ARCH"] isEqualToString:@"aarch64"]) {
        return [NSString stringWithFormat:@"Wrong runtime architecture: %@ (need aarch64)", dict[@"OS_ARCH"]];
    } else if (![dict[@"OS_NAME"] isEqualToString:@"Darwin"]) {
        return [NSString stringWithFormat:@"Wrong runtime platform: %@ (need Darwin)", dict[@"OS_NAME"]];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentInstance addRuntimePath:path markInternal:NO];
        [self.currentInstance.tableView reloadData];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentInstance.tableView scrollToRowAtIndexPath:self.currentInstance.installingIndexPath
            atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
    return nil;
}

+ (NSString *)lzmaErrorDescriptionForCode:(int)code {
    switch (code) {
        case LZMA_MEM_ERROR:
            return @"Memory allocation failed";
        case LZMA_FORMAT_ERROR:
            return @"The input is not in the .xz format";
        case LZMA_OPTIONS_ERROR:
            return @"Unsupported compression options";
        case LZMA_DATA_ERROR:
            return @"Compressed file is corrupt";
        case LZMA_BUF_ERROR:
            return @"Compressed file is truncated or otherwise corrupt";
        default:
            return @"Unknown error, possibly a bug";
    }
}

// Reference: https://github.com/xz-mirror/xz/blob/master/doc/examples/02_decompress.c
+ (NSString *)extractTarXZ:(NSString *)inPath to:(NSString *)outPath progress:(NSProgress *)progress fileProgress:(NSProgress *)fileProgress fileCallback:(void(^)(NSString* name))fileCallback {
    NSString *installingDir = [outPath stringByAppendingPathComponent:@".installing"];
    [NSFileManager.defaultManager createDirectoryAtPath:installingDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSInputStream *inFile = [NSInputStream inputStreamWithFileAtPath:inPath];
    [inFile open];

    NSString *msg = nil;
    lzma_stream strm = LZMA_STREAM_INIT;
    lzma_action action = LZMA_RUN;
    uint8_t inbuf[BUFSIZ], outbuf[512];

    lzma_ret ret = lzma_stream_decoder(&strm, UINT64_MAX, LZMA_CONCATENATED);
    if (ret != LZMA_OK) {
        return [self lzmaErrorDescriptionForCode:ret];
    }

    strm.next_in = NULL;
    strm.avail_in = 0;
    strm.next_out = outbuf;
    strm.avail_out = sizeof(outbuf);

    TarHeader currFileHeader;
    NSString *currFileName;
    NSOutputStream *currFileOut;
    NSUInteger currFileOff, currFileSize;

    while (!progress.cancelled) {
        if (strm.avail_in == 0 && inFile.hasBytesAvailable) {
            strm.next_in = inbuf;
            strm.avail_in = [inFile read:inbuf maxLength:sizeof(inbuf)];

            if (strm.avail_in == -1) {
                msg = inFile.streamError.localizedDescription;
                break;
            }

            if (!inFile.hasBytesAvailable) {
                action = LZMA_FINISH;
            }
        }

        ret = lzma_code(&strm, action);
        if (strm.avail_out == 0 || ret == LZMA_STREAM_END) {
            if (currFileOut) {
                size_t remaining = currFileSize - currFileOff;
                size_t write_size = MIN(sizeof(outbuf), remaining);
                currFileOff += write_size;
                // Avoid overloading the main queue
                if (currFileOff % 102400 == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        fileProgress.completedUnitCount = currFileOff;
                        fileCallback(currFileName);
                    });
                }
                if ([currFileOut write:outbuf maxLength:write_size] != write_size) {
                    msg = [NSString stringWithFormat:@"%s: %@", currFileHeader.name, currFileOut.streamError];
                    break;
                } else if (currFileOff >= currFileSize) {
                    [currFileOut close];
                    currFileOut = nil;
                    if ([currFileName isEqualToString:@"./release"]) {
                        msg = [LauncherPrefManageJREViewController validateRuntimeInfo:outPath];
                        if (msg) goto cleanup;
                    }
                }
            } else {
                memcpy(&currFileHeader, outbuf, sizeof(outbuf));
                if (currFileHeader.name[0] == '\0') {
                    // EOF
                    break;
                }
                NSString *absPath = [NSString stringWithFormat:@"%@/%s", outPath, currFileHeader.name];
                NSError *error = nil;
                switch (currFileHeader.typeflag) {
                    case '0':
                    case '\0': { // File
                        currFileName = @(currFileHeader.name);
                        currFileOff = fileProgress.completedUnitCount = 0;
                        currFileSize = fileProgress.totalUnitCount = strtol(currFileHeader.size, NULL, 8);
                        NSLog(@"[RuntimeUnpack] Extracting %@", currFileName);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            fileCallback(currFileName);
                        });

                        currFileOut = [NSOutputStream outputStreamToFileAtPath:absPath append:NO];
                        [currFileOut open];
                    } break;
                    case '2': { // Symlink
                        symlink(currFileHeader.linkname, currFileHeader.name);
                        //NSLog(@"%s -> %s", currFileHeader.name, currFileHeader.linkname);
                    } break;
                    case '5': { // Folder
                        [NSFileManager.defaultManager createDirectoryAtPath:absPath withIntermediateDirectories:YES attributes:nil error:&error];
                        if (error) {
                            msg = [NSString stringWithFormat:@"%s: %@", currFileHeader.name, error];
                            goto cleanup;
                        }
                    } break;
                    default: // Ignore everything else
                        if (currFileHeader.typeflag < '0' && currFileHeader.typeflag > '7'
                        && (currFileHeader.typeflag != 'x' && currFileHeader.typeflag != 'g')) {
                            msg = [NSString stringWithFormat:@"Invalid typeflag %c", currFileHeader.typeflag];
                            goto cleanup;
                        }
                        NSLog(@"[RuntimeUnpack] Skipped %s (typeflag %c)", currFileHeader.name, currFileHeader.typeflag);
                        break;
                }
            }

            strm.next_out = outbuf;
            strm.avail_out = sizeof(outbuf);

            progress.completedUnitCount = strm.total_in;
        }

        if (ret == LZMA_STREAM_END) {
            break;
        } else if (ret != LZMA_OK) {
            msg = [self lzmaErrorDescriptionForCode:ret];
            break;
        }
    }

cleanup:
    if (msg || progress.cancelled) {
        [NSFileManager.defaultManager removeItemAtPath:outPath error:nil];
    } else {
        [NSFileManager.defaultManager removeItemAtPath:installingDir error:nil];
    }
    lzma_end(&strm);
    [inFile close];
    [currFileOut close];
    return msg;
}

@end
