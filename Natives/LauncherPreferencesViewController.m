#import "DBNumberedSlider.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"

#include "utils.h"

@interface LauncherPreferencesViewController () {
}

// - (void)method

@end

@implementation LauncherPreferencesViewController

UITextField* gl4esTextField;
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

    jargsTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x, 54.0, width - jargsTextView.bounds.size.width - 8.0, height - 58.0)];
    [jargsTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    jargsTextField.tag = 100;
    jargsTextField.delegate = self;
    jargsTextField.placeholder = @"Specify arguments...";
    jargsTextField.text = (NSString *) getPreference(@"java_args");
    jargsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    jargsTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:jargsTextField];

    UILabel *gl4esTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 94.0, 0.0, 0.0)];
    gl4esTextView.text = @"GL4ES dylib";
    gl4esTextView.numberOfLines = 0;
    [gl4esTextView sizeToFit];
    [scrollView addSubview:gl4esTextView];

    gl4esTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x, 94.0, width - jargsTextView.bounds.size.width - 8.0, height - 58.0)];
    [gl4esTextField addTarget:versionTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    gl4esTextField.tag = 101;
    gl4esTextField.delegate = self;
    gl4esTextField.placeholder = @"Override version...";
    gl4esTextField.text = (NSString *) getPreference(@"gl4es_libname");
    gl4esTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    gl4esTextField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [scrollView addSubview:gl4esTextField];

    UILabel *jhomeTextView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 134.0, 0.0, 0.0)];
    jhomeTextView.text = @"Java home";
    jhomeTextView.numberOfLines = 0;
    [jhomeTextView sizeToFit];
    [scrollView addSubview:jhomeTextView];

    jhomeTextField = [[UITextField alloc] initWithFrame:CGRectMake(buttonSizeSlider.frame.origin.x, 134.0, width - jargsTextView.bounds.size.width - 8.0, height - 58.0)];
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

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 100) {
        setPreference(@"java_args", jargsTextField.text);
    } else if (textField.tag == 101) {
        setPreference(@"gl4es_libname", gl4esTextField.text);
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
