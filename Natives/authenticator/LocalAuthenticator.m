#import "BaseAuthenticator.h"

@implementation LocalAuthenticator

- (void)loginWithCallback:(Callback)callback {
    self.authData[@"oldusername"] = self.authData[@"username"] = self.authData[@"input"];
    self.authData[@"profileId"] = @"00000000-0000-0000-0000-000000000000";
    callback(nil, [super saveChanges]);
}

- (void)refreshTokenWithCallback:(Callback)callback {
    // Nothing to do
    callback(nil, YES);
}

@end
