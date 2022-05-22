#import <UIKit/UIKit.h>

@interface AccountListViewController : UITableViewController

@property (nonatomic, copy) void (^whenDelete)(NSString* name);
@property(nonatomic, copy) void (^whenItemSelected)(NSString* name);

@end
