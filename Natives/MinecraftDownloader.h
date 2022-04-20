#import <UIKit/UIKit.h>

typedef void (^MDCallback)(NSString *stage, NSInteger currProgress, NSInteger maxProgress);

@interface MinecraftDownloader : NSObject

+ (void)start:(NSObject *)version callback:(void (^)(NSString *stage, NSProgress *mainProgress, NSProgress *progress))callback;

@end
