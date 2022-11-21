#import <UIKit/UIKit.h>

NSArray<NSDictionary *> *remoteVersionList;

@interface LauncherNavigationController : UINavigationController

@property(nonatomic) UIProgressView *progressViewMain, *progressViewSub;
@property(nonatomic) UILabel* progressText;
@property(nonatomic) UIButton* buttonInstall;

- (void)reloadVersionList:(int)type;

@end
