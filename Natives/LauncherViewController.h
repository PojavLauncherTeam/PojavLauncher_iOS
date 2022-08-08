#import <UIKit/UIKit.h>

NSArray<NSDictionary *> *remoteVersionList;

@interface LauncherViewController : UIViewController

@property UIProgressView *progressViewMain, *progressViewSub;
@property UILabel* progressText;
@property UIButton* buttonInstall;

@end
