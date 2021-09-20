#import <UIKit/UIKit.h>

UIProgressView* install_progress_bar;
UILabel* install_progress_text;
UIButton* install_button;

@interface LauncherViewController : UIViewController

+ (void)fetchVersionList;
+ (void)fetchLocalVersionList:(NSMutableArray *)finalVersionList withPreviousIndex:(int)index;

@end
