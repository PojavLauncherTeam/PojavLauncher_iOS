#import <Foundation/Foundation.h>

@interface BKSSystemService : NSObject

- (unsigned int)createClientPort;
- (void)openApplication:(NSString *)app options:(id)arg2 withResult:(id)arg3 ;
- (void)openURL:(NSURL *)url application:(NSString *)app options:(id)options clientPort:(unsigned int)port withResult:(id)result;

@end
