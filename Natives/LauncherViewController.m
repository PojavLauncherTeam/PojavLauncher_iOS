#import "LauncherViewController.h"
#import "LauncherPreferencesViewController.h"

#include "utils.h"

@interface LauncherViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
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
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
    [self setTitle:@"PojavLauncher"];

    FILE *configver_file = fopen("/var/mobile/Documents/minecraft/config_ver.txt", "rw");

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

    char configver[1024];
    if (!fgets(configver, 1024, configver_file)) {
        NSLog(@"Error: could not read config_ver.txt");
    }

    UILabel *versionTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, 0.0, 0.0)];
    versionTextView.text = @"Minecraft version: ";
    versionTextView.numberOfLines = 0;
    [versionTextView sizeToFit];
    [scrollView addSubview:versionTextView];

    versionTextField = [[UITextField alloc] initWithFrame:CGRectMake(versionTextView.bounds.size.width + 4.0, 4.0, width - versionTextView.bounds.size.width - 8.0, height - 58.0)];
    [versionTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    versionTextField.placeholder = @"Specify version...";
    versionTextField.text = [NSString stringWithUTF8String:configver];
    versionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    versionTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    [self fetchVersionList];
    versionPickerView = [[UIPickerView alloc] init];
    versionPickerView.delegate = self;
    versionPickerView.dataSource = self;
    UIToolbar *versionPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *versionFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *versionDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(versionClosePicker)];
    versionPickToolbar.items = @[versionFlexibleSpace, versionDoneButton];

    versionTextField.inputAccessoryView = versionPickToolbar;
    versionTextField.inputView = versionPickerView;

    fclose(configver_file);
    [scrollView addSubview:versionTextField];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleDone target:self action:@selector(enterPreferences)];
   
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

- (void)fetchLocalVersionList:(NSMutableArray *)finalVersionList withPreviousIndex:(int)index
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *versionPath = @"/var/mobile/Documents/minecraft/versions/";
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

- (void)fetchVersionList
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

        NSString *dataStr = [NSString stringWithUTF8String:[data bytes]];
        NSError *jsonError = nil;
        NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

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
                    [finalVersionList addObject:versionInfo];
                    if ([versionTextField.text isEqualToString:versionId]) {
                        versionSelectedAt = i;
                    }
                    i++;
                }
                [self fetchLocalVersionList:finalVersionList withPreviousIndex:i];
                
                versionList = [finalVersionList copy];
                
                [versionPickerView reloadAllComponents];
                [versionPickerView selectRow:versionSelectedAt inComponent:0 animated:NO];
            });
        } else {
            NSString *err_title = [jsonArray valueForKey:@"error"];
            NSString *err_msg = [jsonArray valueForKey:@"errorMessage"];
            NSLog(@"Warning: failed to fetch version list: %@: %@", err_title, err_msg);
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
- (void)enterPreferences {
    LauncherPreferencesViewController *vc = [[LauncherPreferencesViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)launchMinecraft:(id)sender {
    [(UIButton*) sender setEnabled:NO];
    
    NSObject *object = [versionList objectAtIndex:[versionPickerView selectedRowInComponent:0]];
    NSString *result;
    if ([object isKindOfClass:[NSString class]]) {
        result = (NSString*) object;
    } else {
        result = [object valueForKey:@"url"];
    }

    callback_LauncherViewController_installMinecraft([result UTF8String]);
}

#pragma mark - UIPickerView stuff
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    versionTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    [versionTextField.text writeToFile:@"/var/mobile/Documents/minecraft/config_ver.txt" atomically:NO encoding:NSUTF8StringEncoding error:nil];
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
