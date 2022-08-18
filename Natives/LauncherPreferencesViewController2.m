#import <Foundation/Foundation.h>

#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController2.h"
#import "TOInsetGroupedTableView.h"

#include "utils.h"

@interface LauncherPreferencesViewController2() {}
@property NSArray<NSString*>* prefSections;
@property NSArray<NSDictionary<NSString*, NSDictionary*>*>* prefContents;
@end

@implementation LauncherPreferencesViewController2

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView = [[TOInsetGroupedTableView alloc] init];
    self.tableView.allowsSelection = NO;

    self.prefSections = @[@"general", @"video", @"control", @"java"];

    self.prefContents = @[
        @{
        // General settings
            @"game_directory": @{
                @"icon": @"folder",
                @"type": @"PickField",
                @"pickList": @[@"default", @"TODO"]
            },
            @"home_symlink": @{
                @"icon": @"link",
                @"type": @"Switch"
            },
            @"check_sha": @{
                @"icon": @"lock.shield",
                @"type": @"Switch"
            },
            @"cosmetica": @{
                @"icon": @"eyeglasses",
                @"type": @"Switch"
            },
            @"reset_warnings": @{
                @"icon": @"exclamationmark.triangle",
                @"type": @"Switch"
            },
            @"reset_settings": @{
                @"icon": @"trash",
                @"type": @"Switch"
            }
        }, @{
        // Video and renderer settings
            @"renderer": @{
                @"icon": @"cpu",
                @"type": @"PickField",
                @"pickList": @[@"gl4es", @"zink", @"wip"]
            },
            @"resolution": @{
                @"icon": @"viewfinder",
                @"type": @"Slider"
            },
        }, @{
        // Control settings
        /*
            @"disable_gesture": @{
                @"type": @"Switch"
            },
        */
            @"press_duration": @{
                @"icon": @"timer",
                @"type": @"Slider",
                @"min": @(100),
                @"max": @(1000)
            },
            @"button_scale": @{
                @"icon": @"aspectratio",
                @"type": @"Slider",
                @"min": @(50), // 80?
                @"max": @(500)
            },
            @"mouse_scale": @{
                @"icon": @"arrow.up.left.and.arrow.down.right.circle",
                @"type": @"Slider",
                @"min": @(25),
                @"max": @(300)
            },
            @"mouse_speed": @{
                @"icon": @"arrow.left.and.right",
                @"type": @"Slider",
                @"min": @(25),
                @"max": @(300)
            },
            @"virtmouse_enable": @{
                @"icon": @"cursorarrow.rays",
                @"type": @"Switch"
            },
            @"slideable_hotbar": @{
                @"icon": @"slider.horizontal.below.rectangle",
                @"type": @"Switch"
            }
        }, @{
        // Java tweaks
            @"java_home": @{ // TODO: name as Use Java 17 for older MC
                @"icon": @"cube",
                @"type": @"PickField",
                // false: 8, true: 17
                @"customSwitchValue": @[@"java-8-openjdk", @"java-17-openjdk"]
            },
            @"java_args": @{
                @"icon": @"slider.vertical.3",
                @"type": @"TextField"
            },
            @"auto_ram": @{
                @"icon": @"slider.horizontal.3",
                @"type": @"Switch",
                @"hidden": @(getenv("POJAV_DETECTEDJB") != NULL),
                @"warnCondition": ^BOOL(UISwitch *view){
                    return view.isOn;
                },
                //@"warnMessage": @"TODO",
                @"warnAlways": @YES
            },
            @"allocated_memory": @{
                @"icon": @"memorychip",
                @"type": @"Slider",
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
    NSString *type = item[@"type"];
    if ([type isEqualToString:@"PickField"]) {
        cell.accessoryView = [[UITextField alloc] init];
        [(id)(cell.accessoryView) setText:getPreference(key)];
    } else if ([type isEqualToString:@"TextField"]) {
        UITextField *view = [[UITextField alloc] init];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        view.placeholder = NSLocalizedString(([NSString stringWithFormat:@"preference.placeholder.%@", key]), nil);
        view.text = getPreference(key);
        view.adjustsFontSizeToFitWidth = YES;
        cell.accessoryView = view;
    } else if ([type isEqualToString:@"Slider"]) {
        DBNumberedSlider *view = [[DBNumberedSlider alloc] init];
        view.minimumValue = [item[@"min"] intValue];
        view.maximumValue = [item[@"max"] intValue];
        view.continuous = YES;
        view.value = [getPreference(key) intValue];
        cell.accessoryView = view;
    } else if ([type isEqualToString:@"Switch"]) {
        cell.accessoryView = [[UISwitch alloc] init];
        [(id)(cell.accessoryView) setOn:[getPreference(key) boolValue] animated:NO];
    } else {
        NSAssert(NO, @"Unknown type: %@", type);
    }

    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    cell.textLabel.text = NSLocalizedString(([NSString stringWithFormat:@"preference.title.%@", key]), nil);

    return cell;
}

@end
