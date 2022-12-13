#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherPrefGameDirViewController.h"
#import "TOInsetGroupedTableView.h"

#import "utils.h"

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);

@interface LauncherPreferencesViewController(){}
@property(nonatomic) NSArray<NSString*>* prefSections;
@property(nonatomic) NSMutableArray<NSNumber*>* prefSectionsVisibility;
@property(nonatomic) NSArray<NSArray<NSDictionary*>*>* prefContents;
@property(nonatomic) BOOL prefDetailVisible;

@property CreateView typeButton, typeChildPane, typePickField, typeTextField, typeSlider, typeSwitch;
@end

@implementation LauncherPreferencesViewController

- (NSString *)imageName {
    return @"MenuSettings";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initViewCreation];

    self.prefDetailVisible = self.navigationController == nil;

    self.tableView = [[TOInsetGroupedTableView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    if (self.navigationController == nil) {
        self.tableView.alpha = 0.9;
    }

    BOOL(^whenNotInGame)() = ^BOOL(){
        return self.navigationController != nil;
    };

    self.prefSections = @[@"general", @"video", @"control", @"java", @"debug"];
    self.prefSectionsVisibility = [[NSMutableArray alloc] initWithCapacity:self.prefSections.count];
    for (int i = 0; i < self.prefSections.count; i++) {
        [self.prefSectionsVisibility addObject:@NO];
    }

    self.prefContents = @[
        @[
        // General settings
            @{@"icon": @"cube"},
            @{@"key": @"game_directory",
                @"icon": @"folder",
                @"type": self.typeChildPane,
                @"enableCondition": whenNotInGame,
                @"class": LauncherPrefGameDirViewController.class,
            },
            @{@"key": @"check_sha",
                @"hasDetail": @YES,
                @"icon": @"lock.shield",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"cosmetica",
                @"hasDetail": @YES,
                @"icon": @"eyeglasses",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"debug_logging",
                @"hasDetail": @YES,
                @"icon": @"doc.badge.gearshape",
                @"type": self.typeSwitch
            },
            @{@"key": @"jitstreamer_server",
                @"hasDetail": @YES,
                @"icon": @"hare",
                @"type": self.typeTextField,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"appicon",
                @"hasDetail": @YES,
                @"icon": @"paintbrush",
                @"type": self.typePickField,
                @"enableCondition": ^BOOL(){
                    return UIApplication.sharedApplication.supportsAlternateIcons;
                },
                @"action": ^void(NSString *iconName) {
                    if ([iconName isEqualToString:@"AppIcon-Light"]) {
                        iconName = nil;
                    }
                    [UIApplication.sharedApplication setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
                        if (error == nil) return;
                        NSLog(@"Error: %@", error);
                    }];
                },
                @"pickKeys": @[
                  @"AppIcon-Light",
                  @"AppIcon-Dark"
                ],
                @"pickList": @[
                  localize(@"preference.title.appicon-default", nil),
                  localize(@"preference.title.appicon-dark", nil)
                ]
            },
            @{@"key": @"reset_warnings",
                @"icon": @"exclamationmark.triangle",
                @"type": self.typeButton,
                @"enableCondition": whenNotInGame,
                @"action": ^void(){
                    resetWarnings();
                }
            },
            @{@"key": @"reset_settings",
                @"icon": @"trash",
                @"type": self.typeButton,
                @"enableCondition": whenNotInGame,
                @"requestReload": @YES,
                @"showConfirmPrompt": @YES,
                @"destructive": @YES,
                @"action": ^void(){
                    loadPreferences(YES);
                    [self.tableView reloadData];
                }
            },
        ], @[
        // Video and renderer settings
            @{@"icon": @"video"},
            @{@"key": @"renderer",
                @"icon": @"cpu",
                @"type": self.typePickField,
                @"enableCondition": whenNotInGame,
                @"pickKeys": @[
                    @"auto",
                    @ RENDERER_NAME_GL4ES,
                    @ RENDERER_NAME_MTL_ANGLE,
                    @ RENDERER_NAME_VK_ZINK
                ],
                @"pickList": @[
                    localize(@"preference.title.renderer.auto", nil),
                    localize(@"preference.title.renderer.gl4es", nil),
                    localize(@"preference.title.renderer.angle", nil),
                    localize(@"preference.title.renderer.zink", nil)
                ]
            },
            @{@"key": @"resolution",
                @"hasDetail": @YES,
                @"icon": @"viewfinder",
                @"type": self.typeSlider,
                @"min": @(25),
                @"max": @(150)
            },
        ], @[
        // Control settings
        /*
            @"disable_gesture": @{
                @"type": self.typeSwitch
            },
        */
            @{@"icon": @"gamecontroller"},
            @{@"key": @"press_duration",
                @"hasDetail": @YES,
                @"icon": @"cursorarrow.click.badge.clock",
                @"type": self.typeSlider,
                @"min": @(100),
                @"max": @(1000)
            },
            @{@"key": @"button_scale",
                @"hasDetail": @YES,
                @"icon": @"aspectratio",
                @"type": self.typeSlider,
                @"min": @(50), // 80?
                @"max": @(500)
            },
            @{@"key": @"mouse_scale",
                @"hasDetail": @YES,
                @"icon": @"arrow.up.left.and.arrow.down.right.circle",
                @"type": self.typeSlider,
                @"min": @(25),
                @"max": @(300)
            },
            @{@"key": @"mouse_speed",
                @"hasDetail": @YES,
                @"icon": @"cursorarrow.motionlines",
                @"type": self.typeSlider,
                @"min": @(25),
                @"max": @(300)
            },
            @{@"key": @"virtmouse_enable",
                @"hasDetail": @YES,
                @"icon": @"cursorarrow.rays",
                @"type": self.typeSwitch
            },
            @{@"key": @"slideable_hotbar",
                @"hasDetail": @YES,
                @"icon": @"slider.horizontal.below.rectangle",
                @"type": self.typeSwitch
            }
        ], @[
        // Java tweaks
            @{@"icon": @"sparkles"},
            @{@"key": @"java_home", // Use Java 17 for Minecraft < 1.17
                @"hasDetail": @YES,
                @"icon": @"cube",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame,
                // false: 8, true: 17
                @"customSwitchValue": @[@"java-8-openjdk", @"java-17-openjdk"]
            },
            @{@"key": @"java_args",
                @"hasDetail": @YES,
                @"icon": @"slider.vertical.3",
                @"type": self.typeTextField,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"auto_ram",
                @"hasDetail": @YES,
                @"icon": @"slider.horizontal.3",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame,
                @"warnCondition": ^BOOL(){
                    return getenv("POJAV_DETECTEDJB") == NULL;
                },
                @"warnKey": @"auto_ram_warn",
                @"requestReload": @YES
            },
            @{@"key": @"allocated_memory",
                @"hasDetail": @YES,
                @"icon": @"memorychip",
                @"type": self.typeSlider,
                @"min": @(250),
                @"max": @((NSProcessInfo.processInfo.physicalMemory / 1048576) * 0.85),
                @"enableCondition": ^BOOL(){
                    return ![getPreference(@"auto_ram") boolValue] && whenNotInGame();
                },
                @"warnCondition": ^BOOL(DBNumberedSlider *view){
                    return view.value >= NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.37;
                },
                @"warnKey": @"mem_warn"
            }
        ], @[
            // Debug settings - only recommended for developer use
            @{@"icon": @"ladybug"},
            @{@"key": @"debug_skip_wait_jit",
                @"hasDetail": @YES,
                @"icon": @"forward",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"debug_hide_home_indicator",
                @"hasDetail": @YES,
                @"icon": @"iphone.and.arrow.forward",
                @"type": self.typeSwitch,
                @"enableCondition": ^BOOL(){
                    return self.presentingViewController.view.safeAreaInsets.bottom > 0;
                }
            },
            @{@"key": @"debug_ipad_ui",
                @"hasDetail": @YES,
                @"icon": @"ipad",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame
            },
            @{@"key": @"debug_auto_correction",
                @"hasDetail": @YES,
                @"icon": @"textformat.abc.dottedunderline",
                @"type": self.typeSwitch
            },
            @{@"key": @"debug_show_layout_bounds",
                @"hasDetail": @YES,
                @"icon": @"square.dashed",
                @"type": self.typeSwitch,
                @"enableCondition": whenNotInGame,
                @"requestReload": @YES
            },
            @{@"key": @"debug_show_layout_overlap",
                @"hasDetail": @YES,
                @"icon": @"square.on.square",
                @"type": self.typeSwitch,
                @"enableCondition": ^BOOL(){
                    return [getPreference(@"debug_show_layout_bounds") boolValue] && whenNotInGame();
                }
            }
        ]
    ];

    UIBarButtonItem *helpButton;
    if (@available(iOS 13.0, *)) {
        helpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"questionmark.circle"] style:UIBarButtonItemStyleDone target:self action:@selector(toggleDetailVisibility)];
    } else {
        helpButton = [[UIBarButtonItem alloc] initWithTitle:localize(@"Help", nil) style:UIBarButtonItemStyleDone target:self action:@selector(toggleDetailVisibility)];
    }
    self.navigationItem.rightBarButtonItems = @[helpButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Scan for child pane cells and reload them
    // FIXME: any cheaper operations?
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (int section = 0; section < self.prefContents.count; section++) {
        if (!self.prefSectionsVisibility[section].boolValue) {
            continue;
        }
        for (int row = 0; row < self.prefContents[section].count; row++) {
            if (self.prefContents[section][row][@"type"] == self.typeChildPane) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
    }
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.navigationController == nil) {
        [self.presentingViewController performSelector:@selector(updatePreferenceChanges)];
    }
}

- (void)toggleDetailVisibility {
    self.prefDetailVisible = !self.prefDetailVisible;
    [self.tableView reloadData];
}

#pragma mark UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.prefSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) { // Add to general section
        return [NSString stringWithFormat:@"PojavLauncher %@-%s (%s/%s)\niOS %s on %s (%s)",
            NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
            CONFIG_TYPE, CONFIG_BRANCH, CONFIG_COMMIT, getenv("POJAV_DETECTEDSW"), getenv("POJAV_DETECTEDHW"), getenv("POJAV_DETECTEDINST")];
    }

    NSString *footer = NSLocalizedStringWithDefaultValue(([NSString stringWithFormat:@"preference.section.footer.%@", self.prefSections[section]]), @"Localizable", NSBundle.mainBundle, @" ", nil);
    if ([footer isEqualToString:@" "]) {
        return nil;
    }
    return footer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.prefSectionsVisibility[section].boolValue) {
        return self.prefContents[section].count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];

    NSString *cellID;
    UITableViewCellStyle cellStyle;
    if (item[@"type"] == self.typeChildPane || item[@"type"] == self.typePickField) {
        cellID = @"cellValue1";
        cellStyle = UITableViewCellStyleValue1;
    } else {
        cellID = @"cellSubtitle";
        cellStyle = UITableViewCellStyleSubtitle;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellID];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    // Reset cell properties, as it could be reused
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = nil;
    cell.detailTextLabel.text = nil;

    NSString *key = item[@"key"];
    if (indexPath.row == 0) {
        key = self.prefSections[indexPath.section];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = localize(([NSString stringWithFormat:@"preference.section.%@", key]), nil);
    } else {
        CreateView createView = item[@"type"];
        createView(cell, key, item);
        if (cell.accessoryView) {
            objc_setAssociatedObject(cell.accessoryView, @"key", key, OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(cell.accessoryView, @"item", item, OBJC_ASSOCIATION_ASSIGN);
        }
        cell.textLabel.text = localize(([NSString stringWithFormat:@"preference.title.%@", key]), nil);
    }

    // Set general properties
    if (@available(iOS 13.0, *)) {
        BOOL destructive = [item[@"destructive"] boolValue];
        cell.imageView.tintColor = destructive ? UIColor.systemRedColor : nil;
        cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    if (cellStyle != UITableViewCellStyleValue1) {
        cell.detailTextLabel.text = nil;
        if ([item[@"hasDetail"] boolValue] && self.prefDetailVisible) {
            cell.detailTextLabel.text = localize(([NSString stringWithFormat:@"preference.detail.%@", key]), nil);
        }
    }

    // Check if one has enable condition and call if it does
    BOOL(^checkEnable)(void) = item[@"enableCondition"];
    cell.userInteractionEnabled = !checkEnable || checkEnable();
    cell.textLabel.enabled = cell.detailTextLabel.enabled = cell.userInteractionEnabled;
    [(id)cell.accessoryView setEnabled:cell.userInteractionEnabled];

    return cell;
}

#pragma mark initViewCreation, showAlert, checkWarn

- (void)initViewCreation {
    __weak LauncherPreferencesViewController *weakSelf = self;

    self.typeButton = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        BOOL destructive = [item[@"destructive"] boolValue];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.textColor = destructive ? UIColor.systemRedColor : weakSelf.view.tintColor;
    };

    self.typeChildPane = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.detailTextLabel.text = getPreference(key);
    };

    self.typeTextField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        UITextField *view = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2.1, cell.bounds.size.height)];
        [view addTarget:view action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        view.delegate = weakSelf;
        view.placeholder = localize(([NSString stringWithFormat:@"preference.placeholder.%@", key]), nil);
        view.returnKeyType = UIReturnKeyDone;
        view.text = getPreference(key);
        view.textAlignment = NSTextAlignmentRight;
        view.adjustsFontSizeToFitWidth = YES;
        cell.accessoryView = view;
    };

    self.typePickField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.detailTextLabel.text = getPreference(key);
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
        NSArray *customSwitchValue = item[@"customSwitchValue"];
        if (customSwitchValue == nil) {
            [view setOn:[getPreference(key) boolValue] animated:NO];
        } else {
            [view setOn:[getPreference(key) isEqualToString:customSwitchValue[1]] animated:NO];
        }
        [view addTarget:weakSelf action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = view;
    };
}

- (void)showAlertOnView:(UIView *)view title:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = view;
    alert.popoverPresentationController.sourceRect = view.bounds;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkWarn:(UIView *)view {
    NSDictionary *item = objc_getAssociatedObject(view, @"item");
    NSString *key = item[@"key"];

    BOOL(^isWarnable)(UIView *) = item[@"warnCondition"];
    NSString *warnKey = item[@"warnKey"];
    // Display warning if: warn condition is met and either one of these:
    // - does not have warnKey, always warn
    // - has warnKey and its value is YES, warn once and set it to NO
    if (isWarnable && isWarnable(view) && (!warnKey || [getPreference(warnKey) boolValue])) {
        if (warnKey) {
            setPreference(warnKey, @NO);
        }

        NSString *message = localize(([NSString stringWithFormat:@"preference.warn.%@", key]), nil);
        [self showAlertOnView:view title:localize(@"Warning", nil) message:message];
    }
}

#pragma mark Control event handlers

- (void)sliderMoved:(DBNumberedSlider *)sender {
    [self checkWarn:sender];
    NSString *key = objc_getAssociatedObject(sender, @"key");

    sender.value = (int)sender.value;
    setPreference(key, @(sender.value));
}

- (void)switchChanged:(UISwitch *)sender {
    [self checkWarn:sender];
    NSDictionary *item = objc_getAssociatedObject(sender, @"item");
    NSString *key = item[@"key"];

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
    if (indexPath.row == 0) {
        self.prefSectionsVisibility[indexPath.section] = @(![self.prefSectionsVisibility[indexPath.section] boolValue]);
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        return;
    }

    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];

    if (item[@"type"] == self.typeButton) {
        [self tableView:tableView invokeActionWithPromptAtIndexPath:indexPath];
    } else if (item[@"type"] == self.typeChildPane) {
        [self tableView:tableView openChildPaneAtIndexPath:indexPath];
    } else if (item[@"type"] == self.typePickField) {
        [self tableView:tableView openPickerAtIndexPath:indexPath];
    }
}

#pragma mark External UITableView functions

- (void)tableView:(UITableView *)tableView openChildPaneAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];
    UIViewController *vc = [[item[@"class"] alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView openPickerAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];
    NSArray *pickKeys = item[@"pickKeys"];
    NSArray *pickList = item[@"pickList"];
/*
    if (@available(iOS 14.0, *)) {
        NSMutableArray *menuItems = [[NSMutableArray alloc] init];
        for (int i = 0; i < pickList.count; i++) {
            [menuItems addObject:[UIAction
                actionWithTitle:pickList[i]
                image:nil
                identifier:nil
                handler:^(UIAction *action) {
                    cell.detailTextLabel.text = pickKeys[i];
                    setPreference(item[@"key"], pickKeys[i]);
                }]];
        }
        // FIXME: how to set menu for cell?
        cell.menu = [UIMenu menuWithTitle:cell.textLabel.text children:menuItems];
        return;
    }
*/
    NSString *message = @"";
    if ([item[@"hasDetail"] boolValue]) {
        message = localize(([NSString stringWithFormat:@"preference.detail.%@", item[@"key"]]), nil);
    }
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:cell.textLabel.text message:message preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i = 0; i < pickList.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:pickList[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            cell.detailTextLabel.text = pickKeys[i];
            setPreference(item[@"key"], pickKeys[i]);
            void(^invokeAction)(NSString *) = item[@"action"];
            if (invokeAction) {
                invokeAction(pickKeys[i]);
            }
        }];
        [picker addAction:action];
    }

    UILabel *labels = [UILabel appearanceWhenContainedInInstancesOfClasses:@[UIAlertController.class]];
    labels.numberOfLines = 2;
    picker.popoverPresentationController.sourceView = cell;
    picker.popoverPresentationController.sourceRect = cell.bounds;

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [picker addAction:cancel];

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView invokeActionWithPromptAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *view = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];

    if ([item[@"showConfirmPrompt"] boolValue]) {
        BOOL destructive = [item[@"destructive"] boolValue];
        NSString *title = localize(@"preference.title.confirm", nil);
        NSString *message = localize(([NSString stringWithFormat:@"preference.title.confirm.%@", key]), nil);
        UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
        confirmAlert.popoverPresentationController.sourceView = view;
        confirmAlert.popoverPresentationController.sourceRect = view.bounds;
        UIAlertAction *ok = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:destructive?UIAlertActionStyleDestructive:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self tableView:tableView invokeActionAtIndexPath:indexPath];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        [confirmAlert addAction:cancel];
        [confirmAlert addAction:ok];
        [self presentViewController:confirmAlert animated:YES completion:nil];
    } else {
        [self tableView:tableView invokeActionAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView invokeActionAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];

    void(^invokeAction)(void) = item[@"action"];
    if (invokeAction) {
        invokeAction();
    }

    UIView *view = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *title = localize(([NSString stringWithFormat:@"preference.title.done.%@", key]), nil);
    //NSString *message = localize(([NSString stringWithFormat:@"preference.message.done.%@", key]), nil);
    [self showAlertOnView:view title:title message:nil];
}

#pragma mark UITextField

- (void)textFieldDidEndEditing:(UITextField *)sender {
    [self checkWarn:sender];
    NSString *key = objc_getAssociatedObject(sender, @"key");

    setPreference(key, sender.text);
}

@end
