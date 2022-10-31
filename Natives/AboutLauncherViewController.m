#import "AboutLauncherViewController.h"
#import "UpdateHistoryViewController.h"

#include "utils.h"

#import <sys/utsname.h>

@interface AboutLauncherViewController()
@end

@implementation AboutLauncherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    setViewBackgroundColor(self.view);
    [self setTitle:NSLocalizedString(@"login.menu.about", nil)];

    // TODO: Move this into utils?
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];

    if(@available (iOS 14.0, *)) {
        // UIMenu on the main screen
    } else {
        self.navigationItem.rightBarButtonItems = @[
            [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"login.menu.sendlogs", nil) style:UIBarButtonItemStyleDone target:self action:@selector(latestLogShare)],
            [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"login.menu.updates", nil) style:UIBarButtonItemStyleDone target:self action:@selector(updateHistory)]
        ];
    }

    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.frame];
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.editable = NO;
    [self.view addSubview:textView];

    textView.text = [NSString stringWithFormat:@"version 2.1 %s (%s - %s) on %@ with iOS %@\n\n", CONFIG_TYPE, CONFIG_BRANCH, CONFIG_COMMIT, deviceModel, currSysVer];

    [textView insertText:
        @"Created by PojavLauncherTeam in 2022.\n"
        @"Discord: https://discord.gg/x5pxnANzbX\n"
        @"Subreddit: https://reddit.com/r/PojavLauncher\n"
        @"TikTok: unavailable, we do not make videos on TikTok\n"
        @"Wiki: https://pojavlauncherteam.github.io\n"
    ];

    if (getenv("POJAV_DETECTEDJB")) {
        [textView insertText:@"Stay safe when jailbroken. "];
    }
    [textView insertText:@"Make sure to install PojavLauncher from the official repositories to prevent the risk of malware.\n\n"];

    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd"];
    NSString* date = [dateFormatter stringFromDate:[NSDate date]];
    if([date isEqualToString:@"06-29"] || [date isEqualToString:@"06-30"] || [date isEqualToString:@"07-01"]) {
        [textView insertText:@"May you rest in peace, Technoblade. The Minecraft community will always remember you."];
    }

    NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:textView.text];
    [newString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, newString.length)];
    [newString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, [textView.text rangeOfString:@"\n"].location)];
    textView.attributedText = newString;

    if (@available(iOS 13.0, *)) {
        textView.textColor = UIColor.labelColor;
    }
}

-(void)latestLogShare
{
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("HOME")];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt", [NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)updateHistory {
    UpdateHistoryViewController *vc = [[UpdateHistoryViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
