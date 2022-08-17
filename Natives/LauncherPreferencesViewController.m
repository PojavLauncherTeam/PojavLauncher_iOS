#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherViewController.h"

#include "utils.h"

#define BTNSCALE 0
#define RESOLUTION 1
#define ALLOCMEM 2
#define JARGS 3
#define REND 4
#define JHOME 5
#define GDIRECTORY 6

#define RESETWARN 8
#define TYPESEL 9
#define DEBUGLOG 10
#define MKGDIR 11
#define RMGDIR 12
#define SLIDEHOTBAR 13
#define SAFEAREA 14
#define HOMESYM 15
#define RELAUNCH 16
#define ERASEPREF 17
#define ARCCAPES 18
#define VIRTMOUSE 19
#define CHECKSHA 20
#define UNJBRAM 21

#define TAG_BTNSCALE 98
#define TAG_RESOLUTION 99
#define TAG_ALLOCMEM 100
#define TAG_JARGS 101

#define TAG_REND 102
#define TAG_PICKER_REND 142
#define TAG_DONE_REND 152

#define TAG_JHOME 103
#define TAG_PICKER_JHOME 143
#define TAG_DONE_JHOME 153

#define TAG_GDIR 104
#define TAG_PICKER_GDIR 144
#define TAG_DONE_GDIR 154

#define TAG_RESETWARN 106

#define TAG_SWITCH_VRELEASE 107
#define TAG_SWITCH_VSNAPSHOT 108
#define TAG_SWITCH_VOLDBETA 109
#define TAG_SWITCH_VOLDALPHA 110

#define TAG_DEBUGLOG 111
#define TAG_SLIDEHOTBAR 112

#define TAG_SAFEAREA 113

#define TAG_HOMESYM 114

#define TAG_RELAUNCH 115

#define TAG_ERASEPREF 116

#define TAG_ARCCAPES 117

#define TAG_VIRTMOUSE 118

#define TAG_CHECKSHA 119

#define TAG_UNJBRAM 120

@interface LauncherPreferencesViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate> {
}

// - (void)method

@end

@implementation LauncherPreferencesViewController

UITextField *jargsTextField;
UITextField *rendTextField;
UITextField *jhomeTextField;
UITextField *gdirTextField;
UITextField *activeField;
NSArray* rendererList;
NSMutableArray* gdirList;
NSArray* jhomeList;
UIPickerView* rendPickerView;
UIPickerView* gdirPickerView;
UIPickerView* jhomePickerView;
UISwitch *slideHotbarSwitch;
UIBlurEffect *blur;
UIVisualEffectView *blurView;
UIScrollView *scrollView;

NSDictionary *rendererDict;
NSArray *menuDict;

int tempIndex;

- (void)viewDidLoad
{
    [super viewDidLoad];
    setViewBackgroundColor(self.view);
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    CGFloat currY = 8.0;
    
    rendererDict = @{
        @"gl4es 1.1.4 - exports OpenGL 2.1": @"libgl4es_114.dylib",
        @"tinygl4angle (1.17+) - exports OpenGL 3.2 (Core Profile, limited)": @"libtinygl4angle.dylib",
        @"Zink (Mesa 21.0) - exports OpenGL 4.1": @"libOSMesaOverride.dylib"
    };
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 20, 0)];
    [scrollView addSubview:tableView];
    
    [self registerForKeyboardNotifications];
    
    blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    
    UILabel *btnsizeTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY, 0.0, 30.0)];
    btnsizeTextView.text = @"Button scale (%)";
    btnsizeTextView.numberOfLines = 0;
    btnsizeTextView.textAlignment = NSTextAlignmentCenter;
    [btnsizeTextView sizeToFit];
    CGRect tempRect = btnsizeTextView.frame;
    tempRect.size.height = 30.0;
    btnsizeTextView.frame = tempRect;
    [tableView addSubview:btnsizeTextView];
    
    DBNumberedSlider *buttonSizeSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(20.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 28.0, btnsizeTextView.frame.size.height)];
    buttonSizeSlider.tag = TAG_BTNSCALE;
    [buttonSizeSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [buttonSizeSlider setBackgroundColor:[UIColor clearColor]];
    buttonSizeSlider.minimumValue = 50.0;
    buttonSizeSlider.maximumValue = 500.0;
    buttonSizeSlider.continuous = YES;
    buttonSizeSlider.value = [getPreference(@"button_scale") floatValue];
    [tableView addSubview:buttonSizeSlider];
    
    UILabel *resolutionTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=43.0, 0.0, 30.0)];
    resolutionTextView.text = @"Resolution (%)";
    resolutionTextView.numberOfLines = 0;
    resolutionTextView.textAlignment = NSTextAlignmentCenter;
    [resolutionTextView sizeToFit];
    tempRect = resolutionTextView.frame;
    tempRect.size.height = 30.0;
    resolutionTextView.frame = tempRect;
    [tableView addSubview:resolutionTextView];
    
    DBNumberedSlider *resolutionSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(20.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 28.0, resolutionTextView.frame.size.height)];
    resolutionSlider.tag = TAG_RESOLUTION;
    [resolutionSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [resolutionSlider setBackgroundColor:[UIColor clearColor]];
    resolutionSlider.minimumValue = 25;
    resolutionSlider.maximumValue = 150;
    resolutionSlider.continuous = YES;
    resolutionSlider.value = [getPreference(@"resolution") intValue];
    [tableView addSubview:resolutionSlider];
    
    
    if(getenv("POJAV_DETECTEDJB") || [getPreference(@"ram_unjb_enable") boolValue] == YES) {
        // You cannot bypass jetsam memory limits unjailbroken
        // Use with caution on unjailbroken devices
        UILabel *memTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=45.0, 0.0, 30.0)];
        memTextView.text = @"Allocated RAM";
        memTextView.numberOfLines = 0;
        memTextView.textAlignment = NSTextAlignmentCenter;
        [memTextView sizeToFit];
        tempRect = memTextView.frame;
        tempRect.size.height = 30.0;
        memTextView.frame = tempRect;
        [tableView addSubview:memTextView];
    
        DBNumberedSlider *memSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(20.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 28.0, resolutionTextView.frame.size.height)];
        memSlider.tag = TAG_ALLOCMEM;
        [memSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [memSlider setBackgroundColor:[UIColor clearColor]];
        memSlider.minimumValue = roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.25);
        memSlider.maximumValue = roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.85);
        memSlider.fontSize = 10;
        memSlider.continuous = YES;
        memSlider.value = [getPreference(@"allocated_memory") intValue];
        [tableView addSubview:memSlider];
    }
    UILabel *jargsTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=47.0, 0.0, 0.0)];
    jargsTextView.text = @"Java arguments  ";
    jargsTextView.numberOfLines = 0;
    [jargsTextView sizeToFit];
    [tableView addSubview:jargsTextView];

    jargsTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [jargsTextField addTarget:jargsTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [jargsTextField setReturnKeyType:UIReturnKeyDone];
    jargsTextField.tag = TAG_JARGS;
    jargsTextField.delegate = self;
    jargsTextField.placeholder = @"Specify arguments...";
    jargsTextField.text = (NSString *) getPreference(@"java_args");
    jargsTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    jargsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jargsTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:jargsTextField];

    UILabel *rendTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    rendTextView.text = @"Renderer";
    rendTextView.numberOfLines = 0;
    [rendTextView sizeToFit];
    [tableView addSubview:rendTextView];

    rendTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [rendTextField addTarget:rendTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    rendTextField.tag = TAG_REND;
    rendTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    rendTextField.delegate = self;
    rendTextField.placeholder = @"Override renderer...";
    //rendTextField.text = self.rendererDict[getPreference(@"renderer")];
    tempIndex = [rendererDict.allValues indexOfObject:getPreference(@"renderer")];
    rendTextField.text = rendererDict.allKeys[tempIndex];

    rendTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    rendTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:rendTextField];

    //[rendererList addObject:virglrenderer];

    rendPickerView = [[UIPickerView alloc] init];
    rendPickerView.delegate = self;
    rendPickerView.dataSource = self;
    rendPickerView.tag = TAG_PICKER_REND;
    [rendPickerView reloadAllComponents];
    [rendPickerView selectRow:tempIndex inComponent:0 animated:NO];
    UIToolbar *rendPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *rendFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *rendDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    rendDoneButton.tag = TAG_DONE_REND;
    rendPickerToolbar.items = @[rendFlexibleSpace, rendDoneButton];

    rendTextField.inputAccessoryView = rendPickerToolbar;
    rendTextField.inputView = rendPickerView;

    UILabel *jhomeTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    jhomeTextView.text = @"Java version";
    jhomeTextView.numberOfLines = 0;
    [jhomeTextView sizeToFit];
    [tableView addSubview:jhomeTextView];
    
    jhomeTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [jhomeTextField addTarget:jhomeTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jhomeTextField.tag = TAG_JHOME;
    jhomeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    jhomeTextField.delegate = self;
    jhomeTextField.placeholder = @"Override Java path...";
    
    jhomeTextField.text = [getPreference(@"java_home") lastPathComponent];
    
    jhomeTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jhomeTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:jhomeTextField];
    
    NSString *listPath = getenv("POJAV_DETECTEDJB") ? @"/usr/lib/jvm" : [NSString stringWithFormat:@"%s/jvm", getenv("BUNDLE_PATH")];
    jhomeList = [NSFileManager.defaultManager contentsOfDirectoryAtPath:listPath error:nil];
    
    jhomePickerView = [[UIPickerView alloc] init];
    jhomePickerView.delegate = self;
    jhomePickerView.dataSource = self;
    jhomePickerView.tag = TAG_PICKER_JHOME;
    [jhomePickerView reloadAllComponents];
    for (int i = 0; i < jhomeList.count; i++) {
        if ([jhomeTextField.text isEqualToString:jhomeList[i]]) {
            [jhomePickerView selectRow:i inComponent:0 animated:NO];
            break;
        }
    }
    UIToolbar *jhomePickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *jhomeFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *jhomeDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    jhomeDoneButton.tag = TAG_DONE_JHOME;
    jhomePickerToolbar.items = @[jhomeFlexibleSpace, jhomeDoneButton];
    
    jhomeTextField.inputAccessoryView = jhomePickerToolbar;
    jhomeTextField.inputView = jhomePickerView;
    
    UILabel *gdirTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    gdirTextView.text = @"Game directory";
    gdirTextView.numberOfLines = 0;
    [gdirTextView sizeToFit];
    [tableView addSubview:gdirTextView];

    gdirTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [gdirTextField addTarget:jhomeTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    gdirTextField.tag = TAG_GDIR;
    gdirTextField.delegate = self;
    gdirTextField.placeholder = @"Custom game directory...";
    gdirTextField.text = (NSString *) getPreference(@"game_directory");
    gdirTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    gdirTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:gdirTextField];

    gdirPickerView = [[UIPickerView alloc] init];
    gdirPickerView.delegate = self;
    gdirPickerView.dataSource = self;
    gdirPickerView.tag = TAG_PICKER_GDIR;
    [self instanceDirCont];
    UIToolbar *gdirPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *gdirFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *gdirDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    UIBarButtonItem *gdirCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Create new" style:UIBarButtonItemStyleDone target:self action:@selector(createDir:)];
    UIBarButtonItem *gdirDeleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleDone target:self action:@selector(removeDir:)];
    gdirDoneButton.tag = TAG_DONE_GDIR;
    gdirPickerToolbar.items = @[gdirCreateButton, gdirDeleteButton, gdirFlexibleSpace, gdirDoneButton];

    gdirTextField.inputAccessoryView = gdirPickerToolbar;
    gdirTextField.inputView = gdirPickerView;

    UILabel *slideHotbarTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    slideHotbarTextView.text = @"Slideable hotbar";
    slideHotbarTextView.numberOfLines = 0;
    [slideHotbarTextView sizeToFit];
    [tableView addSubview:slideHotbarTextView];

    slideHotbarSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    slideHotbarSwitch.tag = TAG_SLIDEHOTBAR;
    [slideHotbarSwitch setOn:[getPreference(@"slideable_hotbar") boolValue] animated:NO];
    [slideHotbarSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:slideHotbarSwitch];
    
    UILabel *resetWarnTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    resetWarnTextView.text = @"Reset launcher warnings";
    resetWarnTextView.numberOfLines = 0;
    [resetWarnTextView sizeToFit];
    [tableView addSubview:resetWarnTextView];

    UISwitch *resetWarnSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    resetWarnSwitch.tag = TAG_RESETWARN;
    [resetWarnSwitch setOn:NO animated:NO];
    [resetWarnSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:resetWarnSwitch];
    
    UILabel *checkSHATextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    checkSHATextView.text = @"Check game files before launching";
    checkSHATextView.numberOfLines = 0;
    [checkSHATextView sizeToFit];
    [tableView addSubview:checkSHATextView];

    UISwitch *checkSHASwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    checkSHASwitch.tag = TAG_CHECKSHA;
    [checkSHASwitch setOn:[getPreference(@"check_sha") boolValue] animated:NO];
    [checkSHASwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:checkSHASwitch];
    
    UILabel *debugLogTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    debugLogTextView.text = @"Enable debug logging";
    debugLogTextView.numberOfLines = 0;
    [debugLogTextView sizeToFit];
    [tableView addSubview:debugLogTextView];

    UISwitch *debugLogSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    debugLogSwitch.tag = TAG_DEBUGLOG;
    [debugLogSwitch setOn:[getPreference(@"debug_logging") boolValue] animated:NO];
    [debugLogSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:debugLogSwitch];
    
    if(getenv("POJAV_DETECTEDJB")) {
        // Used for legacy iOS users who are used to
        // the old home directory for the game
        // TODO: Remove for everyone
        UILabel *homesymTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
        homesymTextView.text = @"Disable home symlink";
        homesymTextView.numberOfLines = 0;
        [homesymTextView sizeToFit];
        [tableView addSubview:homesymTextView];
        
        UISwitch *homesymSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
        homesymSwitch.tag = TAG_HOMESYM;
        [homesymSwitch setOn:[getPreference(@"disable_home_symlink") boolValue] animated:NO];
        [homesymSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [tableView addSubview:homesymSwitch];
    }
    
    UILabel *relaunchTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    relaunchTextView.text = @"Restart before launching game";
    relaunchTextView.numberOfLines = 0;
    [relaunchTextView sizeToFit];
    [tableView addSubview:relaunchTextView];

    UISwitch *relaunchSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    relaunchSwitch.tag = TAG_RELAUNCH;
    [relaunchSwitch setOn:[getPreference(@"restart_before_launch") boolValue] animated:NO];
    [relaunchSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:relaunchSwitch];
    
    UILabel *arcCapesTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    arcCapesTextView.text = @"Enable Cosmetica capes";
    arcCapesTextView.numberOfLines = 0;
    [arcCapesTextView sizeToFit];
    [tableView addSubview:arcCapesTextView];

    UISwitch *arcCapesSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    arcCapesSwitch.tag = TAG_ARCCAPES;
    [arcCapesSwitch setOn:[getPreference(@"arccapes_enable") boolValue] animated:NO];
    [arcCapesSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:arcCapesSwitch];
    
    UILabel *virtMouseTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    virtMouseTextView.text = @"Enable virtual mouse";
    virtMouseTextView.numberOfLines = 0;
    [virtMouseTextView sizeToFit];
    [tableView addSubview:virtMouseTextView];

    UISwitch *virtMouseSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    virtMouseSwitch.tag = TAG_VIRTMOUSE;
    [virtMouseSwitch setOn:[getPreference(@"virtmouse_enable") boolValue]  animated:NO];
    [virtMouseSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:virtMouseSwitch];
    
    UILabel *erasePrefTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    erasePrefTextView.text = @"Reset all settings";
    erasePrefTextView.numberOfLines = 0;
    [erasePrefTextView sizeToFit];
    [tableView addSubview:erasePrefTextView];
    
    UISwitch *erasePrefSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    erasePrefSwitch.tag = TAG_ERASEPREF;
    [erasePrefSwitch setOn:NO animated:NO];
    [erasePrefSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:erasePrefSwitch];
    
    if(!getenv("POJAV_DETECTEDJB")) {
        UILabel *enableRAMTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
        enableRAMTextView.text = @"Enable RAM slider";
        enableRAMTextView.numberOfLines = 0;
        [enableRAMTextView sizeToFit];
        [tableView addSubview:enableRAMTextView];

        UISwitch *enableRAMSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
        enableRAMSwitch.tag = TAG_UNJBRAM;
        [enableRAMSwitch setOn:[getPreference(@"ram_unjb_enable") boolValue] animated:NO];
        [enableRAMSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [tableView addSubview:enableRAMSwitch];
    }
    
    CGRect frame = tableView.frame;
    frame.size.height = currY+=44;
    tableView.frame = frame;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, tableView.frame.size.height);
    
    if (@available(iOS 14.0, *)) {
        // use UIMenu
        UIBarButtonItem *help = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"questionmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"xmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(exitAppAlert)];
        self.navigationItem.rightBarButtonItems = @[help, close];
        UIAction *buttonScale = [UIAction actionWithTitle:@"Button scale" image:[[UIImage systemImageNamed:@"aspectratio"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        UIAction *resolution = [UIAction actionWithTitle:@"Resolution" image:[[UIImage systemImageNamed:@"viewfinder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        UIAction *allocRAM = [UIAction actionWithTitle:@"Allocated RAM" image:[[UIImage systemImageNamed:@"memorychip"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:ALLOCMEM];}];
        UIAction *jargs = [UIAction actionWithTitle:@"Java arguments" image:[[UIImage systemImageNamed:@"character.cursor.ibeam"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAction *renderer = [UIAction actionWithTitle:@"Renderer" image:[[UIImage systemImageNamed:@"cpu"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAction *jversion = [UIAction actionWithTitle:@"Java version" image:[[UIImage systemImageNamed:@"cube"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAction *gamedir = [UIAction actionWithTitle:@"Game directory" image:[[UIImage systemImageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}];
        UIAction *hotbar = [UIAction actionWithTitle:@"Slideable hotbar" image:[[UIImage systemImageNamed:@"slider.horizontal.below.rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:SLIDEHOTBAR];}];
        UIAction *resetwarn = [UIAction actionWithTitle:@"Reset warnings" image:[[UIImage systemImageNamed:@"exclamationmark.triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESETWARN];}];
        UIAction *shacheck = [UIAction actionWithTitle:@"Check game files before launching" image:[[UIImage systemImageNamed:@"shield.lefthalf.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:CHECKSHA];}];
        UIAction *safearea = [UIAction actionWithTitle:@"Safe area" image:[[UIImage systemImageNamed:@"crop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:SAFEAREA];}];
        UIAction *debugLog = [UIAction actionWithTitle:@"Debug logging" image:[[UIImage systemImageNamed:@"doc.badge.gearshape"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:DEBUGLOG];}];
        UIAction *restart = [UIAction actionWithTitle:@"Restart before launching game" image:[[UIImage systemImageNamed:@"arrowtriangle.left.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RELAUNCH];}];
        UIAction *symlink = [UIAction actionWithTitle:@"Home symlink" image:[[UIImage systemImageNamed:@"link"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:HOMESYM];}];
        UIAction *cosmetica = [UIAction actionWithTitle:@"Enable Cosmetica capes" image:[[UIImage systemImageNamed:@"square.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:ARCCAPES];}];
        UIAction *virtmouse = [UIAction actionWithTitle:@"Enable virtual mouse" image:[[UIImage systemImageNamed:@"cursorarrow.rays"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:VIRTMOUSE];}];
        UIAction *resetprefs = [UIAction actionWithTitle:@"Reset preferences" image:[[UIImage systemImageNamed:@"trash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:ERASEPREF];}];
        UIAction *enableRAM = [UIAction actionWithTitle:@"Enable RAM slider" image:[[UIImage systemImageNamed:@"slider.horizontal.3"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:UNJBRAM];}];
        
        if(getenv("POJAV_DETECTEDJB")) {
            menuDict = @[buttonScale, resolution, allocRAM, jargs, renderer, jversion, gamedir, hotbar, resetwarn, shacheck, safearea, debugLog, restart, symlink, cosmetica, virtmouse, resetprefs];
        } else if(!getenv("POJAV_DETECTEDJB") && [getPreference(@"disable_home_symlink") boolValue] == YES) {
            menuDict = @[buttonScale, resolution, allocRAM, jargs, renderer, jversion, gamedir, hotbar, resetwarn, shacheck, safearea, debugLog, restart, symlink, cosmetica, virtmouse, resetprefs, enableRAM];
        } else {
            menuDict = @[buttonScale, resolution, jargs, renderer, jversion, gamedir, hotbar, resetwarn, shacheck, safearea, debugLog, restart, symlink, cosmetica, virtmouse, resetprefs, enableRAM];
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:menuDict];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        UIBarButtonItem *help = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close App" style:UIBarButtonItemStyleDone target:self action:@selector(exitApp)];
        self.navigationItem.rightBarButtonItems = @[help, close];
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(keyboardWasShown:)
            name:UIKeyboardDidShowNotification object:nil];
 
    [[NSNotificationCenter defaultCenter] addObserver:self
             selector:@selector(keyboardWillBeHidden:)
             name:UIKeyboardWillHideNotification object:nil];
 
}
 
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
 
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeField = nil;
    if (textField.tag == TAG_JARGS) {
        setPreference(@"java_args", textField.text);
    } else if (textField.tag == TAG_REND) {
        setPreference(@"renderer", rendererDict[textField.text]);
        setenv("POJAV_RENDERER", [getPreference(@"renderer") UTF8String], 1);
    } else if (textField.tag == TAG_JHOME) {
        NSString *listPath = getenv("POJAV_DETECTEDJB") ? @"/usr/lib/jvm" : [NSString stringWithFormat:@"%s/jvm", getenv("BUNDLE_PATH")];
        setPreference(@"java_home", [NSString stringWithFormat:@"%@/%@", listPath, textField.text]);
        setenv("JAVA_HOME", [getPreference(@"java_home") UTF8String], 1);
        if (![textField.text containsString:JRE8_NAME_JB] && ![textField.text containsString:JRE8_NAME_SB] && [getPreference(@"java_warn") boolValue] == YES) {
            UIAlertController *javaAlert = [UIAlertController alertControllerWithTitle:@"Java version is not Java 8" message:@"Minecraft versions below 1.6, modded below 1.16.4, and the mod installer will not work unless you have Java 8 installed on your device." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:javaAlert animated:YES completion:nil];
            [javaAlert addAction:ok];
            setPreference(@"java_warn", @NO);
        }
    } else if (textField.tag == TAG_GDIR) {
        setPreference(@"game_directory", textField.text);
        init_setupMultiDir();
    }
}

- (void)exitAppAlert {
    UIAlertController *closeAlert = [UIAlertController alertControllerWithTitle:@"Close PojavLauncher?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *close = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self exitApp];}];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    [closeAlert addAction:cancel];
    [closeAlert addAction:close];
    [self presentViewController:closeAlert animated:YES completion:nil];

}

- (void)exitApp {
    [blurView setFrame:[[self view] bounds]];
    [blurView setAlpha:0];
    [self.view addSubview:blurView];
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [blurView setAlpha:1];
    } completion:^(BOOL finished) {
        exit(0);
    }];
}

-(void)instanceDirCont {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray* files = [fm contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%s/instances", getenv("POJAV_HOME")] error:nil];
    if (gdirList == nil) {
        gdirList = [NSMutableArray arrayWithCapacity:10];
    } else {
        [gdirList removeAllObjects];
    }
    BOOL updateTempIndex = YES;
    tempIndex = 0;
    for(NSString *file in files) {
        NSString *path = [[NSString stringWithFormat:@"%s/instances", getenv("POJAV_HOME")] stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fm fileExistsAtPath:path isDirectory:(&isDir)];
        if(isDir) {
            [gdirList addObject:file];
            if ([file isEqualToString:gdirTextField.text]) {
                updateTempIndex = NO;
            }
            if (updateTempIndex) {
                ++tempIndex;
            }
        }
    }
    [gdirPickerView reloadAllComponents];
    [gdirPickerView selectRow:tempIndex inComponent:0 animated:NO];
}

- (void)createDir:(UIBarButtonItem *)sender {
    int type = MKGDIR;
    UIAlertController *manageDirAC = [UIAlertController alertControllerWithTitle:@"Create a new game directory" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [manageDirAC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Name of new directory";
        textField.secureTextEntry = NO;
    }];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *directory = [NSString stringWithFormat:@"%s/instances/%@", getenv("POJAV_HOME"), [[manageDirAC textFields][0] text]];
        NSError *error;
        BOOL isDir = NO;
        if([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [self instanceDirCont];
            gdirTextField.text = [[manageDirAC textFields][0] text];
            [gdirTextField endEditing:YES];
        }
        [self manageDirResult:(UIButton *)sender error:error directory:[[manageDirAC textFields][0] text] type:type];
    }];
    [manageDirAC addAction:confirm];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [manageDirAC addAction:cancel];
    [self presentViewController:manageDirAC animated:YES completion:nil];
}
- (void)removeDir:(UIBarButtonItem *)sender {
    int type = RMGDIR;
    if(![gdirTextField.text isEqualToString:@"default"]) {
    UIAlertController *manageDirAC = [UIAlertController alertControllerWithTitle:@"Are you sure you want to delete this?" message:[NSString stringWithFormat:@"The instance %@ will be deleted forever and cannot be restored.", gdirTextField.text] preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *directory = [NSString stringWithFormat:@"%s/instances/%@", getenv("POJAV_HOME"), gdirTextField.text];
        NSLog(@"%@", directory);
        NSError *error;
        BOOL isDir = NO;
        if([[NSFileManager defaultManager] removeItemAtPath:directory error:&error]) {
            [self instanceDirCont];
            gdirTextField.text = @"default";
            [gdirTextField endEditing:YES];
        }
        [self manageDirResult:(UIButton *)sender error:error directory:gdirTextField.text type:type];
    }];
    [manageDirAC addAction:confirm];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [manageDirAC addAction:cancel];
    [self presentViewController:manageDirAC animated:YES completion:nil];
    } else if([gdirTextField.text isEqualToString:@"default"]){
        UIAlertController *gdirAlert = [UIAlertController alertControllerWithTitle:@"You cannot delete the default game directory." message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        [self setPopoverProperties:gdirAlert.popoverPresentationController sender:(UIButton *)sender];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [gdirAlert addAction:ok];
        [self presentViewController:gdirAlert animated:YES completion:nil];
    }
}

- (void)manageDirResult:(UIButton *)sender error:(NSError *)error directory:(NSString *)dirName type:(int)type {
    NSString *title;
    NSString *message;
    if (error == nil) {
        if(type == MKGDIR) {
            title = @"Successfully changed directory.";
        } else if (type == RMGDIR) {
            title = @"Successfully removed directory.";
        }
    } else {
        title = @"An error occurred.";
        message = error.localizedDescription;
    }

    UIAlertController *gdirAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [self setPopoverProperties:gdirAlert.popoverPresentationController sender:sender];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [gdirAlert addAction:ok];
    [self presentViewController:gdirAlert animated:YES completion:nil];
}

- (void)helpMenu {
    if (@available(iOS 14.0, *)) {
        // UIMenu
    } else {
        UIAlertController *helpAlert = [UIAlertController alertControllerWithTitle:@"Needing help with these preferences?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *btnscale = [UIAlertAction actionWithTitle:@"Button scale" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        [helpAlert addAction:btnscale];
        UIAlertAction *resolution = [UIAlertAction actionWithTitle:@"Resolution" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        [helpAlert addAction:resolution];
        if(getenv("POJAV_DETECTEDJB") || [getPreference(@"disable_home_symlink") boolValue] == YES) {
            UIAlertAction *allocmem = [UIAlertAction actionWithTitle:@"Allocated RAM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:ALLOCMEM];}];
            [helpAlert addAction:allocmem];
        }
        UIAlertAction *jargs = [UIAlertAction actionWithTitle:@"Java arguments" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        [helpAlert addAction:jargs];
        UIAlertAction *renderer = [UIAlertAction actionWithTitle:@"Renderer"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        [helpAlert addAction:renderer];
        if(getenv("POJAV_DETECTEDJB")) {
            UIAlertAction *jhome = [UIAlertAction actionWithTitle:@"Java version" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
            [helpAlert addAction:jhome];
        }
        UIAlertAction *gdirectory = [UIAlertAction actionWithTitle:@"Game directory"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}];
        [helpAlert addAction:gdirectory];
        UIAlertAction *slidehotbar = [UIAlertAction actionWithTitle:@"Slideable hotbar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:SLIDEHOTBAR];}];
        [helpAlert addAction:slidehotbar];
        UIAlertAction *resetwarn = [UIAlertAction actionWithTitle:@"Reset warnings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RESETWARN];}];
        [helpAlert addAction:resetwarn];
        UIAlertAction *checksha = [UIAlertAction actionWithTitle:@"Check game files before launching" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:VIRTMOUSE];}];
        [helpAlert addAction:checksha];
        UIAlertAction *safearea = [UIAlertAction actionWithTitle:@"Safe area" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:SAFEAREA];}];
        [helpAlert addAction:safearea];
        UIAlertAction *debuglog = [UIAlertAction actionWithTitle:@"Debug logging" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:DEBUGLOG];}];
        [helpAlert addAction:debuglog];
        UIAlertAction *relaunch = [UIAlertAction actionWithTitle:@"Restart before launching game" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RELAUNCH];}];
        [helpAlert addAction:relaunch];
        if(getenv("POJAV_DETECTEDJB")) {
            UIAlertAction *homesym = [UIAlertAction actionWithTitle:@"Home symlink" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:HOMESYM];}];
            [helpAlert addAction:homesym];
        }
        UIAlertAction *arccapes = [UIAlertAction actionWithTitle:@"Enable Cosmetica capes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:ARCCAPES];}];
        [helpAlert addAction:arccapes];
        UIAlertAction *virtmouse = [UIAlertAction actionWithTitle:@"Enable virtual mouse" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:VIRTMOUSE];}];
        [helpAlert addAction:virtmouse];
        UIAlertAction *erasepref = [UIAlertAction actionWithTitle:@"Reset preferences" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:ERASEPREF];}];
        [helpAlert addAction:erasepref];
        if(!getenv("POJAV_DETECTEDJB")) {
            UIAlertAction *enableRAM = [UIAlertAction actionWithTitle:@"Enable RAM slider" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:UNJBRAM];}];
            [helpAlert addAction:enableRAM];
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [helpAlert addAction:cancel];
        [self setPopoverProperties:helpAlert.popoverPresentationController sender:(UIButton *)self.navigationItem.rightBarButtonItem];
        [self presentViewController:helpAlert animated:YES completion:nil];
    }
}

- (void)helpAlertOpt:(int)setting {
    NSString *title;
    NSString *message;
    if(setting == BTNSCALE) {
        title = @"Button scale";
        message = @"This option allows you to tweak the button scale of the on-screen controls. The numbered slider extends from 50 to 500.";
    } else if(setting == RESOLUTION) {
        title = @"Resolution";
        message = @"This option allows you to downscale the resolution of the game. Reducing resolution reduces GPU workload for better performance. The minimum resolution scale is 25%.";
    } else if(setting == ALLOCMEM) {
        title = @"Allocated RAM";
        if(getenv("POJAV_DETECTEDJB")) {
            message = @"This option allows you to change the amount of memory used by the game. The minimum is 25% (default) and the maximum is 85%. To be safe, any value over 40% will require a tool like jetsamctl to prevent memory crashes.";
        } else if (!(getenv("POJAV_DETECTEDJB") && ![getPreference(@"disable_home_symlink") boolValue] == YES)){
            message = @"This option allows you to change the amount of memory used by the game. This option is disabled by default on unjailbroken devices due to potential instability of the launcher.";
        } else {
            message = @"This option allows you to change the amount of memory used by the game. The minimum is 25% (default) and the maximum is 85%. Use this at your own risk while unjailbroken, as it can cause instability or break launching the game entirely.";
        }
    } else if(setting == JARGS) {
        title = @"Java arguments";
        message = @"This option allows you to edit arguments that can be passed to Minecraft. Not all arguments work with PojavLauncher, so be aware.";
    } else if(setting == REND) {
        title = @"Renderer";
        message = @"This option allows you to change the renderer in use. Choosing  tinygl4angle will allow 1.17+ to be played, but will also not work with older versions.";
    } else if(setting == JHOME) {
        title = @"Java version";
        if(getenv("POJAV_DETECTEDJB")) {
        message = @"This option allows you to change the Java executable directory. Choosing Java 16 or Java 17 may allow you to play 1.17, however older versions and most versions of modded Minecraft, as well as the mod installer, will not work.";
        } else {
            message = @"This option is disabled when running PojavLauncher unjailbroken.";
        }
    } else if(setting == GDIRECTORY) {
        title = @"Game directory";
        message = @"This option allows you to change where your Minecraft settings and saves are stored in a MultiMC like fashion. Useful for when you want to have multiple mod loaders installed but do not want to delete/move mods around to switch.";
    } else if(setting == SLIDEHOTBAR) {
        title = @"Slideable hotbar";
        message = @"This option allows you to use a finger to slide between hotbar slots.";
    } else if(setting == SAFEAREA) {
        title = @"Safe area";
        message = @"This option moves the game surface area into a safe area instead of fullscreen. This option is only available for iPhones with notch.";
    } else if(setting == RESETWARN) {
        title = @"Reset warnings";
        message = @"This option re-enables all warnings to be shown again.";
    } else if(setting == TYPESEL) {
        title = @"Type switches";
        message = @"These switches allow to to change where or not releases, snapshots, old betas, and old alphas will show up in the version selection menu.";
    } else if(setting == CHECKSHA) {
        title = @"Check game files before launching"; 
        message = @"When this option is enabled, every file is validated with SHA1, therefore local modifications will be overwritten.";
    } else if(setting == DEBUGLOG) {
        title = @"Enable debug logging";
        message = @"This option logs internal settings and actions to latestlog.txt. This helps the developers find issues easier, but Minecraft may run slower as the logs will be written to more often.";
    } else if(setting == HOMESYM) {
        title = @"Disable home symlink";
        if(getenv("POJAV_DETECTEDJB")) {
            message = @"This option disables the home symlink to /var/mobile/Documents/.pojavlauncher from the new game directory. This is used for legacy add-ons to continue working, and as a transition from the old 1.2 directory structure.";
        } else {
            message = @"This option is disabled when running PojavLauncher unjailbroken.";
        }
    } else if(setting == RELAUNCH) {
        title = @"Restart before launching game";
        message = @"This option allows the launcher to restart itself before launching the game, therefore all changes are applied such as JVM Arguments and Java version. The restart mechanism doesn't always work, so a toggle is here for now.";
    } else if (setting == ERASEPREF) {
        title = @"Reset preferences";
        message = @"This option resets the launcher preferences to their initial state.";
    } else if (setting == ARCCAPES) {
        title = @"Enable Cosmetica capes";
        message = @"This option allows you to switch from the OptiFine cape service to Cosmetica. See more about Cosmetica on our website.";
    } else if (setting == VIRTMOUSE) {
        title = @"Enable virtual mouse";
        message = @"This option allows you to enable or disable the virtual mouse pointer at launch of the game.";
    } else if (setting == UNJBRAM){
        title = @"Enable RAM slider";
        message = @"This option allows you to enable or disable the Allocated RAM slider when unjailbroken. See \"Allocated RAM\" for more information.";
    } else {
        title = @"Error";
        message = [NSString stringWithFormat:@"The setting %d hasn't been specified with a description.", setting];
    }
    UIAlertController *helpAlertOpt = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [self setPopoverProperties:helpAlertOpt.popoverPresentationController sender:(UIButton *)self.navigationItem.rightBarButtonItem];
    [helpAlertOpt addAction:ok];
    [self presentViewController:helpAlertOpt animated:YES completion:nil];
}

- (void)sliderMoved:(DBNumberedSlider *)sender {
    float memVal;
    switch (sender.tag) {
        case TAG_BTNSCALE:
            setPreference(@"button_scale", @((int)sender.value));
            break;
        case TAG_RESOLUTION:
            setPreference(@"resolution", @((int)sender.value));
            break;
        case TAG_ALLOCMEM:
            memVal = roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.40);
            if(sender.value >= memVal && [getPreference(@"mem_warn") boolValue] == YES) {
                NSString *title = @"High memory value selected.";
                NSString *message;
                if(getenv("POJAV_DETECTEDJB")) {
                    message = @"Due to limitations in the operating system itself, you will need to use a tool like overb0ard to prevent jetsam crashes.";
                } else {
                    message = @"Due to limitations in the operating system itself, this option may cause instability at this and higher values. Proceed with caution.";
                }
                UIAlertController *memAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:memAlert.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:memAlert animated:YES completion:nil];
                [memAlert addAction:ok];
                setPreference(@"mem_warn", @NO);
            }
            setPreference(@"allocated_memory", @((int)sender.value));
            break;
        default:
            NSLog(@"what does slider %ld for? implement me!", sender.tag);
            break;
    }
}

- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case TAG_RESETWARN:
            setPreference(@"mem_warn", @YES);
            setPreference(@"option_warn", @YES);
            setPreference(@"local_warn", @YES);
            setPreference(@"java_warn", @YES);
            setPreference(@"jb_warn", @YES);
            setPreference(@"customctrl_warn", @YES);
            setPreference(@"int_warn", @YES);
            setPreference(@"ram_unjb_warn", @YES);
            {
            UIAlertController *resetWarn = [UIAlertController alertControllerWithTitle:@"Warnings reset." message:@"Restart to show warnings again." preferredStyle:UIAlertControllerStyleActionSheet];
            [self setPopoverProperties:resetWarn.popoverPresentationController sender:(UIButton *)sender];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:resetWarn animated:YES completion:nil];
            [resetWarn addAction:ok];
            }
            break;
        case TAG_SLIDEHOTBAR:
            setPreference(@"slideable_hotbar", @(sender.isOn));
            break;
        case TAG_CHECKSHA:
            setPreference(@"check_sha", @(sender.isOn));
            break;
        case TAG_DEBUGLOG:
            setPreference(@"debug_logging", @(sender.isOn));
            break;
        case TAG_HOMESYM:
            setPreference(@"disable_home_symlink", @(sender.isOn));
            if([getPreference(@"disable_home_symlink") boolValue] == YES){
                NSString *message = [NSString stringWithFormat:@"This will remove the link at /var/mobile/Documents/.pojavlauncher. The new directory is %s.", getenv("POJAV_HOME")];
                UIAlertController *homesymWarn = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:message preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:homesymWarn.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Documents/.pojavlauncher" error:nil];}];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:homesymWarn animated:YES completion:nil];
                [homesymWarn addAction:cancel];
                [homesymWarn addAction:ok];
            } else {
                NSString *message = [NSString stringWithFormat:@"This will create a link to %s at /var/mobile/Documents/.pojavlauncher. This option will be removed in a future release.", getenv("POJAV_HOME")];
                UIAlertController *homesymWarn = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:message preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:homesymWarn.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {symlink("/usr/share/pojavlauncher", "/var/mobile/Documents/.pojavlauncher");}];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:homesymWarn animated:YES completion:nil];
                [homesymWarn addAction:cancel];
                [homesymWarn addAction:ok];
            }
            break;
        case TAG_RELAUNCH:
            setPreference(@"restart_before_launch", @(sender.isOn));
            break;
        case TAG_ERASEPREF:
            {
            NSString *prefFile = [NSString stringWithFormat:@"%s/launcher_preferences.plist", getenv("POJAV_HOME")];
            UIAlertController *eraseprefWarn = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"This will remove all of your custom preferences, including resolution, button size, and Java arguments." preferredStyle:UIAlertControllerStyleActionSheet];
            [self setPopoverProperties:eraseprefWarn.popoverPresentationController sender:(UIButton *)sender];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSFileManager defaultManager] removeItemAtPath:prefFile error:nil];
                UIAlertController *eraseprefPost = [UIAlertController alertControllerWithTitle:@"Preferences reset" message:@"The next time you open PojavLauncher, all of the default settings will be restored." preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:eraseprefWarn.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:eraseprefPost animated:YES completion:nil];
                [eraseprefPost addAction:cancel];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:eraseprefWarn animated:YES completion:nil];
            [eraseprefWarn addAction:cancel];
            [eraseprefWarn addAction:ok];
            }
            break;
        case TAG_ARCCAPES:
            setPreference(@"arccapes_enable", @(sender.isOn));
            break;
        case TAG_VIRTMOUSE:
            setPreference(@"virtmouse_enable", @(sender.isOn));
            break;
        case TAG_UNJBRAM:
            {
            setPreference(@"ram_unjb_enable", @(sender.isOn));
            UIAlertController *enableRAMPost = [UIAlertController alertControllerWithTitle:@"RAM slider option has been changed" message:@"You will need to restart the launcher for changes to take effect." preferredStyle:UIAlertControllerStyleActionSheet];
            [self setPopoverProperties:enableRAMPost.popoverPresentationController sender:(UIButton *)sender];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:enableRAMPost animated:YES completion:nil];
            [enableRAMPost addAction:ok];
            }
            break;
        default:
            NSLog(@"what does switch %ld for? implement me!", sender.tag);
            break;
    }
}

- (void)setPopoverProperties:(UIPopoverPresentationController *)controller sender:(UIButton *)sender {
    if (controller != nil) {
        controller.sourceView = sender;
        controller.sourceRect = sender.bounds;
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - UIPickerView
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView.tag == TAG_PICKER_REND) {
        rendTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    } else if(pickerView.tag == TAG_PICKER_JHOME) {
        jhomeTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    } else if(pickerView.tag == TAG_PICKER_GDIR) {
        gdirTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
        setPreference(@"game_directory", gdirTextField.text);
        init_setupMultiDir();
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView.tag == TAG_PICKER_REND) {
        return rendererDict.allKeys.count;
    } else if(pickerView.tag == TAG_PICKER_JHOME) {
        return jhomeList.count;
    } else if(pickerView.tag == TAG_PICKER_GDIR) {
        return gdirList.count;
    } else {
        return 0;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSObject *object;
    if(pickerView.tag == TAG_PICKER_REND) {
        object = [rendererDict.allKeys objectAtIndex:row];
    } else if(pickerView.tag == TAG_PICKER_JHOME) {
        object = [jhomeList objectAtIndex:row];
    } else if(pickerView.tag == TAG_PICKER_GDIR) {
        object = [gdirList objectAtIndex:row];
    }
    return (NSString*) object;
}

- (void)closeKeyboard:(UIBarButtonItem *)doneButton {
    if (doneButton.tag == TAG_DONE_REND) {
        [rendTextField endEditing:YES];
    } else if (doneButton.tag == TAG_DONE_JHOME) {
        [jhomeTextField endEditing:YES];
    } else if (doneButton.tag == TAG_DONE_GDIR) {
        [gdirTextField endEditing:YES];
    } 
}

@end
