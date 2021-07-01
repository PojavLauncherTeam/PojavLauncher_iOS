#import "UpdateHistoryViewController.h"

#include "utils.h"


@interface UpdateHistoryViewController () {
}
@end

@implementation UpdateHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"Update History"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    int rawHeight = (int) roundf(screenBounds.size.height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, rawHeight)];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    UILabel *latestVerNote = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, scrollView.frame.size.width - 4, 30.0)];
    latestVerNote.text = @"Current version";
    latestVerNote.lineBreakMode = NSLineBreakByWordWrapping;
    latestVerNote.numberOfLines = 0;
    [scrollView addSubview:latestVerNote];
    [latestVerNote setFont:[UIFont boldSystemFontOfSize:25]];

    UILabel *latestVerView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerNote.frame.origin.y + latestVerNote.frame.size.height, scrollView.frame.size.width - 4, 30.0)];
    latestVerView.text = @"1.3";
    latestVerView.lineBreakMode = NSLineBreakByWordWrapping;
    latestVerView.numberOfLines = 0;
    [scrollView addSubview:latestVerView];
    [latestVerView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *latestVerChanges = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerView.frame.origin.y + latestVerView.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    latestVerChanges.text = @"Changes";
    latestVerChanges.numberOfLines = 0;
    [scrollView addSubview:latestVerChanges];
    [latestVerChanges setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *latestVerChangesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerChanges.frame.origin.y + latestVerChanges.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    latestVerChangesCont.text = @"- The Login view has been simplified to three easy buttons\n"
                                 "- New FAQ page to show quick answers to questions\n"
                                 "- New About view to show quick details, links, and update history\n"
                                 "- The Select Account screen is now a pop-up window\n"
                                 "- New picker view to switch versions without typing them manually\n"
                                 "- Support to show your locally installed clients\n"
                                 "- New environment variable for JAVA_HOME, for switching between JDK 8 and JDK 16";
    latestVerChangesCont.numberOfLines = 0;
    [latestVerChangesCont sizeToFit];
    [scrollView addSubview:latestVerChangesCont];

    UILabel *latestVerFixes = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerChangesCont.frame.origin.y + latestVerChangesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    latestVerFixes.text = @"Fixes";
    latestVerFixes.numberOfLines = 0;
    [scrollView addSubview:latestVerFixes];
    [latestVerFixes setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *latestVerFixesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerFixes.frame.origin.y + latestVerFixes.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    latestVerFixesCont.text = @"This section isn't complete.";
    latestVerFixesCont.numberOfLines = 0;
    [latestVerFixesCont sizeToFit];
    [scrollView addSubview:latestVerFixesCont];

    UILabel *latestVerIssues = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerFixesCont.frame.origin.y + latestVerFixesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    latestVerIssues.text = @"Issues";
    latestVerIssues.numberOfLines = 0;
    [scrollView addSubview:latestVerIssues];
    [latestVerIssues setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *latestVerIssuesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerIssues.frame.origin.y + latestVerIssues.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    latestVerIssuesCont.text = @"This section isn't complete.";
    latestVerIssuesCont.numberOfLines = 0;
    [latestVerIssuesCont sizeToFit];
    [scrollView addSubview:latestVerIssuesCont];

    UILabel *prevVerNote = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerIssuesCont.frame.origin.y + latestVerIssuesCont.frame.size.height + 10.0, scrollView.frame.size.width - 4, 30.0)];
    prevVerNote.text = @"Previous versions";
    prevVerNote.lineBreakMode = NSLineBreakByWordWrapping;
    prevVerNote.numberOfLines = 0;
    [scrollView addSubview:prevVerNote];
    [prevVerNote setFont:[UIFont boldSystemFontOfSize:25]];

    UILabel *backOneVerView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, prevVerNote.frame.origin.y + prevVerNote.frame.size.height, scrollView.frame.size.width - 4, 30.0)];
    backOneVerView.text = @"1.2";
    backOneVerView.lineBreakMode = NSLineBreakByWordWrapping;
    backOneVerView.numberOfLines = 0;
    [scrollView addSubview:backOneVerView];
    [backOneVerView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *backOneVerChanges = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerView.frame.origin.y + backOneVerView.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerChanges.text = @"Changes";
    backOneVerChanges.numberOfLines = 0;
    [scrollView addSubview:backOneVerChanges];
    [backOneVerChanges setFont:[UIFont boldSystemFontOfSize:17]];


    UILabel *backOneVerChangesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerChanges.frame.origin.y + backOneVerChanges.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerChangesCont.text = @"- Use new method for Microsoft login\n"
                                 "- Added gl4es 1.1.5 as an option\n"
                                 "- WIP custom controls (can be changed by placing at /var/mobile/Documents/.pojavlauncher/controlmap/default.json). Note that some functions may not work properly.\n"
                                 "- WIP external mouse support\n"
                                 "- Custom environment variables, in /var/mobile/Documents/.pojavlauncher/custom_env.txt\n"
                                 "- Reduction of file size with removal of unused binaries\n"
                                 "- Moved latestlog.txt and overrideargs.txt to /var/mobile/Documents/.pojavlauncher";
    backOneVerChangesCont.numberOfLines = 0;
    [backOneVerChangesCont sizeToFit];
    [scrollView addSubview:backOneVerChangesCont];

    UILabel *backOneVerFixes = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerChangesCont.frame.origin.y + backOneVerChangesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backOneVerFixes.text = @"Fixes";
    backOneVerFixes.numberOfLines = 0;
    [scrollView addSubview:backOneVerFixes];
    [backOneVerFixes setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backOneVerFixesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerFixes.frame.origin.y + backOneVerFixes.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerFixesCont.text = @"- Fix file permission issues during install of package\n"
                                "- Hide home bar like Bedrock Edition\n"
                                "- Properly hide iPad status bar";
    backOneVerFixesCont.numberOfLines = 0;
    [backOneVerFixesCont sizeToFit];
    [scrollView addSubview:backOneVerFixesCont];

    UILabel *backOneVerIssues = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerFixesCont.frame.origin.y + backOneVerFixesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backOneVerIssues.text = @"Issues";
    backOneVerIssues.numberOfLines = 0;
    [scrollView addSubview:backOneVerIssues];
    [backOneVerIssues setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backOneVerIssuesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerIssues.frame.origin.y + backOneVerIssues.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerIssuesCont.text = @"- Crash if login to Microsoft fails\n"
                                 "- Several Forge versions won’t work due to removed deprecated classes (see #67 and #68)\n"
                                 "- Control buttons notch offset seems doubled\n"
                                 "- Text input will not work on 1.12.2 and below";
    backOneVerIssuesCont.numberOfLines = 0;
    [backOneVerIssuesCont sizeToFit];
    [scrollView addSubview:backOneVerIssuesCont];

    UILabel *backTwoVerView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerIssuesCont.frame.origin.y + backOneVerIssuesCont.frame.size.height + 20.0, scrollView.frame.size.width - 4, 30.0)];
    backTwoVerView.text = @"1.1";
    backTwoVerView.lineBreakMode = NSLineBreakByWordWrapping;
    backTwoVerView.numberOfLines = 0;
    [scrollView addSubview:backTwoVerView];
    [backTwoVerView setFont:[UIFont boldSystemFontOfSize:20]];

    UILabel *backTwoVerChanges = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerView.frame.origin.y + backTwoVerView.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerChanges.text = @"Changes";
    backTwoVerChanges.numberOfLines = 0;
    [scrollView addSubview:backTwoVerChanges];
    [backTwoVerChanges setFont:[UIFont boldSystemFontOfSize:17]];


    UILabel *backTwoVerChangesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerChanges.frame.origin.y + backTwoVerChanges.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerChangesCont.text = @"- Added a place to customize JVM Flags, by create and edit `minecraft/overrideargs.txt` file.\n"
                                 "- Changed button offset for avoiding notch cutout on iPhone X and newer.\n"
                                 "- Forge 1.13+ (not all) and Fabric API are now supported.\n"
                                 "- launcher_profiles.json is now automatically created.\n"
                                 "- Minecraft 1.6.1 to 1.13.2 are now playable.\n"
                                 "- Mojang authentication was re-written, so it should work now.";
    backTwoVerChangesCont.numberOfLines = 0;
    [backTwoVerChangesCont sizeToFit];
    [scrollView addSubview:backTwoVerChangesCont];

    UILabel *backTwoVerFixes = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerChangesCont.frame.origin.y + backTwoVerChangesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerFixes.text = @"Fixes";
    backTwoVerFixes.numberOfLines = 0;
    [scrollView addSubview:backTwoVerFixes];
    [backTwoVerFixes setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backTwoVerFixesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerFixes.frame.origin.y + backTwoVerFixes.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerFixesCont.text = @"- Fixed random crashes occur while Minecraft is initializing.";
    backTwoVerFixesCont.numberOfLines = 0;
    [backTwoVerFixesCont sizeToFit];
    [scrollView addSubview:backTwoVerFixesCont];

    UILabel *backTwoVerIssues = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerFixesCont.frame.origin.y + backTwoVerFixesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerIssues.text = @"Issues";
    backTwoVerIssues.numberOfLines = 0;
    [scrollView addSubview:backTwoVerIssues];
    [backTwoVerIssues setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backTwoVerIssuesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backTwoVerIssues.frame.origin.y + backTwoVerIssues.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backTwoVerIssuesCont.text = @"- Crash if login to Microsoft fails\n"
                                 "- Several Forge versions won’t work due to removed deprecated classes (see #67 and #68)\n"
                                 "- Text input will not work on 1.12.2 and below";
    backTwoVerIssuesCont.numberOfLines = 0;
    [backTwoVerIssuesCont sizeToFit];
    [scrollView addSubview:backTwoVerIssuesCont];

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 900);

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
