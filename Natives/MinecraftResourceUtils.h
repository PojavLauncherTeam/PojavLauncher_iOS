#import <UIKit/UIKit.h>

#define TYPE_INSTALLED 0
#define TYPE_RELEASE 1
#define TYPE_SNAPSHOT 2
#define TYPE_OLDBETA 3
#define TYPE_OLDALPHA 4

typedef void (^MDCallback)(NSString *stage, NSProgress *mainProgress, NSProgress *progress);

@interface MinecraftResourceUtils : NSObject

+ (void)downloadClientJson:(NSObject *)version progress:(NSProgress *)mainProgress callback:(MDCallback)callback success:(void (^)(NSMutableDictionary *json))success;
+ (void)downloadVersion:(NSObject *)version callback:(void (^)(NSString *stage, NSProgress *mainProgress, NSProgress *progress))callback;

+ (void)processJVMArgs:(NSMutableDictionary *)json;

+ (NSObject *)findVersion:(NSString *)version inList:(NSArray *)list;
+ (NSObject *)findNearestVersion:(NSObject *)version expectedType:(int)type;

@end
