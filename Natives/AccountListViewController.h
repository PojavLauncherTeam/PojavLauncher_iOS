#import <UIKit/UIKit.h>

@interface AccountListViewController: UITableViewController<UIPopoverPresentationControllerDelegate>


@property (nonatomic, copy) void (^whenDelete)(NSString* name);
@property(nonatomic, copy) void (^whenItemSelected)();

@end
