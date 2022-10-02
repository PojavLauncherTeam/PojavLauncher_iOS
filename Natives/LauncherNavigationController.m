#import "AFNetworking.h"
#import "CustomControlsViewController.h"
#import "JavaGUIViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceUtils.h"
#import "ios_uikit_bridge.h"

#include "utils.h"

#define AUTORESIZE_MASKS UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin

@interface LauncherNavigationController () <UIDocumentPickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate> {
}

@property NSMutableArray* versionList;
// - (void)method

@end

@implementation LauncherNavigationController

UIPickerView* versionPickerView;
UITextField* versionTextField;
int versionSelectedAt = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];

    CGFloat splitWidth = self.toolbar.frame.size.width / 3;

    versionTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 4, splitWidth, self.toolbar.frame.size.height/2 - 4)];
    [versionTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    versionTextField.autoresizingMask = AUTORESIZE_MASKS;
    versionTextField.placeholder = @"Specify version...";
    versionTextField.text = (NSString *) getPreference(@"selected_version");
    versionTextField.textAlignment = NSTextAlignmentCenter;

    self.versionList = [[NSMutableArray alloc] init];
    versionPickerView = [[UIPickerView alloc] init];
    versionPickerView.delegate = self;
    versionPickerView.dataSource = self;
    UIToolbar *versionPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];

    UISegmentedControl *versionTypeControl = [[UISegmentedControl alloc] initWithItems:@[
        NSLocalizedString(@"Installed", nil),
        NSLocalizedString(@"Releases", nil),
        NSLocalizedString(@"Snapshot", nil),
        NSLocalizedString(@"Old-beta", nil),
        NSLocalizedString(@"Old-alpha", nil)
    ]];
    versionTypeControl.selectedSegmentIndex = [getPreference(@"selected_version_type") intValue];
    [versionTypeControl addTarget:self action:@selector(changeVersionType:) forControlEvents:UIControlEventValueChanged];
    [self reloadVersionList:versionTypeControl.selectedSegmentIndex];

    UIBarButtonItem *versionTypeItem = [[UIBarButtonItem alloc] initWithCustomView:versionTypeControl];
    UIBarButtonItem *versionFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *versionDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(versionClosePicker)];
    versionPickToolbar.items = @[versionTypeItem, versionFlexibleSpace, versionDoneButton];
    versionTextField.inputAccessoryView = versionPickToolbar;
    versionTextField.inputView = versionPickerView;

    [self.toolbar addSubview:versionTextField];

    self.progressViewMain = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.toolbar.frame.size.width, 4.0)];
    self.progressViewSub = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.toolbar.frame.size.height - 4.0, self.toolbar.frame.size.width, 4.0)];
    self.progressViewMain.autoresizingMask = self.progressViewSub.autoresizingMask = AUTORESIZE_MASKS;
    self.progressViewMain.hidden = self.progressViewSub.hidden = YES;
    [self.toolbar addSubview:self.progressViewMain];
    [self.toolbar addSubview:self.progressViewSub];

    self.buttonInstall = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(self.buttonInstall);
    self.buttonInstall.enabled = NO;
    [self.buttonInstall setTitle:NSLocalizedString(@"Play", nil) forState:UIControlStateNormal];
    self.buttonInstall.autoresizingMask = AUTORESIZE_MASKS;
    self.buttonInstall.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    self.buttonInstall.layer.cornerRadius = 5;
    self.buttonInstall.frame = CGRectMake(splitWidth, 6.0, splitWidth, self.toolbar.frame.size.height - 12.0);
    self.buttonInstall.tintColor = UIColor.whiteColor;
    [self.buttonInstall addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:self.buttonInstall];

    UIButton *buttonCustomControls = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(buttonCustomControls);
    [buttonCustomControls setTitle:NSLocalizedString(@"launcher.menu.custom_controls", nil) forState:UIControlStateNormal];
    buttonCustomControls.autoresizingMask = AUTORESIZE_MASKS;
    buttonCustomControls.frame = CGRectMake(0, self.toolbar.frame.size.height/2, splitWidth, self.toolbar.frame.size.height/2);
    [buttonCustomControls addTarget:self action:@selector(enterCustomControls) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:buttonCustomControls];

    UIButton *buttonInstallJar = [UIButton buttonWithType:UIButtonTypeSystem];
    setButtonPointerInteraction(buttonInstallJar);
    [buttonInstallJar setTitle:NSLocalizedString(@"launcher.menu.install_jar", nil) forState:UIControlStateNormal];
    buttonInstallJar.autoresizingMask = AUTORESIZE_MASKS;
    buttonInstallJar.frame = CGRectMake(splitWidth*2, self.toolbar.frame.size.height/2, splitWidth, self.toolbar.frame.size.height/2);
    [buttonInstallJar addTarget:self action:@selector(enterModInstaller) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:buttonInstallJar];

    self.progressText = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, self.toolbar.frame.size.width, 20)];
    self.progressText.adjustsFontSizeToFitWidth = YES;
    self.progressText.autoresizingMask = AUTORESIZE_MASKS;
    self.progressText.font = [self.progressText.font fontWithSize:16];
    self.progressText.textAlignment = NSTextAlignmentCenter;
    self.progressText.userInteractionEnabled = NO;
    [self.toolbar addSubview:self.progressText];
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
    self.buttonInstall.enabled = NO;

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

#pragma mark - Options
- (void)enterCustomControls {
    CustomControlsViewController *vc = [[CustomControlsViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [currentVC() presentViewController:vc animated:YES completion:nil];
}

- (void)enterModInstaller {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.sun.java-archive"]
            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [currentVC() presentViewController:documentPicker animated:YES completion:nil];
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

    sender.alpha = 0.5;
    sender.enabled = NO;
    self.progressViewMain.hidden = self.progressViewSub.hidden = NO;

    NSObject *object = [self.versionList objectAtIndex:[versionPickerView selectedRowInComponent:0]];

    [MinecraftResourceUtils downloadVersion:object callback:^(NSString *stage, NSProgress *mainProgress, NSProgress *progress) {
        if (progress == nil && stage != nil) {
            NSLog(@"[MCDL] %@", stage);
        }
        self.progressViewMain.observedProgress = mainProgress;
        self.progressViewSub.observedProgress = progress;
        if (stage == nil) {
            sender.alpha = 1;
            sender.enabled = YES;
            self.progressText.text = nil;
            self.progressViewMain.hidden = self.progressViewSub.hidden = YES;
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

@end
