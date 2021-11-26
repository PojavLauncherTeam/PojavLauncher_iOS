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
#define NOSHADERCONV 7
#define RESETWARN 8
#define TYPESEL 9
#define DEBUGLOG 10
#define MKGDIR 11
#define RMGDIR 12
#define SLIDEHOTBAR 13

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

#define TAG_NOSHADERCONV 105
#define TAG_RESETWARN 106

#define TAG_SWITCH_VRELEASE 107
#define TAG_SWITCH_VSNAPSHOT 108
#define TAG_SWITCH_VOLDBETA 109
#define TAG_SWITCH_VOLDALPHA 110

#define TAG_DEBUGLOG 111
#define TAG_SLIDEHOTBAR 112

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
NSMutableArray* rendererList;
NSMutableArray* gdirList;
NSMutableArray* jhomeList;
UIPickerView* rendPickerView;
UIPickerView* gdirPickerView;
UIPickerView* jhomePickerView;
UISwitch *noshaderconvSwitch, *slideHotbarSwitch;
UIBlurEffect *blur;
UIVisualEffectView *blurView;
UIScrollView *scrollView;
NSString *gl4es114 = @"GL4ES 1.1.4 - exports OpenGL 2.1";
NSString *gl4es115 = @"GL4ES 1.1.5 (1.16+) - exports OpenGL 2.1";
NSString *tinygl4angle = @"tinygl4angle (1.17+) - exports OpenGL 3.2 (Core Profile, limited)";
NSString *zink = @"Zink (Mesa 21.0) - exports OpenGL 4.1";
NSString *java8jben = @"Java 8";
NSString *java16jben = @"Java 16";
NSString *java17jben = @"Java 17";
NSString *java8 = @"Java 8 (sandbox)";
NSString *libsjava8jben = @"/usr/lib/jvm/java-8-openjdk";
NSString *libsjava16jben = @"/usr/lib/jvm/java-16-openjdk";
NSString *libsjava17jben = @"/usr/lib/jvm/java-17-openjdk";
NSString *libsjava8;
NSString *lib_gl4es114 = @"libgl4es_114.dylib";
NSString *lib_gl4es115 = @"libgl4es_115.dylib";
NSString *lib_tinygl4angle = @"libtinygl4angle.dylib";
NSString *lib_zink = @"libOSMesaOverride.dylib";

int tempIndex;

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    
    [self setTitle:@"Preferences"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    CGFloat currY = 8.0;
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 20, 0)];
    [scrollView addSubview:tableView];
    
    [self registerForKeyboardNotifications];
    
    blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    
    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

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
    rendTextField.delegate = self;
    rendTextField.placeholder = @"Override renderer...";
    if ([getPreference(@"renderer") isEqualToString:lib_gl4es114]) {
        rendTextField.text = gl4es114;
        tempIndex = 0;
    } else if ([getPreference(@"renderer") isEqualToString:lib_gl4es115]) {
        rendTextField.text = gl4es115;
        tempIndex = 1;
    } else if ([getPreference(@"renderer") isEqualToString:lib_tinygl4angle]) {
        rendTextField.text = tinygl4angle;
        tempIndex = 2;
    } else if ([getPreference(@"renderer") isEqualToString:lib_zink]) {
        rendTextField.text = zink;
        tempIndex = 3;
    }
    
    rendTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    rendTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:rendTextField];

    rendererList = [[NSMutableArray alloc] init];
    [rendererList addObject:gl4es114];
    [rendererList addObject:gl4es115];
    [rendererList addObject:tinygl4angle];
    [rendererList addObject:zink];
    
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
    jhomeTextField.delegate = self;
    jhomeTextField.placeholder = @"Override Java path...";
    
    libsjava8 = [NSString stringWithFormat:@"%s/jre8", getenv("POJAV_HOME")];
    if(getenv("POJAV_DETECTEDJB")) {
        if ([getPreference(@"java_home") isEqualToString:libsjava8jben]) {
            jhomeTextField.text = java8jben;
        } else if ([getPreference(@"java_home") isEqualToString:libsjava16jben]) {
            jhomeTextField.text = java16jben;
        } else if ([getPreference(@"java_home") isEqualToString:libsjava17jben]) {
            jhomeTextField.text = java17jben;
        }
    } else {
        jhomeTextField.text = java8;
    }
    
    jhomeTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jhomeTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:jhomeTextField];
    
    jhomeList = [[NSMutableArray alloc] init];
    if ([[NSFileManager defaultManager] fileExistsAtPath:libsjava8jben]) {
        [jhomeList addObject:java8jben];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:libsjava16jben]) {
        [jhomeList addObject:java16jben];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:libsjava17jben]) {
        [jhomeList addObject:java17jben];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:libsjava8]) {
        [jhomeList addObject:java8];
    }
    
    jhomePickerView = [[UIPickerView alloc] init];
    jhomePickerView.delegate = self;
    jhomePickerView.dataSource = self;
    jhomePickerView.tag = TAG_PICKER_JHOME;
    [jhomePickerView reloadAllComponents];
    for (int i = 0; i < jhomeList.count; i++) {
        if ([jhomeList[i] isEqualToString:jhomeTextField.text]) {
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

    if ([getPreference(@"option_warn") boolValue] == YES) {
        UIAlertController *preferenceWarn = [UIAlertController alertControllerWithTitle:@"Restart required" message:@"Some options in this menu will require that you restart the launcher for them to take effect."preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:preferenceWarn animated:YES completion:nil];
        [preferenceWarn addAction:ok];
        setPreference(@"option_warn", @NO);
    }
    
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
    
    if ([getPreference(@"option_warn") boolValue] == YES) {
        UIAlertController *preferenceWarn = [UIAlertController alertControllerWithTitle:@"Restart required" message:@"Some options in this menu will require that you restart the launcher for them to take effect."preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:preferenceWarn animated:YES completion:nil];
        [preferenceWarn addAction:ok];
        setPreference(@"option_warn", @NO);
    }

    UILabel *noshaderconvTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    noshaderconvTextView.text = @"Disable gl4es 1.1.5 shaderconv";
    noshaderconvTextView.numberOfLines = 0;
    [noshaderconvTextView sizeToFit];
    [tableView addSubview:noshaderconvTextView];

    noshaderconvSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    noshaderconvSwitch.tag = TAG_NOSHADERCONV;
    [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:NO];
    [noshaderconvSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:noshaderconvSwitch];
    [noshaderconvSwitch setEnabled:[getPreference(@"renderer") isEqualToString:gl4es115]];
    
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
    
    UILabel *releaseTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    releaseTextView.text = @"Releases";
    releaseTextView.numberOfLines = 0;
    [releaseTextView sizeToFit];
        [releaseTextView setFont:[UIFont systemFontOfSize:13]];
    [tableView addSubview:releaseTextView];

    UISwitch *releaseSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((width * .25) - 62.0, currY - 5.0, 50.0, 30)];
    releaseSwitch.tag = TAG_SWITCH_VRELEASE;
    [releaseSwitch setOn:[getPreference(@"vertype_release") boolValue] animated:NO];
    [releaseSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:releaseSwitch];
    
    UILabel *snapshotTextView = [[UILabel alloc] initWithFrame:CGRectMake(releaseSwitch.frame.origin.x + releaseSwitch.frame.size.width + 8.0, currY, 0.0, 0.0)];
    snapshotTextView.text = @"Snapshot";
    snapshotTextView.numberOfLines = 0;
    [snapshotTextView sizeToFit];
        [snapshotTextView setFont:[UIFont systemFontOfSize:13]];
    [tableView addSubview:snapshotTextView];

    UISwitch *snapshotSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((width * .50) - 62.0, currY - 5.0, 50.0, 30)];
    snapshotSwitch.tag = TAG_SWITCH_VSNAPSHOT;
    [snapshotSwitch setOn:[getPreference(@"vertype_snapshot") boolValue] animated:NO];
    [snapshotSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:snapshotSwitch];

    UILabel *oldbetaTextView = [[UILabel alloc] initWithFrame:CGRectMake(snapshotSwitch.frame.origin.x + snapshotSwitch.frame.size.width + 8.0, currY, 0.0, 0.0)];
    oldbetaTextView.text = @"Old beta";
    oldbetaTextView.numberOfLines = 0;
    [oldbetaTextView sizeToFit];
        [oldbetaTextView setFont:[UIFont systemFontOfSize:13]];
    [tableView addSubview:oldbetaTextView];

    UISwitch *oldbetaSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((width * .75) - 62.0, currY - 5.0, 50.0, 30)];
    oldbetaSwitch.tag = TAG_SWITCH_VOLDBETA;
    [oldbetaSwitch setOn:[getPreference(@"vertype_oldbeta") boolValue] animated:NO];
    [oldbetaSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:oldbetaSwitch];
    
    UILabel *oldalphaTextView = [[UILabel alloc] initWithFrame:CGRectMake(oldbetaSwitch.frame.origin.x + oldbetaSwitch.frame.size.width + 8.0, currY, 0.0, 0.0)];
    oldalphaTextView.text = @"Old alpha";
    oldalphaTextView.numberOfLines = 0;
    [oldalphaTextView sizeToFit];
        [oldalphaTextView setFont:[UIFont systemFontOfSize:13]];
    [tableView addSubview:oldalphaTextView];

    UISwitch *oldalphaSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    oldalphaSwitch.tag = TAG_SWITCH_VOLDALPHA;
    [oldalphaSwitch setOn:[getPreference(@"vertype_oldalpha") boolValue] animated:NO];
    [oldalphaSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:oldalphaSwitch];
    
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
    
    CGRect frame = tableView.frame;
    frame.size.height = currY+=44;
    tableView.frame = frame;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, tableView.frame.size.height);
    
    if (@available(iOS 14.0, *)) {
        // use UIMenu
        UIBarButtonItem *help = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"questionmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"xmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(exitAppAlert)];
        self.navigationItem.rightBarButtonItems = @[help, close];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[
            [UIAction actionWithTitle:@"Button scale" image:[[UIImage systemImageNamed:@"aspectratio"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}],
            [UIAction actionWithTitle:@"Resolution" image:[[UIImage systemImageNamed:@"viewfinder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}],
            [UIAction actionWithTitle:@"Allocated RAM" image:[[UIImage systemImageNamed:@"memorychip"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:ALLOCMEM];}],
            [UIAction actionWithTitle:@"Java arguments" image:[[UIImage systemImageNamed:@"character.cursor.ibeam"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JARGS];}],
            [UIAction actionWithTitle:@"Renderer" image:[[UIImage systemImageNamed:@"cpu"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:REND];}],
            [UIAction actionWithTitle:@"Java version" image:[[UIImage systemImageNamed:@"cube"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JHOME];}],
            [UIAction actionWithTitle:@"Game directory" image:[[UIImage systemImageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}],
            [UIAction actionWithTitle:@"Disable shaderconv" image:[[UIImage systemImageNamed:@"circle.lefthalf.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}],
            [UIAction actionWithTitle:@"Slideable hotbar" image:[[UIImage systemImageNamed:@"slider.horizontal.below.rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:SLIDEHOTBAR];}],
            [UIAction actionWithTitle:@"Reset warnings" image:[[UIImage systemImageNamed:@"exclamationmark.triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESETWARN];}],
            [UIAction actionWithTitle:@"Type switches" image:[[UIImage systemImageNamed:@"list.bullet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:TYPESEL];}],
            [UIAction actionWithTitle:@"Debug logging" image:[[UIImage systemImageNamed:@"doc.badge.gearshape"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:DEBUGLOG];}],
        ]];
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
        [scrollView scrollRectToVisible:activeField.frame animated:YES];
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
        if ([textField.text isEqualToString:gl4es114]) {
            setPreference(@"renderer", lib_gl4es114);
        } else if ([textField.text isEqualToString:gl4es115]) {
            setPreference(@"renderer", lib_gl4es115);
        } else if ([textField.text isEqualToString:tinygl4angle]) {
            setPreference(@"renderer", lib_tinygl4angle);
        } else if ([textField.text isEqualToString:zink]) {
            setPreference(@"renderer", lib_zink);
        }
        setenv("RENDERER", [getPreference(@"renderer") UTF8String], 1);
        
        if (![textField.text isEqualToString:gl4es115] && [getPreference(@"disable_gl4es_shaderconv") boolValue] == YES) {
            setPreference(@"disable_gl4es_shaderconv", @NO);
            [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:YES];
            [noshaderconvSwitch setEnabled:NO];
        } else if (![textField.text isEqualToString:gl4es114] && [getPreference(@"disable_gl4es_shaderconv") boolValue] == NO){
            setPreference(@"disable_gl4es_shaderconv", @YES);
            [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:YES];
            [noshaderconvSwitch setEnabled:YES];
        }
    } else if (textField.tag == TAG_JHOME) {
        if ([textField.text isEqualToString:java8jben]) {
            setPreference(@"java_home", libsjava8jben);
            setenv("JAVA_HOME", [libsjava8jben cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } else if ([textField.text isEqualToString:java16jben]) {
            setPreference(@"java_home", libsjava16jben);
            setenv("JAVA_HOME", [libsjava16jben cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } else if ([textField.text isEqualToString:java17jben]) {
            setPreference(@"java_home", libsjava17jben);
            setenv("JAVA_HOME", [libsjava17jben cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } else if ([textField.text isEqualToString:java8]) {
            setPreference(@"java_home", libsjava8);
            setenv("JAVA_HOME", [libsjava8 cStringUsingEncoding:NSUTF8StringEncoding], 1);
        }
        if (![textField.text containsString:java8jben] && ![textField.text containsString:java8] && [getPreference(@"java_warn") boolValue] == YES) {
            UIAlertController *javaAlert = [UIAlertController alertControllerWithTitle:@"Java version is not Java 8" message:@"Minecraft versions below 1.6, modded below 1.16.4, and the mod installer will not work unless you have Java 8 installed on your device."preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:javaAlert animated:YES completion:nil];
            [javaAlert addAction:ok];
            setPreference(@"java_warn", @NO);
        }
    } else if (textField.tag == TAG_GDIR) {
        setPreference(@"game_directory", textField.text);
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
        BOOL isDir = NO;
        BOOL isFailed = NO;
        if(![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) {
            if([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL]) {
                isFailed = NO;
                [self instanceDirCont];
                gdirTextField.text = [[manageDirAC textFields][0] text];
                [gdirTextField endEditing:YES];
                [self manageDirResult:(UIButton *)sender success:isFailed directory:[[manageDirAC textFields][0] text] type:type];
                
            } else {
                isFailed = YES;
                [self manageDirResult:(UIButton *)sender success:isFailed directory:[[manageDirAC textFields][0] text] type:type];
            }
        } else {
            isFailed = YES;
            [self manageDirResult:(UIButton *)sender success:isFailed directory:[[manageDirAC textFields][0] text] type:type];
        }
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
        BOOL isDir = NO;
        BOOL isFailed = NO;
        
            if([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) {
                if([[NSFileManager defaultManager] removeItemAtPath:directory error:NULL]) {
                    isFailed = NO;
                    [self instanceDirCont];
                    gdirTextField.text = @"default";
                    [gdirTextField endEditing:YES];
                    [self manageDirResult:(UIButton *)sender success:isFailed directory:gdirTextField.text type:type];
                } else {
                    isFailed = YES;
                    [self manageDirResult:(UIButton *)sender success:isFailed directory:gdirTextField.text type:type];
                }
            } else {
                isFailed = YES;
                [self manageDirResult:(UIButton *)sender success:isFailed directory:gdirTextField.text type:type];
            }
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

- (void)manageDirResult:(UIButton *)sender success:(BOOL)boolean directory:(NSString *)dirName type:(int)type {
    NSString *title;
    NSString *message;
    if(type == MKGDIR) {
        if(boolean == YES) {
            title = @"An error occurred.";
            message = [NSString stringWithFormat:@"Ensure that a file with the name %@ does not exist, and that the instances directory is writeable.", dirName];
        } else if(boolean == NO) {
            title = @"Successfully changed directory.";
            message = @"";
        }
    } else if (type == RMGDIR) {
        if(boolean == YES) {
            title = @"An error occurred.";
            message = @"Ensure that the instances directory is writeable.";
        } else if(boolean == NO) {
            title = @"Successfully removed directory.";
            message = @"";
        }
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
        UIAlertAction *resolution = [UIAlertAction actionWithTitle:@"Resolution" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        UIAlertAction *allocmem = [UIAlertAction actionWithTitle:@"Allocated RAM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:ALLOCMEM];}];
        UIAlertAction *jargs = [UIAlertAction actionWithTitle:@"Java arguments" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAlertAction *renderer = [UIAlertAction actionWithTitle:@"Renderer"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAlertAction *jhome = [UIAlertAction actionWithTitle:@"Java version" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAlertAction *gdirectory = [UIAlertAction actionWithTitle:@"Game directory"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}];
        UIAlertAction *noshaderconv = [UIAlertAction actionWithTitle:@"Disable shaderconv" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}];
        UIAlertAction *slidehotbar = [UIAlertAction actionWithTitle:@"Slideable hotbar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:SLIDEHOTBAR];}];
        UIAlertAction *resetwarn = [UIAlertAction actionWithTitle:@"Reset warnings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RESETWARN];}];
        UIAlertAction *typesel = [UIAlertAction actionWithTitle:@"Type switches" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:TYPESEL];}];
        UIAlertAction *debuglog = [UIAlertAction actionWithTitle:@"Debug logging" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:DEBUGLOG];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [self setPopoverProperties:helpAlert.popoverPresentationController sender:(UIButton *)self.navigationItem.rightBarButtonItem];
        [self presentViewController:helpAlert animated:YES completion:nil];
        [helpAlert addAction:btnscale];
        [helpAlert addAction:resolution];
        [helpAlert addAction:allocmem];
        [helpAlert addAction:jargs];
        [helpAlert addAction:renderer];
        [helpAlert addAction:jhome];
        [helpAlert addAction:gdirectory];
        [helpAlert addAction:noshaderconv];
        [helpAlert addAction:slidehotbar];
        [helpAlert addAction:resetwarn];
        [helpAlert addAction:typesel];
        [helpAlert addAction:debuglog];
        [helpAlert addAction:cancel];
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
        message = @"This option allows you to change the amount of memory used by the game. The minimum is 25% (default) and the maximum is 85%. Any value over 40% will require that you use a tool like overb0ard to prevent jetsam crashes. Take note that Java uses some of the memory itself, so the value you set will be lowered slightly in game. This option also requires a restart of the launcher to take effect.";
    } else if(setting == JARGS) {
        title = @"Java arguments";
        message = @"This option allows you to edit arguments that can be passed to Minecraft. Not all arguments work with PojavLauncher, so be aware. This option also requires a restart of the launcher to take effect.";
    } else if(setting == REND) {
        title = @"Renderer";
        message = @"This option allows you to change the renderer in use. Choosing GL4ES 1.1.5 or tinygl4angle may fix sheep and banner colors on 1.16 and allow 1.17 to be played, but will also not work with older versions.";
    } else if(setting == JHOME) {
        title = @"Java version";
        message = @"This option allows you to change the Java executable directory. Choosing Java 16 or Java 17 may allow you to play 1.17, however older versions and most versions of modded Minecraft, as well as the mod installer, will not work. This option also requires a restart of the launcher to take effect.";
    } else if(setting == GDIRECTORY) {
        title = @"Game directory";
        message = @"This option allows you to change where your Minecraft settings and saves are stored in a MultiMC like fashion. Useful for when you want to have multiple mod loaders installed but do not want to delete/move mods around to switch. This option also requires a restart of the launcher to take effect.";
    } else if(setting == NOSHADERCONV) {
        title = @"Disable shaderconv";
        message = @"This option allows you to disable the shader converter inside gl4es 1.1.5 in order to let ANGLE processes them directly. This option is experimental and should only be enabled when playing Minecraft 1.17 or above. Alternatively you can use tinygl4angle for 1.17.";
    } else if(setting == SLIDEHOTBAR) {
        title = @"Slideable hotbar";
        message = @"This option allows you to use a finger to slide between hotbar slots.";
    } else if(setting == RESETWARN) {
        title = @"Reset warnings";
        message = @"This option re-enables all warnings to be shown again.";
    } else if(setting == TYPESEL) {
        title = @"Type switches";
        message = @"These switches allow to to change where or not releases, snapshots, old betas, and old alphas will show up in the version selection menu.";
    } else if(setting == DEBUGLOG) {
        title = @"Enable debug logging";
        message = @"This option logs internal settings and actions to latestlog.txt. This helps the developers find issues easier, but Minecraft may run slower as the logs will be written to more often.";
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
                UIAlertController *memAlert = [UIAlertController alertControllerWithTitle:@"High memory value selected." message:@"Due to limitations in the operating system itself, you will need to use a tool like overb0ard to prevent jetsam crashes." preferredStyle:UIAlertControllerStyleActionSheet];
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
        case TAG_NOSHADERCONV:
            setPreference(@"disable_gl4es_shaderconv", @(sender.isOn));
            break;
        case TAG_RESETWARN:
            setPreference(@"mem_warn", @YES);
            setPreference(@"option_warn", @YES);
            setPreference(@"local_warn", @YES);
            setPreference(@"java_warn", @YES);
            setPreference(@"jb_warn", @YES);
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
        case TAG_SWITCH_VRELEASE:
            setPreference(@"vertype_release", @(sender.isOn));
            [LauncherViewController fetchVersionList];
            break;
        case TAG_SWITCH_VSNAPSHOT:
            setPreference(@"vertype_snapshot", @(sender.isOn));
            [LauncherViewController fetchVersionList];
            break;
        case TAG_SWITCH_VOLDBETA:
            setPreference(@"vertype_oldbeta", @(sender.isOn));
            [LauncherViewController fetchVersionList];
            break;
        case TAG_SWITCH_VOLDALPHA:
            setPreference(@"vertype_oldalpha", @(sender.isOn));
            [LauncherViewController fetchVersionList];
            break;
        case TAG_DEBUGLOG:
            setPreference(@"debug_logging", @(sender.isOn));
            [LauncherViewController fetchVersionList];
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

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
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
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView.tag == TAG_PICKER_REND) {
        return rendererList.count;
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
        object = [rendererList objectAtIndex:row];
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
