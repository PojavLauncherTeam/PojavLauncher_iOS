#import <UIKit/UIKit.h>

@class ModpackAPI;

@interface MinecraftResourceDownloadTask : NSObject
@property NSProgress* progress;
@property NSMutableArray *fileList, *progressList;
@property NSMutableDictionary* metadata;
@property(nonatomic, copy) void(^handleError)(void);

- (NSURLSessionDownloadTask *)createDownloadTask:(NSString *)url sha:(NSString *)sha altName:(NSString *)altName toPath:(NSString *)path;
- (void)addDownloadTaskToProgress:(NSURLSessionDownloadTask *)task;
- (void)finishDownloadWithErrorString:(NSString *)error;

- (void)downloadVersion:(NSDictionary *)version;
- (void)downloadModpackFromAPI:(ModpackAPI *)api detail:(NSDictionary *)modDetail atIndex:(NSUInteger)selectedVersion;

@end
