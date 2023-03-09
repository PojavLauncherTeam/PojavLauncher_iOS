#import <UIKit/UIKit.h>

@interface LauncherMenuCustomItem : NSObject
@property(nonatomic) NSString *title, *imageName;
@property(nonatomic, copy) void (^action)(void);
@end

@interface LauncherMenuViewController : UITableViewController

@property NSString* listPath;
@property(nonatomic) UIButton *accountButton;
@property(nonatomic) UIBarButtonItem *accountBtnItem;
@property(nonatomic) BOOL isInitialVc;

- (void)restoreHighlightedSelection;
- (void)selectAccount:(UIButton *)sender;
- (void)updateAccountInfo;
- (UIBarButtonItem *)drawAccountButton;

@end
