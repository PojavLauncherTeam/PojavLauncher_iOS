#import <Foundation/Foundation.h>

#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController2.h"
#import "TOInsetGroupedTableView.h"

#include "utils.h"

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);

@interface LauncherPreferencesViewController2() {}
@property NSArray<NSString*>* prefSections;
@property NSArray<NSDictionary<NSString*, NSDictionary*>*>* prefContents;

@property CreateView typePickField, typeTextField, typeSlider, typeSwitch;
@end

@implementation LauncherPreferencesViewController2

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initViewCreation];

    self.tableView = [[TOInsetGroupedTableView alloc] init];
    self.tableView.allowsSelection = NO;

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
            @"reset_warnings": @{
                @"icon": @"exclamationmark.triangle",
                @"type": self.typeSwitch
            },
            @"reset_settings": @{
                @"icon": @"trash",
                @"type": self.typeSwitch
            }
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
                @"hidden": @(getenv("POJAV_DETECTEDJB") != NULL),
                @"warnCondition": ^BOOL(UISwitch *view){
                    return view.isOn;
                },
                //@"warnMessage": @"TODO",
                @"warnAlways": @YES
            },
            @"allocated_memory": @{
                @"icon": @"memorychip",
                @"type": self.typeSlider,
                @"min": @(NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.25),
                @"max": @(NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.85),
                @"warnAlways": @NO,
                @"warnCondition": ^BOOL(DBNumberedSlider *view){
                    return view.value >= NSProcessInfo.processInfo.physicalMemory / 1048576 * 0.4;
                }
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

    NSString *key = self.prefContents[indexPath.section].allKeys[indexPath.row];
    NSDictionary *item = self.prefContents[indexPath.section].allValues[indexPath.row];
    CreateView createView = item[@"type"];
    createView(cell, key, item);

    // Set general properties
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    cell.textLabel.text = NSLocalizedString(([NSString stringWithFormat:@"preference.title.%@", key]), nil);

    return cell;
}

- (void)initViewCreation {
    self.typePickField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryView = [[UITextField alloc] init];
        [(id)(cell.accessoryView) setText:getPreference(key)];
    };

    self.typeTextField = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        UITextField *view = [[UITextField alloc] init];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        view.placeholder = NSLocalizedString(([NSString stringWithFormat:@"preference.placeholder.%@", key]), nil);
        view.text = getPreference(key);
        view.adjustsFontSizeToFitWidth = YES;
        cell.accessoryView = view;
    };

    self.typeSlider = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        DBNumberedSlider *view = [[DBNumberedSlider alloc] init];
        view.minimumValue = [item[@"min"] intValue];
        view.maximumValue = [item[@"max"] intValue];
        view.continuous = YES;
        view.value = [getPreference(key) intValue];
        cell.accessoryView = view;
    };

    self.typeSwitch = ^void(UITableViewCell *cell, NSString *key, NSDictionary *item) {
        cell.accessoryView = [[UISwitch alloc] init];
        [(id)(cell.accessoryView) setOn:[getPreference(key) boolValue] animated:NO];
    };
}

@end
