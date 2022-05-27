#import <UIKit/UIKit.h>

NSArray* versionList;

@interface LauncherViewController : UIViewController

@property UIProgressView *progressViewMain, *progressViewSub;
@property UILabel* progressText;
@property UIButton* buttonInstall;

+ (void)reloadVersionList:(LauncherViewController *)vc;
+ (void)fetchLocalVersionList:(NSMutableArray *)finalVersionList withPreviousIndex:(int)index;

@end
