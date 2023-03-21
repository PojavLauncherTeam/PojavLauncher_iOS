#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "input/ControllerInput.h"
#import "customcontrols/CustomControlsUtils.h"
#import "FileListViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefContCfgViewController.h"
#import "TOInsetGroupedTableView.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include "glfw_keycodes.h"

#define contentNavigationController (LauncherNavigationController *)UIApplication.sharedApplication.keyWindow.rootViewController.splitViewController.viewControllers[1]

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);

@interface LauncherPrefContCfgViewController ()<UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property(nonatomic) NSString *currentFileName;
@property(nonatomic) NSMutableDictionary *allMappings;
@property(nonatomic) NSDictionary *keycodePlist;
@property(nonatomic) UITextField *activeTextField;
@property(nonatomic) NSArray<NSString*>* prefSections;
@property(nonatomic) NSMutableArray<NSNumber*>* prefSectionsVisibility;
@property(nonatomic) NSArray<NSArray<NSDictionary*>*>* prefContents;
@property(nonatomic) NSArray<NSArray*>* prefMappings, *prefMappingsTrimmed;
@property(nonatomic) NSArray<NSDictionary*>* prefConfigFiles, *prefControllerTypes;
@property(nonatomic) NSMutableArray *keyCodeMap, *keyValueMap;

@end

@implementation LauncherPrefContCfgViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:localize(@"preference.title.default_gamepad_ctrl", nil)];
    
    self.keycodePlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glfw_keycodes" ofType:@"plist"]];
    
    self.keyCodeMap = [[NSMutableArray alloc] init];
    self.keyValueMap = [[NSMutableArray alloc] init];
    initKeycodeTable(self.keyCodeMap, self.keyValueMap);
    
    self.tableView = [[TOInsetGroupedTableView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.sectionFooterHeight = 50;
    
    self.prefMappings = [self loadGamepadConfigurationFile:YES shouldSkipImmutables:NO];
    self.prefMappingsTrimmed = [self loadGamepadConfigurationFile:NO shouldSkipImmutables:YES];
    self.prefConfigFiles = [self loadGamepadControlFolder];
    self.prefControllerTypes = [self loadControllerTypeOptions];
    
    self.prefSections = @[@"config_files", @"game_mappings", @"menu_mappings", @"controller_style"];
    self.prefContents = @[self.prefConfigFiles, self.prefMappingsTrimmed[0], self.prefMappingsTrimmed[1], self.prefControllerTypes];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:localize(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(actionMenuSave)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:localize(@"Exit", nil) style:UIBarButtonItemStyleDone target:self action:@selector(exitButtonSelector)];
    
}

- (NSArray<NSArray<NSDictionary*>*>*) loadGamepadConfigurationFile:(BOOL)isUpdated shouldSkipImmutables:(BOOL)isSkipped {
    if(isUpdated) {
        NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/%@", getenv("POJAV_HOME"), getPreference(@"default_gamepad_ctrl")];
        self.allMappings = parseJSONFromFile(gamepadPath);
    }
    
    self.currentFileName = [getPreference(@"default_ctrl") stringByDeletingPathExtension];
    
    NSMutableArray<NSDictionary*>* tempGameMap = [[NSMutableArray<NSDictionary*> alloc] init];
    NSMutableArray<NSDictionary*>* tempMenuMap = [[NSMutableArray<NSDictionary*> alloc] init];
    
    __block NSArray *immutables = @[@"mouse_primary", @"mouse_middle", @"mouse_secondary"];
    __block NSArray *maps = @[@"mGameMappingList", @"mMenuMappingList"];
    
    for(NSString *mapName in maps) {
        for(NSDictionary* mapping in self.allMappings[mapName]) {
            __block BOOL isImmutable = NO;
            __block int isThird = 0;
            for(NSString* name in immutables) {
                if([name isEqualToString:mapping[@"name"]]) { if(isSkipped) { isImmutable = YES; } }
                if(isThird == 2 && !isImmutable) {
                    if([mapName isEqualToString:maps[0]]) {
                        [tempGameMap addObject:mapping];
                    } else if([mapName isEqualToString:maps[1]]) {
                        [tempMenuMap addObject:mapping];
                    }
                }
                isThird++;
            }
        }
    }
    
    return @[[tempGameMap copy], [tempMenuMap copy]];
}

- (NSArray<NSDictionary*>*) loadGamepadControlFolder {
    NSArray<NSString*>* gamepadCtrl = @[getPreference(@"default_gamepad_ctrl")];
    NSMutableArray<NSDictionary*>* finalArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *holder = [[NSMutableDictionary alloc] init];
    holder[@"name"] = gamepadCtrl;
    [finalArray addObject:holder];
    
    return [finalArray copy];
}


- (NSArray<NSDictionary*>*) loadControllerTypeOptions {
    NSArray<NSString*>* types = @[@"xbox", @"playstation"];
    NSMutableArray<NSDictionary*>* finalArray = [[NSMutableArray alloc] init];
    for(NSString *type in types) {
        NSMutableDictionary *controllerDict = [[NSMutableDictionary alloc] init];
        controllerDict[@"name"] = type;
        [finalArray addObject:controllerDict];
    }
    
    return [finalArray copy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark External UITableView functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.prefSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.prefContents[section].count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak LauncherPrefContCfgViewController *weakSelf = self;
    
    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];
    NSString *cellID = @"cellValue1";
    UITableViewCellStyle cellStyle = UITableViewCellStyleValue1;
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

    NSString *name = nil;
    NSString *value = nil;
    NSNumber *keycode = 0;
    
    if(indexPath.section == 0) {
        name = item[@"name"];
        value = getPreference(@"default_gamepad_ctrl");
        cell.textLabel.text = localize(@"controller_configurator.title.current", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = value;
    } else if(indexPath.section == 1 || indexPath.section == 2) {
        name = item[@"name"];
        NSNumber *keycode = (NSNumber *)item[@"keycode"];
        value = [self.keyCodeMap objectAtIndex:[self.keyValueMap indexOfObject:keycode]];
        cell.textLabel.text = localize(([NSString stringWithFormat:@"controller_configurator.%@.title.%@", getPreference(@"controller_type"), name]), nil);
        
        CGFloat shortest = MIN(self.view.frame.size.width, self.view.frame.size.height);
        CGFloat tempW = MIN(self.view.frame.size.width * 0.75, shortest);
        CGFloat tempH = MIN(self.view.frame.size.height * 0.6, shortest);
        
        UITextField *view = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2.1, cell.bounds.size.height)];
        [view addTarget:view action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        view.delegate = weakSelf;
        view.returnKeyType = UIReturnKeyDone;
        view.text = value;
        view.tag = indexPath.section;
        view.textAlignment = NSTextAlignmentRight;
        view.tintColor = UIColor.clearColor;
        view.adjustsFontSizeToFitWidth = YES;
        
        UIPickerView *pickerMapping = [[UIPickerView alloc] init];
        pickerMapping.delegate = self;
        pickerMapping.dataSource = self;
        [pickerMapping reloadAllComponents];
        [pickerMapping selectRow:[self.keyValueMap indexOfObject:keycode] inComponent:0 animated:NO];
        [self pickerView:pickerMapping didSelectRow:0 inComponent:0];

         
        UIBlurEffectStyle blurStyle;
        UIVisualEffectView *blurView;
        if (@available(iOS 13.0, *)) {
            blurStyle = UIBlurEffectStyleSystemMaterial;
        } else {
            blurStyle = UIBlurEffectStyleExtraLight;
        }
        blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
        blurView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        blurView.frame = CGRectMake(
            (self.view.frame.size.width - MAX(tempW, tempH))/2,
            (self.view.frame.size.height - MIN(tempW, tempH))/2,
            MAX(tempW, tempH), MIN(tempW, tempH));
        blurView.layer.cornerRadius = 10.0;
        blurView.clipsToBounds = YES;
        
        UIToolbar *editPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, blurView.frame.size.width, 44.0)];
        UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
      
        UIBarButtonItem *editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTextField:)];
        editPickToolbar.items = @[btnFlexibleSpace, editDoneButton];
         
        view.inputAccessoryView = editPickToolbar;
        view.inputView = pickerMapping;
        
        cell.accessoryView = view;
    } else if(indexPath.section == 3) {
        name = item[@"name"];
        value = getPreference(@"default_gamepad_ctrl");
        cell.textLabel.text = localize([NSString stringWithFormat:@"controller_configurator.title.type.%@", name], nil);
        if ([getPreference(@"controller_type") isEqualToString:name]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    if (cell.accessoryView) {
        objc_setAssociatedObject(cell.accessoryView, @"gamepad_button", name, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(cell.accessoryView, @"item", item, OBJC_ASSOCIATION_ASSIGN);
    }
    
    [(id)cell.accessoryView setEnabled:YES];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = NSLocalizedStringWithDefaultValue(([NSString stringWithFormat:@"controller_configurator.section.%@", self.prefSections[section]]), @"Localizable", NSBundle.mainBundle, @" ", nil);
    if ([header isEqualToString:@" "]) {
        return nil;
    }
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer = NSLocalizedStringWithDefaultValue(([NSString stringWithFormat:@"controller_configurator.section.footer.%@", self.prefSections[section]]), @"Localizable", NSBundle.mainBundle, @" ", nil);
    if ([footer isEqualToString:@" "]) {
        return nil;
    }
    return footer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSDictionary *item = self.prefContents[indexPath.section][indexPath.row];

    if (indexPath.section == 0 || indexPath.section == 3) {
        [self tableView:tableView invokeActionAtIndexPath:indexPath];
        return;
    }
    // 1 and 2 handle themselves with picker views.
    
    return;
}

- (void)tableView:(UITableView *)tableView invokeActionAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section == 0) {
        [self actionMenuLoad];
        [self.tableView reloadData];
    } else if(indexPath.section == 3) {
        if(indexPath.row == 0) {
            setPreference(@"controller_type", @"xbox");
        } else if(indexPath.row == 1) {
            setPreference(@"controller_type", @"playstation");
        }
        NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)];
        [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITextField + UIPickerView

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = (UILabel *)view;
    if (label == nil) {
        label = [UILabel new];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.5;
        label.textAlignment = NSTextAlignmentCenter;
    }
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];

    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.activeTextField.text = [self.keyCodeMap objectAtIndex:row];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.keyCodeMap.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.keyCodeMap objectAtIndex:row];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UITableViewCell *cell = (UITableViewCell *)textField.superview;
    __block NSDictionary *item = objc_getAssociatedObject(cell.accessoryView, @"item");
    __block NSString *fullString = @"";
    __block NSArray *arrayToSave = nil;
    __block NSUInteger btnIndex = 0;
    __block NSString *index = @"";
    
    if(textField.tag == 1) {
        arrayToSave = self.prefMappings[0];
        index = @"mGameMappingList";
    } else if(textField.tag == 2) {
        arrayToSave = self.prefMappings[1];
        index = @"mMenuMappingList";
    }
    
    for(NSDictionary* mapping in arrayToSave) {
        if(item[@"gamepad_button"] == mapping[@"gamepad_button"]) {
            btnIndex = [arrayToSave indexOfObject:mapping];
            break;
        }
    }
    
    if(![textField.text hasPrefix:@"SPECIALBTN"]) {
        fullString = [@"GLFW_KEY_" stringByAppendingString:textField.text];
    } else {
        fullString = textField.text;
    }
    
    self.allMappings[index][btnIndex][@"keycode"] = [self.keycodePlist objectForKey:fullString];
    
    self.activeTextField = nil;
}

- (void)closeTextField:(UIBarButtonItem *)sender {
    [self.activeTextField endEditing:YES];
}

#pragma mark UI

- (void) dismissModalViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionOpenFilePicker:(void (^)(NSString *name))handler {
    FileListViewController *vc = [[FileListViewController alloc] init];
    vc.listPath = [NSString stringWithFormat:@"%s/controlmap/gamepads", getenv("POJAV_HOME")];
    
    vc.whenItemSelected = handler;
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);

    UIPopoverPresentationController *popoverController = [vc popoverPresentationController];
    popoverController.sourceView = self.tableView;
    popoverController.sourceRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)actionMenuLoad {
    [self actionOpenFilePicker:^void(NSString* name) {
        NSString *currentFile = [NSString stringWithFormat:@"%@.json", getPreference(@"default_gamepad_ctrl")];
        if(![currentFile isEqualToString:name]) {
            setPreference(@"default_gamepad_ctrl", [NSString stringWithFormat:@"%@.json", name]);
            self.prefMappings = [self loadGamepadConfigurationFile:YES shouldSkipImmutables:NO];
            self.prefMappingsTrimmed = [self loadGamepadConfigurationFile:NO shouldSkipImmutables:YES];
            [self.tableView reloadData];
        }
    }];
}

- (void)actionMenuSaveWithExit:(BOOL)exit {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:localize(@"custom_controls.control_menu.save", nil)
        message:exit?localize(@"custom_controls.control_menu.exit.warn", nil):@""
        preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Name";
        textField.text = self.currentFileName;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = controller.textFields;
        UITextField *field = textFields[0];
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.allMappings options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData == nil) {
            showDialog(self, localize(@"custom_controls.control_menu.save.error.json", nil), error.localizedDescription);
            return;
        }
        BOOL success = [jsonData writeToFile:[NSString stringWithFormat:@"%s/controlmap/gamepads/%@.json", getenv("POJAV_HOME"), field.text] options:NSDataWritingAtomic error:&error];
        if (!success) {
            showDialog(self, localize(@"custom_controls.control_menu.save.error.write", nil), error.localizedDescription);
            return;
        }

        if (exit) {
            [self dismissModalViewController];
        }

        setPreference(@"default_gamepad_ctrl", [NSString stringWithFormat:@"%@.json", field.text]);
    }]];
    if (exit) {
        [controller addAction:[UIAlertAction actionWithTitle:localize(@"custom_controls.control_menu.discard_changes", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self dismissModalViewController];
        }]];
    }
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)actionMenuSave {
    [self actionMenuSaveWithExit:NO];
}

- (void)exitButtonSelector {
    NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/%@", getenv("POJAV_HOME"), getPreference(@"default_gamepad_ctrl")];
    if([self.allMappings isEqualToDictionary:parseJSONFromFile(gamepadPath)]) {
        [self dismissModalViewController];
    } else {
        [self actionMenuSaveWithExit:YES];
    }
}

@end
