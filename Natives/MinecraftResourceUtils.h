#import <UIKit/UIKit.h>

typedef void (^MDCallback)(NSString *stage, NSProgress *mainProgress, NSProgress *progress);

@interface MinecraftResourceUtils : NSObject

+ (void)downloadClientJson:(NSObject *)version progress:(NSProgress *)mainProgress callback:(MDCallback)callback success:(void (^)(NSMutableDictionary *json))success;
+ (void)downloadVersion:(NSObject *)version callback:(void (^)(NSString *stage, NSProgress *mainProgress, NSProgress *progress))callback;

+ (void)processJVMArgs:(NSMutableDictionary *)json;

@end
