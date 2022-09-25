#import <UIKit/UIKit.h>

NSArray<NSDictionary *> *remoteVersionList;

@interface LauncherNavigationController : UINavigationController

@property UIProgressView *progressViewMain, *progressViewSub;
@property UILabel* progressText;
@property UIButton* buttonInstall;

- (void)reloadVersionList:(int)type;

@end
