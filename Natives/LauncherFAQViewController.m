#import "LauncherFAQViewController.h"

#include "utils.h"

@implementation LauncherFAQViewController
CGFloat faqcurrY = 4.0;
- (void)viewDidLoad
{
    [super viewDidLoad];
    setViewBackgroundColor(self.view);
    [self setTitle:NSLocalizedString(@"FAQ", nil)];

    NSMutableAttributedString *faqString = NSMutableAttributedString.new;

    [faqString appendAttributedString:[self makeItem:@"Notice about older devices\nIf you're using a device with less than 2GB of memory, you may not be able to play PojavLauncher with a good experience, if at all.\n\n"]];

    [faqString appendAttributedString:[self makeItem:@"Modded versions before 1.16\nIn order to use these versions, you need to install openjdk-8-jre(*) and change Java home in Preferences to 'Java 8'.\n\n"]];

    [faqString appendAttributedString:[self makeItem:@"Vanilla versions after 21w10b\nIn order to use these versions, you need to install openjdk-17-jre(*) and change the Renderer in Preferences to Auto.\n\n"]];

    [faqString appendAttributedString:[self makeItem:@"(*)\nInstalling external Java is not needed, as .ipa build has already included both Java versions in order to work without jailbreak.\n\n"]];

    [faqString appendAttributedString:[self makeItem:@"Sodium versions for 1.17 and higher\nSodium is currently broken with 1.17 and higher, due to the workaround required to get these versions to launch.\n\n"]];

    [faqString appendAttributedString:[self makeItem:@"Cosmetica capes\nTo get started with Cosmetica capes, install OptiFine or the Cosmetica Mod, and visit https://login.cosmetica.cc to link with your Minecraft account."]];

    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.frame];
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    textView.attributedText = faqString;
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.editable = NO;
    if (@available(iOS 13.0, *)) {
        textView.textColor = UIColor.labelColor;
    }
    [self.view addSubview:textView];
}

- (NSAttributedString *)makeItem:(NSString *)string {
    NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:string];
    [newString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, string.length)];
    [newString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, [string rangeOfString:@"\n"].location)];
    return newString;
}

@end
