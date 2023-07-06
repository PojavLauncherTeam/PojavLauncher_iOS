#import <UIKit/UIKit.h>

NSMutableArray<NSDictionary *> *localVersionList, *remoteVersionList;

@interface LauncherNavigationController : UINavigationController

@property(nonatomic) UIProgressView *progressViewMain, *progressViewSub;
@property(nonatomic) UILabel* progressText;
@property(nonatomic) UIButton* buttonInstall;

- (void)fetchLocalVersionList;
- (void)setInteractionEnabled:(BOOL)enable;

@end
