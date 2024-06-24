#import <UIKit/UIKit.h>

@class ModpackAPI;

@interface MinecraftResourceDownloadTask : NSObject
@property NSProgress *progress, *textProgress;
@property NSMutableArray *fileList, *progressList;
@property NSMutableDictionary* metadata;
@property(nonatomic, copy) void(^handleError)(void);

- (NSURLSessionDownloadTask *)createDownloadTask:(NSString *)url size:(NSUInteger)size sha:(NSString *)sha altName:(NSString *)altName toPath:(NSString *)path;
- (void)finishDownloadWithErrorString:(NSString *)error;

- (void)downloadVersion:(NSDictionary *)version;
- (void)downloadModpackFromAPI:(ModpackAPI *)api detail:(NSDictionary *)modDetail atIndex:(NSUInteger)selectedVersion;

@end
