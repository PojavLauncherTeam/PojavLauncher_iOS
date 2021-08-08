#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"

#include "utils.h"

#define BTNSCALE 0
#define JARGS 1
#define REND 2
#define JHOME 3

@interface LauncherPreferencesViewController () {
}

// - (void)method

@end

@implementation LauncherPreferencesViewController

UITextField* rendTextField;
UITextField* jargsTextField;
UITextField* jhomeTextField;
UITextField* versionTextField;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"Preferences"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    UILabel *btnsizeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 8.0, 0.0, 30.0)];
    btnsizeTextView.text = @"Button scale (%)";
    btnsizeTextView.numberOfLines = 0;
    btnsizeTextView.textAlignment = NSTextAlignmentCenter;
    [btnsizeTextView sizeToFit];
    CGRect tempRect = btnsizeTextView.frame;
    tempRect.size.height = 30.0;
    btnsizeTextView.frame = tempRect;
    [scrollView addSubview:btnsizeTextView];
    
    DBNumberedSlider *buttonSizeSlider = [[DBNumberedSlider alloc] initWithFrame:CGRectMake(8.0 + btnsizeTextView.frame.size.width, 8.0, self.view.frame.size.width - btnsizeTextView.frame.size.width - 12.0, btnsizeTextView.frame.size.height)];
    buttonSizeSlider.tag = 1;
    [buttonSizeSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [buttonSizeSlider setBackgroundColor:[UIColor clearColor]];
    buttonSizeSlider.minimumValue = 50.0;
    buttonSizeSlider.maximumValue = 500.0;
    buttonSizeSlider.continuous = YES;
    buttonSizeSlider.value = ((NSNumber *) getPreference(@"button_scale")).floatValue;
    [scrollView addSubview:buttonSizeSlider];

    UILabel *jargsTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 54.0, 0.0, 0.0)];
    jargsTextView.text = @"Java arguments  ";
    jargsTextView.numberOfLines = 0;
    [jargsTextView sizeToFit];
    [scrollView addSubview:jargsTextView];

    jargsTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, 54.0, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [jargsTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jargsTextField.tag = 100;
    jargsTextField.delegate = self;
    jargsTextField.placeholder = @"Specify arguments...";
    jargsTextField.text = (NSString *) getPreference(@"java_args");
    jargsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jargsTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:jargsTextField];

    UILabel *rendTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 94.0, 0.0, 0.0)];
    rendTextView.text = @"Renderer";
    rendTextView.numberOfLines = 0;
    [rendTextView sizeToFit];
    [scrollView addSubview:rendTextView];

    rendTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, 94.0, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [rendTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    rendTextField.tag = 101;
    rendTextField.delegate = self;
    rendTextField.placeholder = @"Override renderer...";
    rendTextField.text = (NSString *) getPreference(@"renderer");
    rendTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    rendTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:rendTextField];

    UILabel *jhomeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 134.0, 0.0, 0.0)];
    jhomeTextView.text = @"Java home";
    jhomeTextView.numberOfLines = 0;
    [jhomeTextView sizeToFit];
    [scrollView addSubview:jhomeTextView];

    jhomeTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x + 3, 134.0, width - jargsTextView.bounds.size.width - 8.0, 30)];
    [jhomeTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jhomeTextField.tag = 102;
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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStyleDone target:self action:@selector(helpMenu)];
    if (@available(iOS 14.0, *)) {
        // use UIMenu
        UIAction *option1 = [UIAction actionWithTitle:@"Button scale" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:BTNSCALE];}];
        UIAction *option2 = [UIAction actionWithTitle:@"Java arguments" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAction *option3 = [UIAction actionWithTitle:@"Renderer" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAction *option4 = [UIAction actionWithTitle:@"Java home" image:nil identifier:nil
                             handler:^(__kindof UIAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIMenu *menu = [UIMenu menuWithTitle:@"Help menu" image:nil identifier:nil
                        options:UIMenuOptionsDisplayInline children:@[option1, option2, option3, option4]];
        self.navigationItem.rightBarButtonItem.action = nil;
        self.navigationItem.rightBarButtonItem.primaryAction = nil;
        self.navigationItem.rightBarButtonItem.menu = menu;
    }

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 100) {
        setPreference(@"java_args", jargsTextField.text);
    } else if (textField.tag == 101) {
        setPreference(@"renderer", rendTextField.text);
    } else if (textField.tag == 102) {
        setPreference(@"java_home", jhomeTextField.text);
        if (![jhomeTextField.text containsString:@"java-8-openjdk"]) {
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
        UIAlertAction *jargs = [UIAlertAction actionWithTitle:@"Java arguments" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JARGS];}];
        UIAlertAction *renderer = [UIAlertAction actionWithTitle:@"Renderer"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:REND];}];
        UIAlertAction *jhome = [UIAlertAction actionWithTitle:@"Java home" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self helpAlertOpt:JHOME];}];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [self presentViewController:helpAlert animated:YES completion:nil];
        [helpAlert addAction:btnscale];
        [helpAlert addAction:jargs];
        [helpAlert addAction:renderer];
        [helpAlert addAction:jhome];
        [helpAlert addAction:cancel];
    }
}

- (void)helpAlertOpt:(int)setting {
    NSString *title;
    NSString *message;
    if(setting == BTNSCALE) {
        title = @"Button scale";
        message = @"This option allows you to tweak the button scale of the on-screen controls. The numbered slider extends from 50 to 500.";
    } else if(setting == JARGS) {
        title = @"Java arguments";
        message = @"This option allows you to edit arguments that can be passed to Minecraft. Not all arguments work with PojavLauncher, so be aware. This option also requires a restart of the launcher to take effect.";
    } else if(setting == REND) {
        title = @"Renderer";
        message = @"This option allows you to change the renderer in use. Typing 'libgl4es_115.dylib' may fix sheep and banner colors on 1.16 and allow 1.17 to be played, but will also not work with older versions. This option also requires a restart of the launcher to take effect.";
    } else if(setting == JHOME) {
        title = @"Java home";
        message = @"This option allows you to change the Java executable directory. Typing '/usr/lib/jvm/java-16-openjdk' may allow you to play 1.17, however older versions and most versions of modded Minecraft, as well as the mod installer, will not work. This option also requires a restart of the launcher to take effect.";
    }
    UIAlertController *helpAlertOpt = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [helpAlertOpt addAction:ok];
    [self presentViewController:helpAlertOpt animated:YES completion:nil];
}

- (void)sliderMoved:(DBNumberedSlider *)sender {
    switch (sender.tag) {
        case 1:
            setPreference(@"button_scale", @(sender.value));
            break;
        default:
            NSLog(@"what does slider %ld for? implement me!", sender.tag);
            break;
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

@end
