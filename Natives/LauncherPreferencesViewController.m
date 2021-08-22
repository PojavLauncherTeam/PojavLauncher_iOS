#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"

#include "utils.h"

#define BTNSCALE 0
#define RESOLUTION 1
#define JARGS 2
#define REND 3
#define JHOME 4
#define NOSHADERCONV 5

@interface LauncherPreferencesViewController () <UIPopoverPresentationControllerDelegate> {
}

// - (void)method

@end

@implementation LauncherPreferencesViewController

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

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    UILabel *btnsizeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY, 0.0, 30.0)];
    btnsizeTextView.text = @"Button scale (%)";
    btnsizeTextView.numberOfLines = 0;
    btnsizeTextView.textAlignment = NSTextAlignmentCenter;
    [btnsizeTextView sizeToFit];
    CGRect tempRect = btnsizeTextView.frame;
    tempRect.size.height = 30.0;
    btnsizeTextView.frame = tempRect;
    [scrollView addSubview:btnsizeTextView];
    
    DBNumberedSlider *buttonSizeSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(8.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 12.0, btnsizeTextView.frame.size.height)];
    buttonSizeSlider.tag = 98;
    [buttonSizeSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [buttonSizeSlider setBackgroundColor:[UIColor clearColor]];
    buttonSizeSlider.minimumValue = 50.0;
    buttonSizeSlider.maximumValue = 500.0;
    buttonSizeSlider.continuous = YES;
    buttonSizeSlider.value = [getPreference(@"button_scale") floatValue];
    [scrollView addSubview:buttonSizeSlider];

    UILabel *resolutionTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=40.0, 0.0, 30.0)];
    resolutionTextView.text = @"Resolution (%)";
    resolutionTextView.numberOfLines = 0;
    resolutionTextView.textAlignment = NSTextAlignmentCenter;
    [resolutionTextView sizeToFit];
    tempRect = resolutionTextView.frame;
    tempRect.size.height = 30.0;
    resolutionTextView.frame = tempRect;
    [scrollView addSubview:resolutionTextView];
    
    DBNumberedSlider *resolutionSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(8.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 12.0, resolutionTextView.frame.size.height)];
    resolutionSlider.tag = 99;
    [resolutionSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [resolutionSlider setBackgroundColor:[UIColor clearColor]];
    resolutionSlider.minimumValue = 25;
    resolutionSlider.maximumValue = 150;
    resolutionSlider.continuous = YES;
    resolutionSlider.value = [getPreference(@"resolution") intValue];
    [scrollView addSubview:resolutionSlider];

    UILabel *memTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=40.0, 0.0, 30.0)];
    memTextView.text = @"Allocated RAM";
    memTextView.numberOfLines = 0;
    memTextView.textAlignment = NSTextAlignmentCenter;
    [memTextView sizeToFit];
    tempRect = memTextView.frame;
    tempRect.size.height = 30.0;
    memTextView.frame = tempRect;
    [scrollView addSubview:memTextView];

    DBNumberedSlider *memSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(8.0 + btnsizeTextView.frame.size.width, currY, self.view.frame.size.width - btnsizeTextView.frame.size.width - 12.0, resolutionTextView.frame.size.height)];
    memSlider.tag = 100;
    [memSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [memSlider setBackgroundColor:[UIColor clearColor]];
    memSlider.minimumValue = roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.25);
    memSlider.maximumValue = roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.85);
    memSlider.fontSize = 10;
    memSlider.continuous = YES;
    memSlider.value = [getPreference(@"allocated_memory") intValue];
    [scrollView addSubview:memSlider];

    UILabel *jargsTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=45.0, 0.0, 0.0)];
    jargsTextView.text = @"Java arguments  ";
    jargsTextView.numberOfLines = 0;
    [jargsTextView sizeToFit];
    [scrollView addSubview:jargsTextView];

    UITextField *jargsTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [jargsTextField addTarget:jargsTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jargsTextField.tag = 101;
    jargsTextField.delegate = self;
    jargsTextField.placeholder = @"Specify arguments...";
    jargsTextField.text = (NSString *) getPreference(@"java_args");
    jargsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jargsTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:jargsTextField];

    UILabel *rendTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=40.0, 0.0, 0.0)];
    rendTextView.text = @"Renderer";
    rendTextView.numberOfLines = 0;
    [rendTextView sizeToFit];
    [scrollView addSubview:rendTextView];

    UITextField *rendTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [rendTextField addTarget:rendTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    rendTextField.tag = 102;
    rendTextField.delegate = self;
    rendTextField.placeholder = @"Override renderer...";
    rendTextField.text = (NSString *) getPreference(@"renderer");
    rendTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    rendTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:rendTextField];

    UILabel *jhomeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=40.0, 0.0, 0.0)];
    jhomeTextView.text = @"Java home";
    jhomeTextView.numberOfLines = 0;
    [jhomeTextView sizeToFit];
    [scrollView addSubview:jhomeTextView];

    UITextField *jhomeTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, currY, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [jhomeTextField addTarget:jhomeTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jhomeTextField.tag = 103;
    jhomeTextField.delegate = self;
    jhomeTextField.placeholder = @"Override Java path...";
    jhomeTextField.text = (NSString *) getPreference(@"java_home");
    jhomeTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jhomeTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:jhomeTextField];

    if ([getPreference(@"option_warn") boolValue] == YES) {
        UIAlertController *preferenceWarn = [UIAlertController alertControllerWithTitle:@"Restart required" message:@"Some options in this menu will require that you restart the launcher for them to take effect."preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:preferenceWarn animated:YES completion:nil];
        [preferenceWarn addAction:ok];
        setPreference(@"option_warn", @NO);
    }

    UILabel *noshaderconvTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, currY+=40.0, 0.0, 0.0)];
    noshaderconvTextView.text = @"Disable gl4es 1.1.5 shaderconv";
    noshaderconvTextView.numberOfLines = 0;
    [noshaderconvTextView sizeToFit];
    [scrollView addSubview:noshaderconvTextView];

    UISwitch *noshaderconvSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width - 58.0, currY, 50.0, 30)];
    noshaderconvSwitch.tag = 104;
    [noshaderconvSwitch setOn:[getPreference(@"disable_gl4es_shaderconv") boolValue] animated:NO];
    [noshaderconvSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [scrollView addSubview:noshaderconvSwitch];

    if (@available(iOS 14.0, *)) {
        // use UIMenu
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"questionmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
        UIAction *option1 = [UIAction actionWithTitle:@"Button scale" image:[[UIImage systemImageNamed:@"aspectratio"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Resolution" image:[[UIImage systemImageNamed:@"viewfinder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        UIAction *option3 = [UIAction actionWithTitle:@"Java arguments" image:[[UIImage systemImageNamed:@"character.cursor.ibeam"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAction *option4 = [UIAction actionWithTitle:@"Renderer" image:[[UIImage systemImageNamed:@"cpu"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAction *option5 = [UIAction actionWithTitle:@"Java home" image:[[UIImage systemImageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAction *option6 = [UIAction actionWithTitle:@"Disable shaderconv" image:[[UIImage systemImageNamed:@"circle.lefthalf.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option1, option2, option3, option4, option5, option6]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
    }

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == 101) {
        setPreference(@"java_args", textField.text);
    } else if (textField.tag == 102) {
        setPreference(@"renderer", textField.text);
        setenv("RENDERER", textField.text.UTF8String, 1);
    } else if (textField.tag == 103) {
        setPreference(@"java_home", textField.text);
        if (![textField.text containsString:@"java-8-openjdk"]) {
            UIAlertController *javaAlert = [UIAlertController alertControllerWithTitle:@"Java version is not Java 8" message:@"Minecraft versions below 1.6, modded below 1.16.4, and the mod installer will not work unless you have Java 8 installed on your device."preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [self presentViewController:javaAlert animated:YES completion:nil];
            [javaAlert addAction:ok];
        }
    }
}

- (void)helpMenu {
    if (@available(iOS 14.0, *)) {
        // UIMenu
    } else {
        UIAlertController *helpAlert = [UIAlertController alertControllerWithTitle:@"Needing help with these preferences?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *btnscale = [UIAlertAction actionWithTitle:@"Button scale" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        UIAlertAction *resolution = [UIAlertAction actionWithTitle:@"Resolution" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:RESOLUTION];}];
        UIAlertAction *jargs = [UIAlertAction actionWithTitle:@"Java arguments" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAlertAction *renderer = [UIAlertAction actionWithTitle:@"Renderer"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAlertAction *jhome = [UIAlertAction actionWithTitle:@"Java home" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAlertAction *noshaderconv = [UIAlertAction actionWithTitle:@"Disable shaderconv" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:NOSHADERCONV];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [self setPopoverProperties:helpAlert.popoverPresentationController sender:(UIButton *)self.navigationItem.rightBarButtonItem];
        [self presentViewController:helpAlert animated:YES completion:nil];
        [helpAlert addAction:btnscale];
        [helpAlert addAction:resolution];
        [helpAlert addAction:jargs];
        [helpAlert addAction:renderer];
        [helpAlert addAction:jhome];
        [helpAlert addAction:noshaderconv];
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
    } else if(setting == JARGS) {
        title = @"Java arguments";
        message = @"This option allows you to edit arguments that can be passed to Minecraft. Not all arguments work with PojavLauncher, so be aware. This option also requires a restart of the launcher to take effect.";
    } else if(setting == REND) {
        title = @"Renderer";
        message = @"This option allows you to change the renderer in use. Typing 'libgl4es_115.dylib' may fix sheep and banner colors on 1.16 and allow 1.17 to be played, but will also not work with older versions.";
    } else if(setting == JHOME) {
        title = @"Java home";
        message = @"This option allows you to change the Java executable directory. Typing '/usr/lib/jvm/java-16-openjdk' may allow you to play 1.17, however older versions and most versions of modded Minecraft, as well as the mod installer, will not work. This option also requires a restart of the launcher to take effect.";
    } else if(setting == NOSHADERCONV) {
        title = @"Disable shaderconv";
        message = @"This option allows you to disable the shader converter inside gl4es 1.1.5 in order to let ANGLE processes them directly. This option is experimental and should only be enabled when playing Minecraft 1.17 or above.";
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
                UIAlertController *offlineAlert = [UIAlertController alertControllerWithTitle:@"High memory value selected." message:@"Due to limitations in the operating system itself, you will need to use a tool like overb0ard to prevent jetsam crashes." preferredStyle:UIAlertControllerStyleActionSheet];
                [self setPopoverProperties:offlineAlert.popoverPresentationController sender:(UIButton *)sender];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [self presentViewController:offlineAlert animated:YES completion:nil];
                [offlineAlert addAction:ok];
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
        case 104:
            setPreference(@"disable_gl4es_shaderconv", @(sender.isOn));
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

@end
