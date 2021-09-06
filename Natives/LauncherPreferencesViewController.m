#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"

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
UIPickerView* rendPickerView;
UISwitch *noshaderconvSwitch;
UIBlurEffect *blur;
UIVisualEffectView *blurView;
UIScrollView *scrollView;
NSString *gl4es114 = @"GL4ES 1.1.4";
NSString *gl4es115 = @"GL4ES 1.1.5 (1.16+)";
NSString *tinygl4angle = @"tinygl4angle (1.17+)";
//NSString *vgpu = @"vgpu";
NSString *lib_gl4es114 = @"libgl4es_114.dylib";
NSString *lib_gl4es115 = @"libgl4es_115.dylib";
NSString *lib_tinygl4angle = @"libtinygl4angle.dylib";
//NSString *lib_vgpu = @"libvgpu.dylib";

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
    buttonSizeSlider.tag = 98;
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
    resolutionSlider.tag = 99;
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
    memSlider.tag = 100;
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
    jargsTextField.tag = 101;
    jargsTextField.delegate = self;
    jargsTextField.placeholder = @"Specify arguments...";
    jargsTextField.text = (NSString *) getPreference(@"java_args");
    jargsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jargsTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:jargsTextField];
    
    UIToolbar *jargsPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *jargsFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *jargsDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    jargsDoneButton.tag = 150;
    jargsPickerToolbar.items = @[jargsFlexibleSpace, jargsDoneButton];

    jargsTextField.inputAccessoryView = jargsPickerToolbar;

    UILabel *rendTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    rendTextView.text = @"Renderer";
    rendTextView.numberOfLines = 0;
    [rendTextView sizeToFit];
    [tableView addSubview:rendTextView];

    rendTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [rendTextField addTarget:rendTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    rendTextField.tag = 102;
    rendTextField.delegate = self;
    rendTextField.placeholder = @"Override renderer...";
    if ([getPreference(@"renderer") isEqualToString:lib_gl4es114]) {
        rendTextField.text = gl4es114;
    } else if ([getPreference(@"renderer") isEqualToString:lib_gl4es115]) {
        rendTextField.text = gl4es115;
    } else if ([getPreference(@"renderer") isEqualToString:lib_tinygl4angle]) {
        rendTextField.text = tinygl4angle;
    } /* else if ([getPreference(@"renderer") isEqualToString:lib_vgpu) {
       rendTextField.text = vgpu;
    }*/
    
    rendTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    rendTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:rendTextField];

    rendererList = [[NSMutableArray alloc] init];
    [rendererList addObject:gl4es114];
    [rendererList addObject:gl4es115];
    [rendererList addObject:tinygl4angle];
    //[rendererList addObject:vgpu];

    rendPickerView = [[UIPickerView alloc] init];
    rendPickerView.delegate = self;
    rendPickerView.dataSource = self;
    UIToolbar *rendPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *rendFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *rendDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    rendDoneButton.tag = 151;
    rendPickerToolbar.items = @[rendFlexibleSpace, rendDoneButton];

    rendTextField.inputAccessoryView = rendPickerToolbar;
    rendTextField.inputView = rendPickerView;

    UILabel *jhomeTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    jhomeTextView.text = @"Java home";
    jhomeTextView.numberOfLines = 0;
    [jhomeTextView sizeToFit];
    [tableView addSubview:jhomeTextView];

    jhomeTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 28.0, 30)];
    [jhomeTextField addTarget:jhomeTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jhomeTextField.tag = 103;
    jhomeTextField.delegate = self;
    jhomeTextField.placeholder = @"Override Java path...";
    jhomeTextField.text = (NSString *) getPreference(@"java_home");
    jhomeTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jhomeTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:jhomeTextField];
    
    UIToolbar *jhomePickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *jhomeFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *jhomeDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    jhomeDoneButton.tag = 152;
    jhomePickerToolbar.items = @[jhomeFlexibleSpace, jhomeDoneButton];

    jhomeTextField.inputAccessoryView = jhomePickerToolbar;

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
    gdirTextField.tag = 104;
    gdirTextField.delegate = self;
    gdirTextField.placeholder = @"Custom game directory...";
    gdirTextField.text = (NSString *) getPreference(@"game_directory");
    gdirTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    gdirTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [tableView addSubview:gdirTextField];

    UIToolbar *gdirPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *gdirFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *gdirDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
    gdirDoneButton.tag = 153;
    gdirPickerToolbar.items = @[gdirFlexibleSpace, gdirDoneButton];

    gdirTextField.inputAccessoryView = gdirPickerToolbar;
    
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
    noshaderconvSwitch.tag = 105;
    [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:NO];
    [noshaderconvSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:noshaderconvSwitch];
    if ([getPreference(@"renderer") isEqualToString:gl4es115]) {
            [noshaderconvSwitch setEnabled:YES];
        } else {
            [noshaderconvSwitch setEnabled:NO];
    }

    UILabel *resetWarnTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    resetWarnTextView.text = @"Reset launcher warnings";
    resetWarnTextView.numberOfLines = 0;
    [resetWarnTextView sizeToFit];
    [tableView addSubview:resetWarnTextView];

    UISwitch *resetWarnSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    resetWarnSwitch.tag = 106;
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
    releaseSwitch.tag = 107;
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
    snapshotSwitch.tag = 108;
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
    oldbetaSwitch.tag = 109;
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
    oldalphaSwitch.tag = 110;
    [oldalphaSwitch setOn:[getPreference(@"vertype_oldalpha") boolValue] animated:NO];
    [oldalphaSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:oldalphaSwitch];
    
    UILabel *debugLogTextView = [[UILabel alloc] initWithFrame:CGRectMake(16.0, currY+=44.0, 0.0, 0.0)];
    debugLogTextView.text = @"Enable debug logging";
    debugLogTextView.numberOfLines = 0;
    [debugLogTextView sizeToFit];
    [tableView addSubview:debugLogTextView];

    UISwitch *debugLogSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 62.0, currY - 5.0, 50.0, 30)];
    debugLogSwitch.tag = 111;
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
        UIAction *option1 = [UIAction actionWithTitle:@"Button scale" image:[[UIImage systemImageNamed:@"aspectratio"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Resolution" image:[[UIImage systemImageNamed:@"viewfinder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        UIAction *option3 = [UIAction actionWithTitle:@"Allocated RAM" image:[[UIImage systemImageNamed:@"memorychip"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:ALLOCMEM];}];
        UIAction *option4 = [UIAction actionWithTitle:@"Java arguments" image:[[UIImage systemImageNamed:@"character.cursor.ibeam"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAction *option5 = [UIAction actionWithTitle:@"Renderer" image:[[UIImage systemImageNamed:@"cpu"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAction *option6 = [UIAction actionWithTitle:@"Java home" image:[[UIImage systemImageNamed:@"cube"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAction *option7 = [UIAction actionWithTitle:@"Game directory" image:[[UIImage systemImageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}];
        UIAction *option8 = [UIAction actionWithTitle:@"Disable shaderconv" image:[[UIImage systemImageNamed:@"circle.lefthalf.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}];
        UIAction *option9 = [UIAction actionWithTitle:@"Reset warnings" image:[[UIImage systemImageNamed:@"exclamationmark.triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESETWARN];}];
        UIAction *option10 = [UIAction actionWithTitle:@"Type switches" image:[[UIImage systemImageNamed:@"list.bullet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:TYPESEL];}];
        UIAction *option11 = [UIAction actionWithTitle:@"Debug logging" image:[[UIImage systemImageNamed:@"doc.badge.gearshape"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:DEBUGLOG];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option1, option2, option3, option4, option5, option6, option7, option8, option9, option10, option11]];
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
    if (textField.tag == 101) {
        setPreference(@"java_args", textField.text);
    } else if (textField.tag == 102) {
        if (![textField.text isEqualToString:gl4es114]) {
            setPreference(@"renderer", lib_gl4es114);
            setenv("RENDERER", [lib_gl4es114 cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } else if (![textField.text isEqualToString:gl4es115]) {
            setPreference(@"renderer", lib_gl4es115);
            setenv("RENDERER", [lib_gl4es115 cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } else if (![textField.text isEqualToString:tinygl4angle]) {
            setPreference(@"renderer", lib_tinygl4angle);
            setenv("RENDERER", [lib_tinygl4angle cStringUsingEncoding:NSUTF8StringEncoding], 1);
        } /* else if (![textField.text isEqualToString:vgpu]) {
            setPreference(@"renderer", lib_vgpu);
            setenv("RENDERER", [lib_vgpu cStringUsingEncoding:NSUTF8StringEncoding]]), 1);
        } */
        
        if (![textField.text isEqualToString:gl4es115] && [getPreference(@"disable_gl4es_shaderconv") boolValue] == YES) {
            setPreference(@"disable_gl4es_shaderconv", @NO);
            [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:YES];
            [noshaderconvSwitch setEnabled:NO];
        } else if (![textField.text isEqualToString:gl4es114] && [getPreference(@"disable_gl4es_shaderconv") boolValue] == NO){
            setPreference(@"disable_gl4es_shaderconv", @YES);
            [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:YES];
            [noshaderconvSwitch setEnabled:YES];
        }
    } else if (textField.tag == 103) {
        setPreference(@"java_home", textField.text);
        if (![textField.text containsString:@"java-8-openjdk"] && [getPreference(@"java_warn") boolValue] == YES) {
            UIAlertController *javaAlert = [UIAlertController alertControllerWithTitle:@"Java version is not Java 8" message:@"Minecraft versions below 1.6, modded below 1.16.4, and the mod installer will not work unless you have Java 8 installed on your device."preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:javaAlert animated:YES completion:nil];
            [javaAlert addAction:ok];
            setPreference(@"java_warn", @NO);
        }
    } else if (textField.tag == 104) {
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
        UIAlertAction *jhome = [UIAlertAction actionWithTitle:@"Java home" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAlertAction *gdirectory = [UIAlertAction actionWithTitle:@"Game directory"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:GDIRECTORY];}];
        UIAlertAction *noshaderconv = [UIAlertAction actionWithTitle:@"Disable shaderconv" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}];
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
        message = @"This option allows you to change the renderer in use. Choosing 'libgl4es_115.dylib' may fix sheep and banner colors on 1.16 and allow 1.17 to be played, but will also not work with older versions.";
    } else if(setting == JHOME) {
        title = @"Java home";
        message = @"This option allows you to change the Java executable directory. Choosing '/usr/lib/jvm/java-16-openjdk' may allow you to play 1.17, however older versions and most versions of modded Minecraft, as well as the mod installer, will not work. This option also requires a restart of the launcher to take effect.";
    } else if(setting == GDIRECTORY) {
        title = @"Game directory";
        message = @"This option allows you to change where your Minecraft settings and saves are stored in a MultiMC like fashion. Useful for when you want to have multiple mod loaders installed but do not want to delete/move mods around to switch. This option also requires a restart of the launcher to take effect.";
    } else if(setting == NOSHADERCONV) {
        title = @"Disable shaderconv";
        message = @"This option allows you to disable the shader converter inside gl4es 1.1.5 in order to let ANGLE processes them directly. This option is experimental and should only be enabled when playing Minecraft 1.17 or above.";
    } else if(setting == RESETWARN) {
        title = @"Reset warnings";
        message = @"This option re-enables all warnings to be shown again.";
    } else if(setting == TYPESEL) {
        title = @"Type switches";
        message = @"These switches allow to to change where or not releases, snapshots, old betas, and old alphas will show up in the version selection menu. This option also requires a restart of the launcher to take effect.";
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
        case 98:
            setPreference(@"button_scale", @((int)sender.value));
            break;
        case 99:
            setPreference(@"resolution", @((int)sender.value));
            break;
        case 100:
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
        case 105:
            setPreference(@"disable_gl4es_shaderconv", @(sender.isOn));
            break;
        case 106:
            setPreference(@"mem_warn", @YES);
            setPreference(@"option_warn", @YES);
            setPreference(@"local_warn", @YES);
            setPreference(@"java_warn", @YES);
            setPreference(@"jb_warn", @YES);
            if(1 == 1) {
                UIAlertController *resetWarn = [UIAlertController alertControllerWithTitle:@"Warnings reset." message:@"Restart to show warnings again." preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:resetWarn.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:resetWarn animated:YES completion:nil];
                [resetWarn addAction:ok];
            }
            break;
        case 107:
            setPreference(@"vertype_release", @(sender.isOn));
            break;
        case 108:
            setPreference(@"vertype_snapshot", @(sender.isOn));
            break;
        case 109:
            setPreference(@"vertype_oldbeta", @(sender.isOn));
            break;
        case 110:
            setPreference(@"vertype_oldalpha", @(sender.isOn));
            break;
        case 111:
            setPreference(@"debug_logging", @(sender.isOn));
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

#pragma mark - UIPickerView (renderer)
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    rendTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    setPreference(@"renderer", rendTextField.text);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return rendererList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSObject *object = [rendererList objectAtIndex:row];
    return (NSString*) object;
}

- (void)closeKeyboard:(UIBarButtonItem *)doneButton {
    if (doneButton.tag == 150) {
        [jargsTextField endEditing:YES];
    } else if (doneButton.tag == 151) {
        [rendTextField endEditing:YES];
    } else if (doneButton.tag == 152) {
        [jhomeTextField endEditing:YES];
    } else if (doneButton.tag == 153) {
        [gdirTextField endEditing:YES];
    } 
}

@end
