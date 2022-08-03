#import "AFNetworking.h"
#import "BaseAuthenticator.h"
#import "../ios_uikit_bridge.h"
#import "../utils.h"

typedef void(^XSTSCallback)(NSString *xsts, NSString *uhs);

@implementation MicrosoftAuthenticator

- (void)acquireAccessToken:(NSString *)authcode refresh:(BOOL)refresh callback:(Callback)callback {
    currentVC().title = NSLocalizedString(@"login.msa.progress.acquireAccessToken", nil);

    NSDictionary *data = @{
        @"client_id": @"00000000402b5328",
        (refresh ? @"refresh_token" : @"code"): authcode,
        @"grant_type": refresh ? @"refresh_token" : @"authorization_code",
        @"redirect_url": @"https://login.live.com/oauth20_desktop.srf",
        @"scope": @"service::user.auth.xboxlive.com::MBI_SSL"
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    [manager GET:@"https://login.live.com/oauth20_token.srf" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        self.authData[@"msaRefreshToken"] = response[@"refresh_token"];
        [self acquireXBLToken:response[@"access_token"] callback:callback];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(NO);
        NSLog(@"[MSA] Error: %@", error);
        showDialog(currentVC(), @"Error", error.localizedDescription);
    }];
}

- (void)acquireXBLToken:(NSString *)accessToken callback:(Callback)callback {
    currentVC().title = NSLocalizedString(@"login.msa.progress.acquireXBLToken", nil);

    NSDictionary *data = @{
        @"Properties": @{
            @"AuthMethod": @"RPS",
            @"SiteName": @"user.auth.xboxlive.com",
            @"RpsTicket": accessToken
        },
        @"RelyingParty": @"http://auth.xboxlive.com",
        @"TokenType": @"JWT"
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer = AFJSONRequestSerializer.serializer;
    [manager POST:@"https://user.auth.xboxlive.com/user/authenticate" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        Callback innerCallback = ^(BOOL success) {
            if (success == NO) {
                callback(NO);
                return;
            }
            // Obtain XSTS for authenticating to Minecraft
            [self acquireXSTSFor:@"rp://api.minecraftservices.com/" token:response[@"Token"] callback:^(NSString *xsts, NSString *uhs){
                if (xsts == nil) {
                    callback(NO);
                    return;
                }
                [self acquireMinecraftToken:uhs xstsToken:xsts callback:callback];
            }];
        };

        // Obtain XSTS for getting the Xbox gamertag
        [self acquireXSTSFor:@"http://xboxlive.com" token:response[@"Token"] callback:^(NSString *xsts, NSString *uhs){
            if (xsts == nil) {
                callback(NO);
                return;
            }
            [self acquireXboxProfile:uhs xstsToken:xsts callback:innerCallback];
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(NO);
        NSLog(@"[MSA] Error: %@", error);
        showDialog(currentVC(), @"Error", error.localizedDescription);
    }];
}

- (void)acquireXSTSFor:(NSString *)replyingParty token:(NSString *)xblToken callback:(XSTSCallback)callback {
    currentVC().title = NSLocalizedString(@"login.msa.progress.acquireXSTS", nil);

    NSDictionary *data = @{
       @"Properties": @{
           @"SandboxId": @"RETAIL",
           @"UserTokens": @[
               xblToken
           ]
       },
       @"RelyingParty": replyingParty,
       @"TokenType": @"JWT",
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer = AFJSONRequestSerializer.serializer;
    [manager POST:@"https://xsts.auth.xboxlive.com/xsts/authorize" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        NSString *uhs = response[@"DisplayClaims"][@"xui"][0][@"uhs"];
        callback(response[@"Token"], uhs);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(nil, nil);
        NSString *errorString;
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        switch ((int)([errorDict[@"XErr"] longValue]-2148916230l)) {
            case 3:
                errorString = @"login.msa.error.xsts.noxboxacc";
                break;
            case 5:
                errorString = @"login.msa.error.xsts.noxbox";
                break;
            case 6:
            case 7:
                errorString = @"login.msa.error.xsts.krverify";
                break;
            case 8:
                errorString = @"login.msa.error.xsts.underage";
                break;
            default:
                errorString = [NSString stringWithFormat:@"%@\n\nUnknown XErr code, response:\n%@", error.localizedDescription, errorDict];
                break;
        }
        NSLog(@"[MSA] Error: %@", errorString);
        showDialog(currentVC(), NSLocalizedString(@"Error", nil), NSLocalizedString(errorString, nil));
    }];
}


- (void)acquireXboxProfile:(NSString *)xblUhs xstsToken:(NSString *)xblXsts callback:(Callback)callback {
    currentVC().title = NSLocalizedString(@"login.msa.progress.acquireXboxProfile", nil);

    NSDictionary *headers = @{
        @"x-xbl-contract-version": @"2",
        @"Authorization": [NSString stringWithFormat:@"XBL3.0 x=%@;%@", xblUhs, xblXsts]
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    [manager GET:@"https://profile.xboxlive.com/users/me/profile/settings?settings=PublicGamerpic,Gamertag" parameters:nil headers:headers progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        self.authData[@"profilePicURL"] = [NSString stringWithFormat:@"%@&h=120&w=120", response[@"profileUsers"][0][@"settings"][0][@"value"]];
        self.authData[@"xboxGamertag"] = response[@"profileUsers"][0][@"settings"][1][@"value"];
        callback(YES);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(NO);
        NSLog(@"[MSA] Error: %@", error);
        showDialog(currentVC(), @"Error", error.localizedDescription);
    }];
}

- (void)acquireMinecraftToken:(NSString *)xblUhs xstsToken:(NSString *)xblXsts callback:(Callback)callback {
    currentVC().title = NSLocalizedString(@"login.msa.progress.acquireMCToken", nil);

    NSDictionary *data = @{
        @"identityToken": [NSString stringWithFormat:@"XBL3.0 x=%@;%@", xblUhs, xblXsts]
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer = AFJSONRequestSerializer.serializer;
    [manager POST:@"https://api.minecraftservices.com/authentication/login_with_xbox" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        self.authData[@"accessToken"] = response[@"access_token"];
        [self checkMCProfile:response[@"access_token"] callback:callback];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(NO);
        NSLog(@"[MSA] Error: %@", error);
        showDialog(currentVC(), @"Error", error.localizedDescription);
    }];
}

- (void)checkMCProfile:(NSString *)mcAccessToken callback:(Callback)callback {
    self.authData[@"expiresAt"] = @((long)[NSDate.date timeIntervalSince1970] + 86400);

    currentVC().title = NSLocalizedString(@"login.msa.progress.checkMCProfile", nil);

    NSDictionary *headers = @{
        @"Authorization": [NSString stringWithFormat:@"Bearer %@", mcAccessToken]
    };
    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer = AFJSONRequestSerializer.serializer;
    [manager GET:@"https://api.minecraftservices.com/minecraft/profile" parameters:nil headers:headers progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        NSString *uuid = response[@"id"];
        self.authData[@"profileId"] = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",
            [uuid substringWithRange:NSMakeRange(0, 8)],
            [uuid substringWithRange:NSMakeRange(8, 4)],
            [uuid substringWithRange:NSMakeRange(12, 4)],
            [uuid substringWithRange:NSMakeRange(16, 4)],
            [uuid substringWithRange:NSMakeRange(20, 12)]
        ];
        self.authData[@"profilePicURL"] = [NSString stringWithFormat:@"https://mc-heads.net/head/%@/120", self.authData[@"profileId"]];
        self.authData[@"oldusername"] = self.authData[@"username"];
        self.authData[@"username"] = response[@"name"];
        callback([super saveChanges]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        if ([errorDict[@"error"] isEqualToString:@"NOT_FOUND"]) {
            // If there is no profile, use the Xbox gamertag as username with Demo mode
            self.authData[@"profileId"] = @"00000000-0000-0000-0000-000000000000";
            self.authData[@"username"] = [NSString stringWithFormat:@"Demo.%@", self.authData[@"xboxGamertag"]];

            showDialog(currentVC(), NSLocalizedString(@"Notice", nil), NSLocalizedString(@"login.msa.notice.demomode", nil));
            callback([super saveChanges]);
            return;
        }

        callback(NO);
        NSLog(@"[MSA] Error: %@", errorDict);
        showDialog(currentVC(), @"Error", [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
    }];
}

- (void)loginWithCallback:(Callback)callback {
    [self acquireAccessToken:self.authData[@"input"] refresh:NO callback:callback];
}

- (void)refreshTokenWithCallback:(Callback)callback {
    if ([NSDate.date timeIntervalSince1970] > [self.authData[@"expiresAt"] longValue]) {
        [self acquireAccessToken:self.authData[@"msaRefreshToken"] refresh:YES callback:callback];
    } else {
        callback(YES);
    }
}

@end
