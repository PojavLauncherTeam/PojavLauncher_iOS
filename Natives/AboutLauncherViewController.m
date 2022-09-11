#import "AboutLauncherViewController.h"
#import "UpdateHistoryViewController.h"

#include "utils.h"

#import <sys/utsname.h>

@interface AboutLauncherViewController()
@property (nonatomic, strong) UIActivityViewController *activityViewController;
@end

@implementation AboutLauncherViewController
@synthesize activityViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    setViewBackgroundColor(self.view);
    [self setTitle:NSLocalizedString(@"login.menu.about", nil)];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;
    int rawHeight = (int) roundf(screenBounds.size.height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height + 5, width, height)];
    [self.view addSubview:scrollView];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // TODO: Move this into utils?
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];

    UILabel *logoVerView = [[UILabel alloc] initWithFrame:CGRectMake(4, 0, width - 8, 30)];
    logoVerView.text = [NSString stringWithFormat:@"version 2.1 %s (%s - %s) on %@ with iOS %@", CONFIG_TYPE, CONFIG_BRANCH, CONFIG_COMMIT, deviceModel, currSysVer];
    logoVerView.lineBreakMode = NSLineBreakByWordWrapping;
    logoVerView.numberOfLines = 0;
    [scrollView addSubview:logoVerView];
    [logoVerView setFont:[UIFont boldSystemFontOfSize:20]];

    CGFloat logoNoteViewOriginY;
    if(@available (iOS 14.0, *)) {
        // UIMenu on the main screen
        logoNoteViewOriginY = logoVerView.frame.origin.y + logoVerView.frame.size.height + 5;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send your logs" style:UIBarButtonItemStyleDone target:self action:@selector(latestLogShare)];
        UIButton *updateHistoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [updateHistoryButton setTitle:@"See the recent changelog." forState:UIControlStateNormal];
        updateHistoryButton.frame = CGRectMake(4, logoVerView.frame.origin.y + logoVerView.frame.size.height + 5, width - 8, 25.0);
        updateHistoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [updateHistoryButton addTarget:self action:@selector(updateHistory) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:updateHistoryButton];
        logoNoteViewOriginY = logoVerView.frame.origin.y + logoVerView.frame.size.height + updateHistoryButton.frame.size.height + 9;
    }

    UILabel *logoNoteView = [[UILabel alloc] initWithFrame:CGRectMake(4.0, logoNoteViewOriginY, width - 8, 700)];
    logoNoteView.text = @"Created by PojavLauncherTeam in 2022. We do not exist on TikTok. No one from the dev team makes TikTok videos.";
    logoNoteView.lineBreakMode = NSLineBreakByWordWrapping;
    logoNoteView.numberOfLines = 0;
    [logoNoteView sizeToFit];
    [scrollView addSubview:logoNoteView];

    UITextView *linkTextView = [[UITextView alloc] initWithFrame:CGRectMake(-1, logoNoteView.frame.origin.y + logoNoteView.frame.size.height + 9, width - 8, 84)];
    linkTextView.text = @"Discord: https://discord.gg/x5pxnANzbX\nSubreddit: https://reddit.com/r/PojavLauncher\nWiki: https://pojav.ml";
    linkTextView.editable = NO;
    linkTextView.dataDetectorTypes = UIDataDetectorTypeAll;
    [scrollView addSubview:linkTextView];
    [linkTextView setFont:[UIFont systemFontOfSize:17]];
    
    UILabel *safetyNoteView = [[UILabel alloc] initWithFrame:CGRectMake(4, linkTextView.frame.origin.y + linkTextView.frame.size.height - 2, width - 8, 700)];
    safetyNoteView.text = @"Stay safe when jailbroken. Make sure to install PojavLauncher from the official repositories to prevent the risk of malware.";
    safetyNoteView.lineBreakMode = NSLineBreakByWordWrapping;
    safetyNoteView.numberOfLines = 0;
    [safetyNoteView sizeToFit];
    [scrollView addSubview:safetyNoteView];

    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd"];
    NSString* date = [dateFormatter stringFromDate:[NSDate date]];
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        UILabel *technoDay = [[UILabel alloc] initWithFrame:CGRectMake(4, safetyNoteView.frame.origin.y + safetyNoteView.frame.size.height + 9, width - 8, 700)];
        technoDay.text = @"May you rest in peace, Technoblade. The Minecraft community will always remember you.";
        technoDay.lineBreakMode = NSLineBreakByWordWrapping;
        technoDay.numberOfLines = 0;
        [technoDay sizeToFit];
        [scrollView addSubview:technoDay];
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, technoDay.frame.origin.y + technoDay.frame.size.height + 0);
    } else {
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, safetyNoteView.frame.origin.y + safetyNoteView.frame.size.height + 0);
    }
}

-(void)latestLogShare
{
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("HOME")];
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]] applicationActivities:nil];

    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)updateHistory {
    UpdateHistoryViewController *vc = [[UpdateHistoryViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
