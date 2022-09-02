#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController2.h"
#import "TOInsetGroupedTableView.h"

#include "utils.h"

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);

@interface LauncherPreferencesViewController2() {}
@property NSArray<NSString*>* prefSections;
@property NSArray<NSDictionary<NSString*, NSDictionary*>*>* prefContents;

@property CreateView typeButton, typePickField, typeTextField, typeSlider, typeSwitch;
@end

@implementation LauncherPreferencesViewController2

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initViewCreation];

    self.tableView = [[TOInsetGroupedTableView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    self.prefSections = @[@"general", @"video", @"control", @"java"];

    self.prefContents = @[
        @{
        // General settings
            @"game_directory": @{
                @"icon": @"folder",
                @"type": self.typePickField,
                @"pickList": @[@"default", @"TODO"]
            },
            @"home_symlink": @{
                @"icon": @"link",
                @"type": self.typeSwitch
            },
            @"check_sha": @{
                @"icon": @"lock.shield",
                @"type": self.typeSwitch
            },
            @"cosmetica": @{
                @"icon": @"eyeglasses",
                @"type": self.typeSwitch
            },
            @"reset_settings": @{
                @"icon": @"trash",
                @"type": self.typeButton,
                @"requestReload": @YES,
                @"showConfirmPrompt": @(YES),
                @"action": ^void(){
                    loadPreferences(YES);
                    // TODO: reset UI states
                }
            },
            @"reset_warnings": @{
                @"icon": @"exclamationmark.triangle",
                @"type": self.typeButton,
                @"action": ^void(){
                    resetWarnings();
                }
            },
        }, @{
        // Video and renderer settings
            @"renderer": @{
                @"icon": @"cpu",
                @"type": self.typePickField,
                @"pickList": @[@"gl4es", @"zink", @"wip"]
            },
            @"resolution": @{
                @"icon": @"viewfinder",
                @"type": self.typeSlider
            },
        }, @{
        // Control settings
        /*
            @"disable_gesture": @{
                @"type": self.typeSwitch
            },
        */
            @"press_duration": @{
                @"icon": @"timer",
                @"type": self.typeSlider,
                @"min": @(100),
                @"max": @(1000)
            },
            @"button_scale": @{
                @"icon": @"aspectratio",
                @"type": self.typeSlider,
                @"min": @(50), // 80?
                @"max": @(500)
            },
            @"mouse_scale": @{
                @"icon": @"arrow.up.left.and.arrow.down.right.circle",
                @"type": self.typeSlider,
                @"min": @(25),
                @"max": @(300)
            },
            @"mouse_speed": @{
                @"icon": @"arrow.left.and.right",
                @"type": self.typeSlider,
                @"min": @(25),
                @"max": @(300)
            },
            @"virtmouse_enable": @{
                @"icon": @"cursorarrow.rays",
                @"type": self.typeSwitch
            },
            @"slideable_hotbar": @{
                @"icon": @"slider.horizontal.below.rectangle",
                @"type": self.typeSwitch
            }
        }, @{
        // Java tweaks
            @"java_home": @{ // TODO: name as Use Java 17 for older MC
                @"icon": @"cube",
                @"type": self.typeSwitch,
                // false: 8, true: 17
                @"customSwitchValue": @[@"java-8-openjdk", @"java-17-openjdk"]
            },
            @"java_args": @{
                @"icon": @"slider.vertical.3",
                @"type": self.typeTextField
            },
            @"auto_ram": @{
                @"icon": @"slider.horizontal.3",
                @"type": self.typeSwitch,
                //@"hidden": @(getenv("POJAV_DETECTEDJB") == NULL),
                @"requestReload": @YES
            },
            @"allocated_memory": @{
                @"icon": @"memorychip",
                @"type": self.typeSlider,
                @"min": @(NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.25),
                @"max": @(NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.85),
                @"enableCondition": ^BOOL(){
                    return ![getPreference(@"auto_ram") boolValue];
                },
                @"warnAlways": @NO,
                @"warnCondition": ^BOOL(DBNumberedSlider *view){
                    return view.value >= NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.4;
                },
                @"warnKey": @"mem_warn"
            }
        }
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.prefSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(([NSString stringWithFormat:@"preference.section.%@", self.prefSections[section]]), nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.prefContents[section].count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = nil;

    NSString *key = self.prefContents[indexPath.section].allKeys[indexPath.row];
    NSDictionary *item = self.prefContents[indexPath.section].allValues[indexPath.row];
    CreateView createView = item[@"type"];
    createView(cell, key, item);
    if (cell.accessoryView) {
        objc_setAssociatedObject(cell.accessoryView, @"key", key, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(cell.accessoryView, @"item", item, OBJC_ASSOCIATION_ASSIGN);
    }

    // Set general properties
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    cell.textLabel.text = NSLocalizedString(([NSString stringWithFormat:@"preference.title.%@", key]), nil);

    // Check if one has enable condition and call if it does
    BOOL(^checkEnable)(void) = item[@"enableCondition"];
    cell.userInteractionEnabled = !checkEnable || checkEnable();
    cell.textLabel.enabled = cell.detailTextLabel.enabled = cell.userInteractionEnabled;

    return cell;
}

- (void)initViewCreation {
    __weak LauncherPreferencesViewController2 *weakSelf = self;

    self.typeButton = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.textColor = UIColor.systemBlueColor;
    };

/*
    self.typePickField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryView = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2, cell.bounds.size.height)];
        [(id)(cell.accessoryView) setText:getPreference(key)];
    };
*/

    self.typeTextField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        UITextField *view = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2.1, cell.bounds.size.height)];
        [view addTarget:view action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        view.delegate = weakSelf;
        view.placeholder = NSLocalizedString(([NSString stringWithFormat:@"preference.placeholder.%@", key]), nil);
        view.returnKeyType = UIReturnKeyDone;
        view.text = getPreference(key);
        view.textAlignment = NSTextAlignmentRight;
        view.adjustsFontSizeToFitWidth = YES;
        cell.accessoryView = view;
    };

    self.typePickField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        weakSelf.typeTextField(cell, key, item);
        //???
    };

    self.typeSlider = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        DBNumberedSlider *view = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2.1, cell.bounds.size.height)];
        [view addTarget:weakSelf action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        view.minimumValue = [item[@"min"] intValue];
        view.maximumValue = [item[@"max"] intValue];
        view.continuous = YES;
        view.value = [getPreference(key) intValue];
        cell.accessoryView = view;
    };

    self.typeSwitch = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        UISwitch *view = [[UISwitch alloc] init];
        [view setOn:[getPreference(key) boolValue] animated:NO];
        [view addTarget:weakSelf action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = view;
    };
}

- (void)showAlertOnView:(UIView *)view title:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = view;
    alert.popoverPresentationController.sourceRect = view.bounds;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkWarn:(UIView *)view {
    NSString *key = objc_getAssociatedObject(view, @"key");
    NSDictionary *item = objc_getAssociatedObject(view, @"item");

    BOOL(^isWarnable)(UIView *) = item[@"warnCondition"];
    NSString *warnKey = item[@"warnKey"];
    if (isWarnable && isWarnable(view) && (!warnKey || [getPreference(warnKey) boolValue])) {
        if (warnKey) {
            setPreference(warnKey, @NO);
        }

        NSString *message = NSLocalizedString(([NSString stringWithFormat:@"preference.warn.%@", key]), nil);
        [self showAlertOnView:view title:NSLocalizedString(@"Warning", nil) message:message];
    }
}

#pragma mark Control event handlers

- (void)sliderMoved:(DBNumberedSlider *)sender {
    [self checkWarn:sender];
    NSString *key = objc_getAssociatedObject(sender, @"key");

    setPreference(key, @(sender.value));
}

- (void)switchChanged:(UISwitch *)sender {
    [self checkWarn:sender];
    NSString *key = objc_getAssociatedObject(sender, @"key");
    NSDictionary *item = objc_getAssociatedObject(sender, @"item");

    // Special switches may define custom value instead of NO/YES
    NSArray *customSwitchValue = item[@"customSwitchValue"];
    if (customSwitchValue != nil) {
        setPreference(key, customSwitchValue[sender.isOn]);
    } else {
        setPreference(key, @(sender.isOn));
    }

    // Some settings may affect the availability of other settings
    // In this case, a switch may request to reload to apply user interaction change
    if ([item[@"requestReload"] boolValue]) {
        // TODO: only reload needed rows
        [self.tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    UITableViewCell *view = [self.tableView cellForRowAtIndexPath:indexPath];
    if (view.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }

    NSString *key = self.prefContents[indexPath.section].allKeys[indexPath.row];
    NSDictionary *item = self.prefContents[indexPath.section].allValues[indexPath.row];

    if ([item[@"showConfirmPrompt"] boolValue]) {
        NSString *title = NSLocalizedString(@"preference.title.confirm", nil);
        NSString *message = NSLocalizedString(([NSString stringWithFormat:@"preference.title.confirm.%@", key]), nil);
        UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
        confirmAlert.popoverPresentationController.sourceView = view;
        confirmAlert.popoverPresentationController.sourceRect = view.bounds;
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self tableView:tableView invokeActionAtIndexPath:indexPath];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        [confirmAlert addAction:cancel];
        [confirmAlert addAction:ok];
        [self presentViewController:confirmAlert animated:YES completion:nil];
    } else {
        [self tableView:tableView invokeActionAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView invokeActionAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = self.prefContents[indexPath.section].allKeys[indexPath.row];
    NSDictionary *item = self.prefContents[indexPath.section].allValues[indexPath.row];

    void(^invokeAction)(void) = item[@"action"];
    if (invokeAction) {
        invokeAction();
    }

    UIView *view = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *title = NSLocalizedString(([NSString stringWithFormat:@"preference.title.done.%@", key]), nil);
    //NSString *message = NSLocalizedString(([NSString stringWithFormat:@"preference.message.done.%@", key]), nil);
    [self showAlertOnView:view title:title message:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)sender {
    [self checkWarn:sender];
    NSString *key = objc_getAssociatedObject(sender, @"key");

    setPreference(key, sender.text);
}

@end
