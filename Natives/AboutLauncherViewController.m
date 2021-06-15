#import "AboutLauncherViewController.h"

#include "utils.h"

#import <sys/utsname.h>


@interface AboutLauncherViewController () {
}
@property (nonatomic, strong) UIActivityViewController *activityViewController;
@end

@implementation AboutLauncherViewController
@synthesize activityViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"About PojavLauncher"];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    int rawHeight = (int) roundf(screenBounds.size.height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(width / 2, 0, width / 2, rawHeight)];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                          encoding:NSUTF8StringEncoding];
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];

    UILabel *logoVerView = [[UILabel alloc] initWithFrame:CGRectMake(20, height, (width / 2), 20)];
    logoVerView.text = [NSString stringWithFormat:@"version 1.3 (development) on %@ with iOS %@", deviceModel, currSysVer];
    logoVerView.lineBreakMode = NSLineBreakByWordWrapping;
    logoVerView.numberOfLines = 1;
    [logoVerView sizeToFit];
    [self.view addSubview:logoVerView];
    [logoVerView setFont:[UIFont boldSystemFontOfSize:10]];

    UILabel *logoNoteView = [[UILabel alloc] initWithFrame:CGRectMake(20.0, self.navigationController.navigationBar.frame.size.height + 5, (width / 2) - 20, 20)];
    logoNoteView.text = @"Created by PojavLauncherTeam in 2021.\n\nWe do not exist on TikTok. No one from the dev team makes TikTok videos.\n\n";
    logoNoteView.lineBreakMode = NSLineBreakByWordWrapping;
    logoNoteView.numberOfLines = 0;
    [logoNoteView sizeToFit];
    [self.view addSubview:logoNoteView];

    UILabel *discordText = [[UILabel alloc] initWithFrame:CGRectMake(20.0, logoNoteView.frame.size.height + 15, (width / 2), 30.0)];
    discordText.text = @"Discord: ";
    discordText.numberOfLines = 0;
    [discordText sizeToFit];
    [self.view addSubview:discordText];

    UITextView *discordLink = [[UITextView alloc] initWithFrame:CGRectMake(discordText.frame.size.width + 13, logoNoteView.frame.size.height + 7, (width / 2) - (discordText.frame.size.width + 13), 30.0)];
    discordLink.text = @"https://discord.gg/6RpEJda";
    discordLink.editable = NO;
    discordLink.dataDetectorTypes = UIDataDetectorTypeAll;
    [self.view addSubview:discordLink];
    [discordLink setFont:[UIFont systemFontOfSize:17]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send your logs" style:UIBarButtonItemStyleDone target:self action:@selector(latestLogShare)];

    UILabel *latestVerView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, width, 30.0)];
    latestVerView.text = @"1.3";
    latestVerView.lineBreakMode = NSLineBreakByWordWrapping;
    latestVerView.numberOfLines = 0;
    [scrollView addSubview:latestVerView];
    [latestVerView setFont:[UIFont boldSystemFontOfSize:20]];
 
    UILabel *latestVerCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerView.frame.origin.y + latestVerView.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    latestVerCont.text = @"You are running a development build of this version, so it does not have a valid changelog just yet.";
    latestVerCont.numberOfLines = 0;
    [latestVerCont sizeToFit];
    [scrollView addSubview:latestVerCont];

    UILabel *backOneVerView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, latestVerCont.frame.origin.y + latestVerCont.frame.size.height + 20.0, scrollView.frame.size.width - 4, 30.0)];
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
    backOneVerChangesCont.text = @"- Use new method for Microsoft login\n- Moved latestlog.txt and overrideargs.txt to /var/mobile/Documents/.pojavlauncher\n- WIP custom controls and external mouse support";
    backOneVerChangesCont.numberOfLines = 0;
    [backOneVerChangesCont sizeToFit];
    [scrollView addSubview:backOneVerChangesCont];

    UILabel *backOneVerFixes = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerChangesCont.frame.origin.y + backOneVerChangesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backOneVerFixes.text = @"Fixes";
    backOneVerFixes.numberOfLines = 0;
    [scrollView addSubview:backOneVerFixes];
    [backOneVerFixes setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backOneVerFixesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerFixes.frame.origin.y + backOneVerFixes.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerFixesCont.text = @"- Fix file permission issues during install of package\n- Hide home bar like Bedrock Edition\n- Properly hide iPad status bar";
    backOneVerFixesCont.numberOfLines = 0;
    [backOneVerFixesCont sizeToFit];
    [scrollView addSubview:backOneVerFixesCont];

    UILabel *backOneVerIssues = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerFixesCont.frame.origin.y + backOneVerFixesCont.frame.size.height + 5.0, scrollView.frame.size.width - 4, 30.00)];
    backOneVerIssues.text = @"Issues";
    backOneVerIssues.numberOfLines = 0;
    [scrollView addSubview:backOneVerIssues];
    [backOneVerIssues setFont:[UIFont boldSystemFontOfSize:17]];

    UILabel *backOneVerIssuesCont = [[UILabel alloc] initWithFrame:CGRectMake(4.0, backOneVerIssues.frame.origin.y + backOneVerIssues.frame.size.height, scrollView.frame.size.width - 4, 30.00)];
    backOneVerIssuesCont.text = @"- Crash if login to Microsoft fails\n- Several Forge versions won’t work due to removed deprecated classes (see #67 and #68)\n- Text input will not work on 1.12.2 and below";
    backOneVerIssuesCont.numberOfLines = 0;
    [backOneVerIssuesCont sizeToFit];
    [scrollView addSubview:backOneVerIssuesCont];

    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + 800);

}

-(void)latestLogShare
{
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:@"file:///var/mobile/Documents/.pojavlauncher/latestlog.txt"]] applicationActivities:nil];

    [self presentViewController:activityViewController animated:YES completion:nil];
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
