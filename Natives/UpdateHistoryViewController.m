#import "UpdateHistoryViewController.h"

#include "utils.h"

@interface UpdateHistoryViewController () {
}
-(UILabel *)uhContent:(bool)isHeading size:(int)size text:(NSString *)text width:(int)width;
@end

@implementation UpdateHistoryViewController
CGFloat uhcurrY = 4.0;
- (void)viewDidLoad
{
    [super viewDidLoad];
    setViewBackgroundColor(self.view);

    [self setTitle:NSLocalizedString(@"login.menu.updates", nil)];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    int rawHeight = (int) roundf(screenBounds.size.height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, rawHeight)];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    uhcurrY = 4.0;

    [scrollView addSubview:[self uhContent:true size:25 text:@"Current version" width:width]];
    [scrollView addSubview:[self uhContent:true size:20 text:[NSString stringWithFormat:@"2.1 (%s)", CONFIG_TYPE] width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Changes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Now shows when currently logging in\n"
                            "- Account list now displays profile picture and account type\n"
                            "- Play button is greyed out when launching\n"
                            "- Back button is hidden when launching\n"
                            "- New toggle to allow restarting JVM before launching\n"
                            "- Added WIP Demo mode support!\n"
                            "- Patch log4shell exploit in client\n"
                            "- Keyboard and mouse support deepened\n"
                            "- Custom controls UI completed\n"
                            "- Arc custom capes integration!\n"
                            "- Removed Mojang account login" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Fixes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Slight changes to error messages\n"
                            "- Fix Makefile errors in `deploy` and `ipa`\n"
                            "- Fix some instances of Mojang login failing\n"
                            "- Fix NullPointerException when launching ≤1.6.4\n"
                            "- Fix NullPointerException when setting inherited fields\n"
                            "- Fix \"Share your logs\" not working\n"
                            "- Fix Fabric 1.17+ not launching\n"
                            "- Fix postinst issue on Procursus" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Issues" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Mouse support requires iOS 14.0 or later, keyboards require iOS 13.4 or later\n"
                            "- Old custom control .json files no longer work, remove to fix" width:width]];
    [scrollView addSubview:[self uhContent:true size:25 text:@"Previous versions" width:width]];
    [scrollView addSubview:[self uhContent:true size:20 text:@"2.0 - Raw Iron" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Changes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- The Login view has been simplified to three easy buttons\n"
                            "- The Offline Account has been replaced with Local Account. Installing Minecraft now requires a Mojang or Microsoft account logged in.\n"
                            "- New FAQ page to show quick answers to questions\n"
                            "- New About view to show quick details, links, and update history\n"
                            "- Ability to send logs from within the launcher\n"
                            "- The Select Account screen is now a pop-up window\n"
                            "- New picker view to switch versions without typing them manually\n"
                            "- Support to show your locally installed clients\n"
                            "- New settings page to manage preferences\n"
                            "- OpenJDK 8 support, to allow older versions of modded Minecraft\n"
                            "- New mod installer, built into the launcher\n"
                            "- Unfinished in-launcher custom controls\n"
                            "- Move to /usr/share, for better rootFS compatibility\n"
                            "- New packaging format\n"
                            "   - release, for iOS 14 and lower (full root access jailbreaks)\n"
                            "   - release-rootless, for iOS 15 (Procursus rootless jailbreak)" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Fixes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- WIP fix for typing on 1.12.2 and older\n"
                            "- The hotbar now works across GUI scales\n"
                            "- (With JDK 8) Forge 1.8.9 - 1.15.2 now work\n"
                            "- (With JDK 8) Vanilla 1.5.2 and under now work\n"
                            "- Buttons now scale correctly according to screen size" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Issues" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Crash if login to Microsoft fails\n"
                            "- Old custom control .json files no longer work, remove to fix\n"
                            "- Custom controls settings page is not complete, there may be some issues!\n"
                            "- An unknown issue might cause Taurine, 14.3, and A12+ to crash on launch." width:width]];
    [scrollView addSubview:[self uhContent:true size:20 text:@"1.2" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Changes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Use new method for Microsoft login\n"
                            "- Added gl4es 1.1.5 as an option\n"
                            "- WIP custom controls (can be changed by placing at /var/mobile/Documents/.pojavlauncher/controlmap/default.json). Note that some functions may not work properly.\n"
                            "- WIP external mouse support\n"
                            "- Custom environment variables, in /var/mobile/Documents/.pojavlauncher/custom_env.txt\n"
                            "- Reduction of file size with removal of unused binaries\n"
                            "- Moved latestlog.txt and overrideargs.txt to /var/mobile/Documents/.pojavlauncher" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Fixes" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Fix file permission issues during install of package\n"
                            "- Hide home bar like Bedrock Edition\n"
                            "- Properly hide iPad status bar" width:width]];
    [scrollView addSubview:[self uhContent:true size:17 text:@"Issues" width:width]];
    [scrollView addSubview:[self uhContent:false size:0 text:@"- Crash if login to Microsoft fails\n"
                            "- Several Forge versions won’t work due to removed deprecated classes (see #67 and #68)\n"
                            "- Control buttons notch offset seems doubled\n"
                            "- Text input will not work on 1.12.2 and below" width:width]];
    [scrollView addSubview:[self uhContent:true size:20 text:@"See the GitHub for even earlier releases" width:width]];


    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, uhcurrY);

}

-(UILabel *)uhContent:(bool)isHeading size:(int)size text:(NSString *)text width:(int)width {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(4.0, uhcurrY, width - 40, 30.0)];
    label.text = text;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    if(isHeading) {
        [label setFont:[UIFont boldSystemFontOfSize:size]];
    } else {
        [label sizeToFit];
    }
    uhcurrY+=label.frame.size.height;
    return label;
}

@end
