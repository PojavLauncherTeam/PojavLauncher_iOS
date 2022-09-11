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
    setViewBackgroundColor(self.view);
    [self setTitle:NSLocalizedString(@"FAQ", nil)];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    NSString *snapheadingtext = @"Vanilla versions after 21w08b";
    
    faqcurrY = 4.0;
    
    [scrollView addSubview:[self faqContent:true text:@"Notice about older devices" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"If you're using a device with less than 2GB of memory, you may not be able to play PojavLauncher with a good experience, if at all." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Modded versions before 1.16" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-8-jre from Doregon's Repo and change Java home in Preferences to 'Java 8'." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Vanilla versions after 21w10b" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-16-jre and change the Renderer in Preferences to tinygl4angle." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Vanilla versions after 21w37a" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"In order to use these versions, you need to install openjdk-17-jre and change the Renderer in Preferences to tinygl4angle. If you are using unc0ver/checkra1n, switch to or wait for a Procursus jailbreak." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Sodium versions for 1.17 and higher" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"Sodium is currently broken with 1.17 and higher, due to the workaround required to get these versions to launch." width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Jetsam crashing" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"Even though PojavLauncher only allocates 1/4 of the system's total memory, jetsam can still kill the game. A solution is described on the PojavLauncher website (iOS Wiki > Going further > overb0arding)" width:width]];
    [scrollView addSubview:[self faqContent:true text:@"Cosmetica capes" width:width]];
    [scrollView addSubview:[self faqContent:false text:@"To get started with Cosmetica capes, install OptiFine or the Cosmetica Mod, and visit login.cosmetica.cc to link with your Minecraft account." width:width]];
    
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, faqcurrY);
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

@end
