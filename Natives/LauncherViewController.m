#import "AFNetworking.h"
#import "CustomControlsViewController.h"
#import "JavaGUIViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherViewController.h"
#import "MinecraftResourceUtils.h"
#import "ios_uikit_bridge.h"

#include "utils.h"

@interface LauncherViewController () <UIDocumentPickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate> {
}

@property NSMutableArray* versionList;
// - (void)method

@end

@implementation LauncherViewController

UIPickerView* versionPickerView;
UITextField* versionTextField;
int versionSelectedAt = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = self.view.frame;

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    UILabel *versionTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, 0.0, 0.0)];
    versionTextView.text = @"Minecraft version: ";
    versionTextView.numberOfLines = 0;
    [versionTextView sizeToFit];
    [scrollView addSubview:versionTextView];

    versionTextField = [[UITextField alloc] initWithFrame:CGRectMake(versionTextView.bounds.size.width + 4.0, 4.0, width - versionTextView.bounds.size.width - 8.0, height - 58.0)];
    [versionTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    versionTextField.placeholder = @"Specify version...";
    versionTextField.text = (NSString *) getPreference(@"selected_version");
    versionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    versionTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;


    self.versionList = [[NSMutableArray alloc] init];
    int selectedVersionType = [getPreference(@"selected_version_type") intValue];
    [self reloadVersionList:selectedVersionType];
    versionPickerView = [[UIPickerView alloc] init];
    versionPickerView.delegate = self;
    versionPickerView.dataSource = self;
    UIToolbar *versionPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];

    UISegmentedControl *versionTypeControl = [[UISegmentedControl alloc]    initWithItems:@[
        NSLocalizedString(@"Installed", nil),
        NSLocalizedString(@"Releases", nil),
        NSLocalizedString(@"Snapshot", nil),
        NSLocalizedString(@"Old-beta", nil),
        NSLocalizedString(@"Old-alpha", nil)
    ]];
    versionTypeControl.selectedSegmentIndex = selectedVersionType;
    [versionTypeControl addTarget:self action:@selector(changeVersionType:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *versionTypeItem = [[UIBarButtonItem alloc] initWithCustomView:versionTypeControl];
    UIBarButtonItem *versionFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *versionDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(versionClosePicker)];
    versionPickToolbar.items = @[versionTypeItem, versionFlexibleSpace, versionDoneButton];

    versionTextField.inputAccessoryView = versionPickToolbar;
    versionTextField.inputView = versionPickerView;

    [scrollView addSubview:versionTextField];

    if (@available(iOS 14.0, *)) {
        // use UIMenu
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"ellipsis.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(displayOptions:)];
        UIAction *option1 = [UIAction actionWithTitle:@"Launch a mod installer" image:[[UIImage systemImageNamed:@"internaldrive"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
            handler:^(__kindof UIAction * _Nonnull action) {[self enterModInstaller:self.navigationItem.rightBarButtonItem];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Custom controls" image:[[UIImage systemImageNamed:@"dpad.right.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
            handler:^(__kindof UIAction * _Nonnull action) {[self enterCustomControls];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
            options:UIMenuOptionsDisplayInline children:@[option1, option2]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStyleDone target:self action:@selector(displayOptions:)];
    }

    self.progressViewMain = [[UIProgressView alloc] initWithFrame:CGRectMake(4.0, height - 58.0, width - 8.0, 6.0)];
    self.progressViewSub = [[UIProgressView alloc] initWithFrame:CGRectMake(4.0, height - 58.0, width - 8.0, 6.0)];
    self.progressViewMain.alpha = 0.6;
    self.progressViewSub.alpha = 0.4;
    [scrollView addSubview:self.progressViewSub];
    [scrollView addSubview:self.progressViewMain];

    self.buttonInstall = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.buttonInstall.enabled = NO;
    [self.buttonInstall setTitle:@"Play" forState:UIControlStateNormal];
    self.buttonInstall.frame = CGRectMake(10.0, height - 54.0, 100.0, 50.0);
    [self.buttonInstall addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:self.buttonInstall];
    
    self.progressText = [[UILabel alloc] initWithFrame:CGRectMake(120.0, height - 54.0, width - 124.0, 50.0)];
    [scrollView addSubview:self.progressText];
}

- (BOOL)isVersionInstalled:(NSString *)versionId
{
    NSString *localPath = [NSString stringWithFormat:@"%s/versions/%@", getenv("POJAV_GAME_DIR"), versionId];
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager fileExistsAtPath:localPath isDirectory:&isDirectory];
    return isDirectory;
}

- (void)fetchLocalVersionList:(NSMutableArray *)finalVersionList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *versionPath = [NSString stringWithFormat:@"%s/versions/", getenv("POJAV_GAME_DIR")];
    NSArray *localVersionList = [fileManager contentsOfDirectoryAtPath:versionPath error:Nil];
    for (NSString *versionId in localVersionList) {
        if ([self isVersionInstalled:versionId]) {
            BOOL shouldAdd = YES;
            for (NSObject *object in finalVersionList) {
                if (![object isKindOfClass:[NSDictionary class]]) continue;
                
                NSDictionary *versionInfo = (NSDictionary *)object;

                NSString *prevVersionId = [versionInfo valueForKey:@"id"];
                if ([versionId isEqualToString:prevVersionId]) {
                    shouldAdd = NO;
                }
            }
            if (shouldAdd && [MinecraftResourceUtils findVersion:versionId inList:self.versionList] == nil) {
                [finalVersionList addObject:versionId];
                if ([versionTextField.text isEqualToString:versionId]) {
                    versionSelectedAt = finalVersionList.count - 1;
                }
            }
        }
    }
}

- (void)reloadVersionList:(int)type
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:@"https://piston-meta.mojang.com/mc/game/version_manifest_v2.json" parameters:nil headers:nil progress:^(NSProgress * _Nonnull progress) {
        self.progressViewMain.progress = progress.fractionCompleted;
    } success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
        NSObject *lastSelected = nil;
        if (self.versionList.count > 0 && versionSelectedAt >= 0) {
            lastSelected = self.versionList[versionSelectedAt];
        }
        [self.versionList removeAllObjects];        

        remoteVersionList = responseObject[@"versions"];
        assert(remoteVersionList != nil);
        versionSelectedAt = -versionSelectedAt;

        for (NSDictionary *versionInfo in remoteVersionList) {
            NSString *versionId = versionInfo[@"id"];
            NSString *versionType = versionInfo[@"type"];
            if (([self isVersionInstalled:versionId] && type == TYPE_INSTALLED) ||
                ([versionType isEqualToString:@"release"] && type == TYPE_RELEASE) ||
                ([versionType isEqualToString:@"snapshot"] && type == TYPE_SNAPSHOT) ||
                ([versionType isEqualToString:@"old_beta"] && type == TYPE_OLDBETA) ||
                ([versionType isEqualToString:@"old_alpha"] && type == TYPE_OLDALPHA)) {
                [self.versionList addObject:versionInfo];

                if ([versionTextField.text isEqualToString:versionId]) {
                    versionSelectedAt = self.versionList.count - 1;
                }
            }
        }

        if (type == TYPE_INSTALLED) {
            [self fetchLocalVersionList:self.versionList];
        }

        [versionPickerView reloadAllComponents];
        if (versionSelectedAt < 0 && lastSelected != nil) {
            NSObject *nearest = [MinecraftResourceUtils findNearestVersion:lastSelected expectedType:type];
            if (nearest != nil) {
                versionSelectedAt = [self.versionList indexOfObject:nearest];
            }
        }

        // Get back the currently selected in case none matching version found
        versionSelectedAt = MIN(abs(versionSelectedAt), self.versionList.count - 1);

        [versionPickerView selectRow:versionSelectedAt inComponent:0 animated:NO];
        [self pickerView:versionPickerView didSelectRow:versionSelectedAt inComponent:0];

        self.buttonInstall.enabled = YES;
        self.progressViewMain.progress = 0;
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Warning: Error fetching version list: %@", error);
        self.buttonInstall.enabled = YES;
    }];
}

- (void)changeVersionType:(UISegmentedControl *)sender {
    setPreference(@"selected_version_type", @(sender.selectedSegmentIndex));
    [self reloadVersionList:sender.selectedSegmentIndex];
}

#pragma mark - Button click events
- (void)displayOptions:(UIBarButtonItem*)sender {
    if (@available(iOS 14.0, *)) {
        // use UIMenu
    } else {
        // use UIAlertController
        UIAlertController *fullAlert = [UIAlertController alertControllerWithTitle:@"Options" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *option1 = [UIAlertAction actionWithTitle:@"Launch a mod installer" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {[self enterModInstaller:self.navigationItem.rightBarButtonItem];}];
        UIAlertAction *option2 = [UIAlertAction actionWithTitle:@"Custom controls" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {[self enterCustomControls];}];
        fullAlert.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:fullAlert animated:YES completion:nil];
        [fullAlert addAction:option1];
        [fullAlert addAction:option2];
    }
}

- (void)enterCustomControls {
    if (![getPreference(@"customctrl_warn") boolValue]) {
        CustomControlsViewController *vc = [[CustomControlsViewController alloc] init];
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    setPreference(@"customctrl_warn", @(NO));
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"This option is unfinished, some might be incomplete or missing." preferredStyle:UIAlertControllerStyleActionSheet];
    if (alert.popoverPresentationController != nil) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width-10.0, 0, 10, 10);
    }
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self enterCustomControls];
    }];
    [self presentViewController:alert animated:YES completion:nil];
    [alert addAction:ok];
}

- (void)enterModInstaller:(UIBarButtonItem*)sender {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.sun.java-archive"]
            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        JavaGUIViewController *vc = [[JavaGUIViewController alloc] init];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        vc.filepath = url.path;
        NSLog(@"ModInstaller: launching %@", vc.filepath);
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)launchMinecraft:(UIButton *)sender {
    if (!versionTextField.hasText) {
        return;
    }

    sender.enabled = NO;

    NSObject *object = [self.versionList objectAtIndex:[versionPickerView selectedRowInComponent:0]];

    [MinecraftResourceUtils downloadVersion:object callback:^(NSString *stage, NSProgress *mainProgress, NSProgress *progress) {
        if (progress == nil && stage != nil) {
            NSLog(@"[MCDL] %@", stage);
        }
        self.progressViewMain.observedProgress = mainProgress;
        self.progressViewSub.observedProgress = progress;
        if (stage == nil) {
            sender.enabled = YES;
            if (mainProgress != nil) {
                UIKit_launchMinecraftSurfaceVC();
            }
            return;
        }
        self.progressText.text = [NSString stringWithFormat:@"%@ (%.2f MB / %.2f MB)", stage, progress.completedUnitCount/1048576.0, progress.totalUnitCount/1048576.0];
    }];

    //callback_LauncherViewController_installMinecraft("1.12.2");
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - UIPickerView stuff
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.versionList.count == 0) {
        versionTextField.text = @"";
        return;
    }
    versionSelectedAt = row;
    versionTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    setPreference(@"selected_version", versionTextField.text);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.versionList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSObject *object = [self.versionList objectAtIndex:row];
    if ([object isKindOfClass:[NSString class]]) {
        return (NSString*) object;
    } else {
        return [object valueForKey:@"id"];
    }
}

- (void)versionClosePicker {
    [versionTextField endEditing:YES];
    [self pickerView:versionPickerView didSelectRow:[versionPickerView selectedRowInComponent:0] inComponent:0];
}

#pragma mark - View controller UI mode
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

@end
