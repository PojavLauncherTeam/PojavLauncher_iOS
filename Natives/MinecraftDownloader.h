#import <UIKit/UIKit.h>

typedef void (^MDCallback)(NSString *stage, NSProgress *mainProgress, NSProgress *progress);

@interface MinecraftDownloader : NSObject

+ (void)start:(NSObject *)version callback:(void (^)(NSString *stage, NSProgress *mainProgress, NSProgress *progress))callback;

@end
