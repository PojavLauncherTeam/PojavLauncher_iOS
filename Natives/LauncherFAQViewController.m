#import "LauncherFAQViewController.h"

#include "utils.h"

@interface LauncherFAQViewController () {
}
-(UILabel *)faqContent:(bool)isHeading text:(NSString *)text width:(int)width;
@end

@implementation LauncherFAQViewController
CGFloat faqcurrY = 4.0;
- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
    
    [self setTitle:@"Launcher FAQ"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 200);

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    NSString *snapheadingtext = @"Vanilla versions after 21w08b";
    
    faqcurrY = 4.0;
    
    [scrollView addSubview:[self faqContent:true text:@"Modded versions before 1.16" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-8-jre from Doregon's Repo and change Java home in Preferences to 'Java 8'." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Vanilla versions after 21w10b" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-16-jre and change the Renderer in Preferences to tinygl4angle." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Vanilla versions after 21w37a" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-17-jre and change the Renderer in Preferences to tinygl4angle. If you are using unc0ver/checkra1n, switch to or wait for a Procursus jailbreak." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Jetsam crashing" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"Even though PojavLauncher only allocates 1/4 of the system's total memory, jetsam can still kill the game. A solution is described on the PojavLauncher website (iOS Wiki > Going further > overb0arding)" width:width]];
    
}

-(UILabel *)faqContent:(bool)isHeading text:(NSString *)text width:(int)width {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(4.0, faqcurrY, width - 40, 30.0)];
    label.text = text;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    if(isHeading) {
        [label setFont:[UIFont boldSystemFontOfSize:20]];
    } else {
        [label sizeToFit];
    }
    faqcurrY+=label.frame.size.height;
    return label;
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
