#import "BaseAuthenticator.h"

@implementation LocalAuthenticator

- (void)loginWithCallback:(Callback)callback {
    self.authData[@"oldusername"] = self.authData[@"username"] = self.authData[@"input"];       
    self.authData[@"accessToken"] = @"0";
    self.authData[@"profileId"] = @"00000000-0000-0000-0000-000000000000";
    setenv("POJAV_GAME_DIR", [NSString stringWithFormat:@"%s/Library/Application Support/minecraft", getenv("POJAV_HOME")].UTF8String, 1);
    callback(nil, [super saveChanges]);
}

- (void)refreshTokenWithCallback:(Callback)callback {
    // Nothing to do
    callback(nil, YES);
}

@end
