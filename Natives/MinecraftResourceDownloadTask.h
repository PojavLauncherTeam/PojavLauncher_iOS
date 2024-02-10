#import <UIKit/UIKit.h>

@interface MinecraftResourceDownloadTask : NSObject
@property NSProgress* progress;
@property NSMutableArray *fileList, *progressList;
@property NSMutableDictionary* verMetadata;
@property(nonatomic, copy) void(^handleError)(void);

- (void)downloadVersion:(NSDictionary *)version;

@end
