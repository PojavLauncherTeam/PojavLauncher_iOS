#import <UIKit/UIKit.h>

@interface LauncherMenuCustomItem : NSObject
@property(nonatomic) NSString *title, *imageName;
@property(nonatomic, copy) void (^action)(void);
@end

@interface LauncherMenuViewController : UITableViewController

@property NSString* listPath;

- (void)restoreHighlightedSelection;

@end
