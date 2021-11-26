#import <UIKit/UIKit.h>

@interface FileListViewController : UITableViewController

@property NSString* listPath;
@property(nonatomic, copy) void (^whenItemSelected)(NSString* name);

@end
