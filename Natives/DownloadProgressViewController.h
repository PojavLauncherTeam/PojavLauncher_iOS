#import <UIKit/UIKit.h>
#import "MinecraftResourceDownloadTask.h"

@interface DownloadProgressViewController : UITableViewController
@property MinecraftResourceDownloadTask* task;

- (instancetype)initWithTask:(MinecraftResourceDownloadTask *)task;

@end
