#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "input/ControllerInput.h"
#import "customcontrols/CustomControlsUtils.h"
#import "FileListViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefContCfgViewController.h"
#import "PickTextField.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include "glfw_keycodes.h"

#define contentNavigationController (LauncherNavigationController *)UIApplication.sharedApplication.keyWindow.rootViewController.splitViewController.viewControllers[1]

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);

@interface LauncherPrefContCfgViewController ()<UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property(nonatomic) NSString *currentFileName;
@property(nonatomic) NSMutableDictionary *currentMappings;
@property(nonatomic) NSDictionary *keycodePlist;
@property(nonatomic) UIPickerView *editPickMapping;
@property(nonatomic) UIToolbar *editPickToolbar;
@property(nonatomic) UITextField *activeTextField;
@property(nonatomic) NSArray<NSString*>* prefSections;
@property(nonatomic) NSMutableArray<NSNumber*>* prefSectionsVisibility;
@property(nonatomic) NSArray<NSDictionary*> *prefControllerTypes;
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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.sectionFooterHeight = 50;
    
    [self loadGamepadConfigurationFile];
    self.prefControllerTypes = @[@{@"name": @"xbox"}, @{@"name": @"playstation"}];
    
    self.prefSections = @[@"config_files", @"game_mappings", @"menu_mappings", @"controller_style"];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionMenuSave)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(exitButtonSelector)];
    
    self.editPickMapping = [[UIPickerView alloc] init];
    self.editPickMapping.delegate = self;
    self.editPickMapping.dataSource = self;
    self.editPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTextField:)];
    self.editPickToolbar.items = @[btnFlexibleSpace, editDoneButton];
}

- (void)loadGamepadConfigurationFile {
    NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/%@", getenv("POJAV_HOME"), getPrefObject(@"control.default_gamepad_ctrl")];
    self.currentMappings = parseJSONFromFile(gamepadPath);
    self.currentFileName = [getPrefObject(@"control.default_ctrl") stringByDeletingPathExtension];
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *dict) {
        return ![obj[@"name"] hasPrefix:@"mouse_"];
    }];
    [self.currentMappings[@"mGameMappingList"] filterUsingPredicate:filterPredicate];
    [self.currentMappings[@"mMenuMappingList"] filterUsingPredicate:filterPredicate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark External UITableView functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.prefSections.count;
}

- (NSArray *)prefContentForIndex:(NSInteger)index {
    switch (index) {
        case 0: return nil; // one single cell is defined in cellForRowAtIndexPath
        case 1: return self.currentMappings[@"mGameMappingList"];
        case 2: return self.currentMappings[@"mMenuMappingList"];
        case 3: return self.prefControllerTypes;
        default: return nil;
    } 
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return [self prefContentForIndex:section].count;
    }
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *item = [self prefContentForIndex:indexPath.section][indexPath.row];
    NSString *cellID = [NSString stringWithFormat:@"cellValue%ld", indexPath.section];
    UITableViewCellStyle cellStyle = UITableViewCellStyleValue1;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellID];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    if(indexPath.section == 0) {
        cell.textLabel.text = localize(@"controller_configurator.title.current", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = getPrefObject(@"control.default_gamepad_ctrl");
    } else if(indexPath.section == 1 || indexPath.section == 2) {
        NSNumber *keycode = (NSNumber *)item[@"keycode"];
        cell.textLabel.text = localize(([NSString stringWithFormat:@"controller_configurator.%@.title.%@", getPrefObject(@"control.controller_type"), item[@"name"]]), nil);
        UITextField *view = (id)cell.accessoryView;
        if (view == nil) {
            view = [[PickTextField alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width / 2.1, cell.bounds.size.height)];
            [view addTarget:view action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
            view.autocorrectionType = UITextAutocorrectionTypeNo;
            view.autocapitalizationType = UITextAutocapitalizationTypeNone;
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
            view.delegate = self;
            view.returnKeyType = UIReturnKeyDone;
            view.tag = indexPath.section;
            view.textAlignment = NSTextAlignmentRight;
            view.tintColor = UIColor.clearColor;
            view.adjustsFontSizeToFitWidth = YES;
            view.inputAccessoryView = self.editPickToolbar;
            view.inputView = self.editPickMapping;
            cell.accessoryView = view;
        }
        view.text = self.keyCodeMap[[self.keyValueMap indexOfObject:keycode]];
        objc_setAssociatedObject(view, @"gamepad_button", item[@"name"], OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(view, @"item", item, OBJC_ASSOCIATION_ASSIGN);
    } else if(indexPath.section == 3) {
        cell.textLabel.text = localize([NSString stringWithFormat:@"controller_configurator.title.type.%@", item[@"name"]], nil);
        if ([getPrefObject(@"control.controller_type") isEqualToString:item[@"name"]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return localize([NSString stringWithFormat:@"controller_configurator.section.%@", self.prefSections[section]], nil);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *key = [NSString stringWithFormat:@"controller_configurator.section.footer.%@", self.prefSections[section]];
    NSString *footer = localize(key, nil);
    return [footer isEqualToString:key] ? nil : footer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSDictionary *item = [self prefContentForIndex:indexPath.section][indexPath.row];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section == 0) {
        [self actionMenuLoad];
    } else if(indexPath.section == 3) {
        setPrefObject(@"control.controller_type", self.prefControllerTypes[indexPath.row][@"name"]);
        NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)];
        [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationNone];
    }
    // 1 and 2 handle themselves with picker views.
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
    [self.editPickMapping selectRow:[self.keyCodeMap indexOfObject:textField.text] inComponent:0 animated:NO];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UITableViewCell *cell = (UITableViewCell *)textField.superview;
    NSMutableDictionary *item = objc_getAssociatedObject(cell.accessoryView, @"item");
    if(![textField.text hasPrefix:@"SPECIALBTN"]) {
        item[@"keycode"] = self.keycodePlist[[@"GLFW_KEY_" stringByAppendingString:textField.text]];
    } else {
        item[@"keycode"] = self.keycodePlist[textField.text];
    }
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
        NSString *currentFile = [NSString stringWithFormat:@"%@.json", getPrefObject(@"control.default_gamepad_ctrl")];
        if(![currentFile isEqualToString:name]) {
            setPrefObject(@"control.default_gamepad_ctrl", [NSString stringWithFormat:@"%@.json", name]);
            [self loadGamepadConfigurationFile];
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
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.currentMappings options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData == nil) {
            showDialog(localize(@"custom_controls.control_menu.save.error.json", nil), error.localizedDescription);
            return;
        }
        BOOL success = [jsonData writeToFile:[NSString stringWithFormat:@"%s/controlmap/gamepads/%@.json", getenv("POJAV_HOME"), field.text] options:NSDataWritingAtomic error:&error];
        if (!success) {
            showDialog(localize(@"custom_controls.control_menu.save.error.write", nil), error.localizedDescription);
            return;
        }

        if (exit) {
            [self dismissModalViewController];
        }

        setPrefObject(@"control.default_gamepad_ctrl", [NSString stringWithFormat:@"%@.json", field.text]);
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
    NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/%@", getenv("POJAV_HOME"), getPrefObject(@"control.default_gamepad_ctrl")];
    if([self.currentMappings isEqualToDictionary:parseJSONFromFile(gamepadPath)]) {
        [self dismissModalViewController];
    } else {
        [self actionMenuSaveWithExit:YES];
    }
}

@end
