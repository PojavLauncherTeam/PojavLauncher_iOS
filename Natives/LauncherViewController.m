#import "CustomControlsViewController.h"
#import "JavaGUIViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherViewController.h"

#include "utils.h"

@interface LauncherViewController () <UIDocumentPickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate> {
}

// - (void)method

@end

@implementation LauncherViewController

NSArray* versionList;
UIPickerView* versionPickerView;
UITextField* versionTextField;
int versionSelectedAt = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
    [self setTitle:@"PojavLauncher"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

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

    [LauncherViewController fetchVersionList];
    versionPickerView = [[UIPickerView alloc] init];
    versionPickerView.delegate = self;
    versionPickerView.dataSource = self;
    UIToolbar *versionPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *versionFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *versionDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(versionClosePicker)];
    versionPickToolbar.items = @[versionFlexibleSpace, versionDoneButton];

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
        UIAction *option3 = [UIAction actionWithTitle:@"Preferences" image:[[UIImage systemImageNamed:@"wrench.and.screwdriver"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
            handler:^(__kindof UIAction * _Nonnull action) {[self enterPreferences];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
            options:UIMenuOptionsDisplayInline children:@[option1, option2, option3]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStyleDone target:self action:@selector(displayOptions:)];
    }

    install_progress_bar = [[UIProgressView alloc] initWithFrame:CGRectMake(4.0, height - 58.0, width - 8.0, 6.0)];
    [scrollView addSubview:install_progress_bar];

    install_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [install_button setTitle:@"Play" forState:UIControlStateNormal];
    install_button.frame = CGRectMake(10.0, height - 54.0, 100.0, 50.0);
    [install_button addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:install_button];
    
    install_progress_text = [[UILabel alloc] initWithFrame:CGRectMake(120.0, height - 54.0, width - 124.0, 50.0)];
    [scrollView addSubview:install_progress_text];
}

+ (void)fetchLocalVersionList:(NSMutableArray *)finalVersionList withPreviousIndex:(int)index
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *versionPath = [NSString stringWithFormat:@"%s/versions/", getenv("POJAV_GAME_DIR")];
    NSArray *localVersionList = [fileManager contentsOfDirectoryAtPath:versionPath error:Nil];
    for (NSString *versionId in localVersionList) {
        NSString *localPath = [versionPath stringByAppendingString:versionId];
        BOOL isDir;
        [fileManager fileExistsAtPath:localPath isDirectory:&isDir];
        if (isDir) {
            BOOL shouldAdd = YES;
            for (NSObject *object in finalVersionList) {
                if (![object isKindOfClass:[NSDictionary class]]) continue;
                
                NSDictionary *versionInfo = (NSDictionary *)object;

                NSString *prevVersionId = [versionInfo valueForKey:@"id"];
                if ([versionId isEqualToString:prevVersionId]) {
                    shouldAdd = NO;
                }
            }
            if (shouldAdd && ![finalVersionList containsObject:versionId]) {
                [finalVersionList addObject:versionId];
                if ([versionTextField.text isEqualToString:versionId]) {
                    versionSelectedAt = index;
                }
                index++;
            }
        }
    }
}

+ (void)fetchVersionList
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = 
      [[NSMutableURLRequest alloc] initWithURL:[NSURL
      URLWithString:@"https://launchermeta.mojang.com/mc/game/version_manifest.json"]];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        long statusCode = (long)[httpResponse statusCode];

        NSError *jsonError = nil;
        NSDictionary *jsonArray = (data == nil) ? nil : [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

        if (jsonError != nil) {
            NSLog(@"Warning: Error parsing version list JSON: %@", jsonError);
        } else if (statusCode == 200) {
            NSArray *remoteVersionList = [jsonArray valueForKey:@"versions"];
            assert(remoteVersionList != nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray *finalVersionList = [[NSMutableArray alloc] init];
                int i = 0;
                for (NSDictionary *versionInfo in remoteVersionList) {
                    NSString *versionId = [versionInfo valueForKey:@"id"];
                    NSString *versionType = [versionInfo valueForKey:@"type"];
                    if (([versionType containsString:@"release"] && [getPreference(@"vertype_release") boolValue]) ||
                        ([versionType containsString:@"snapshot"] && [getPreference(@"vertype_snapshot") boolValue]) ||
                        ([versionType containsString:@"old_beta"] && [getPreference(@"vertype_oldbeta") boolValue]) ||
                        ([versionType containsString:@"old_alpha"] && [getPreference(@"vertype_oldalpha") boolValue]) ||
                        [versionType containsString:@"modified"]) {
                        [finalVersionList addObject:versionInfo];
                        
                        if ([versionTextField.text isEqualToString:versionId]) {
                            versionSelectedAt = i;
                        }
                        i++;
                    }
                }
                [self fetchLocalVersionList:finalVersionList withPreviousIndex:i];
                
                versionList = [finalVersionList copy];
                
                [versionPickerView reloadAllComponents];
                [versionPickerView selectRow:versionSelectedAt inComponent:0 animated:NO];
            });
        } else {
            NSString *err_title = [jsonArray valueForKey:@"error"];
            NSString *err_msg = [jsonArray valueForKey:@"errorMessage"];
            NSLog(@"Warning: Error %ld fetching version list: %@: %@", statusCode, err_title, err_msg);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (versionList == nil) { // no internet connection
                NSMutableArray *finalVersionList = [[NSMutableArray alloc] init];
                [self fetchLocalVersionList:finalVersionList withPreviousIndex:0];
                versionList = [finalVersionList copy];
                [versionPickerView reloadAllComponents];
                [versionPickerView selectRow:versionSelectedAt inComponent:0 animated:NO];
            }
        });
    }];
    [getDataTask resume];
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
        UIAlertAction *option3 = [UIAlertAction actionWithTitle:@"Preferences"  style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {[self enterPreferences];}];
        fullAlert.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:fullAlert animated:YES completion:nil];
        [fullAlert addAction:option1];
        [fullAlert addAction:option2];
        [fullAlert addAction:option3];
    }
}

- (void)enterCustomControls {
    CustomControlsViewController *vc = [[CustomControlsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)enterModInstaller:(UIBarButtonItem*)sender {
    NSString *javaVer = getPreference(@"java_home");
    if(![javaVer containsString:(@"java-8-openjdk")] && ![javaVer containsString:(@"jre8")]) {
        UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:@"Cannot use the mod installer" message:@"In order to use the mod installer, you need to install Java 8 and specify it in the Preferences menu." preferredStyle:UIAlertControllerStyleActionSheet];
        if (offlineAlert.popoverPresentationController != nil) {
            offlineAlert.popoverPresentationController.sourceView = self.view;
            offlineAlert.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width-10.0, 0, 10, 10);
        }
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:offlineAlert animated:YES completion:nil];
        [offlineAlert addAction:ok];
    } else {
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.sun.java-archive"]
                                                          inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:documentPicker animated:YES completion:nil];
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        JavaGUIViewController *vc = [[JavaGUIViewController alloc] init];
        vc.filepath = url.path;
        NSLog(@"ModInstaller: launching %@", vc.filepath);
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)enterPreferences {
    LauncherPreferencesViewController *vc = [[LauncherPreferencesViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)launchMinecraft:(UIButton *)sender {
    [sender setEnabled:NO];
    
    NSObject *object = [versionList objectAtIndex:[versionPickerView selectedRowInComponent:0]];
    NSString *result;
    if ([object isKindOfClass:[NSString class]]) {
        result = (NSString *)object;
    } else {
        result = [object valueForKey:@"url"];
    }
    NSAssert(result != nil, @"version should not be null");

    callback_LauncherViewController_installMinecraft([result UTF8String]);
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - UIPickerView stuff
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    versionTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    setPreference(@"selected_version", versionTextField.text);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return versionList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSObject *object = [versionList objectAtIndex:row];
    if ([object isKindOfClass:[NSString class]]) {
        return (NSString*) object;
    } else {
        return [object valueForKey:@"id"];
    }
}

- (void)versionClosePicker {
    [versionTextField endEditing:YES];
}

#pragma mark - View controller UI mode
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
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

@end
