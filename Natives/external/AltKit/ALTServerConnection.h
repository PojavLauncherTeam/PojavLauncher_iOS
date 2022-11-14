#import <Foundation/Foundation.h>

@interface ALTServerConnection

- (void)disconnect;
- (void)enableUnsignedCodeExecutionWithCompletionHandler:(void(^)(BOOL success, NSError *error))handler;

@end


@interface ALTServerManager

+ (ALTServerManager *)sharedManager;

- (void)autoconnectWithCompletionHandler:(void(^)(ALTServerConnection *connection, NSError *error))handler;
- (void)startDiscovering;
- (void)stopDiscovering;

@end
