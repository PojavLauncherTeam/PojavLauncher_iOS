#import "AFNetworking.h"
#import "BaseAuthenticator.h"
#import "../ios_uikit_bridge.h"
#import "../utils.h"
#include "jni.h"

typedef void(^XSTSCallback)(NSString *xsts, NSString *uhs);

@implementation MicrosoftAuthenticator

- (void)acquireAccessToken:(NSString *)authcode refresh:(BOOL)refresh callback:(Callback)callback {
    callback(localize(@"login.msa.progress.acquireAccessToken", nil), YES);

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
        if (error.code == NSURLErrorDataNotAllowed) {
            // The account token is expired and offline
            self.authData[@"accessToken"] = @"offline";
            callback(nil, YES);
        } else {
            callback(error, NO);
        }
    }];
}

- (void)acquireXBLToken:(NSString *)accessToken callback:(Callback)callback {
    callback(localize(@"login.msa.progress.acquireXBLToken", nil), YES);

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
        Callback innerCallback = ^(NSString* status, BOOL success) {
            if (!success) {
                callback(status, NO);
                return;
            } else if (status) {
                return;
            }
            // Obtain XSTS for authenticating to Minecraft
            [self acquireXSTSFor:@"rp://api.minecraftservices.com/" token:response[@"Token"] xstsCallback:^(NSString *xsts, NSString *uhs){
                if (xsts == nil) {
                    callback(nil, NO);
                    return;
                }
                self.authData[@"xuid"] = uhs;
                [self acquireMinecraftToken:uhs xstsToken:xsts callback:callback];
            } callback:callback];
        };

        // Obtain XSTS for getting the Xbox gamertag
        [self acquireXSTSFor:@"http://xboxlive.com" token:response[@"Token"] xstsCallback:^(NSString *xsts, NSString *uhs){
            if (xsts == nil) {
                callback(nil, NO);
                return;
            }
            [self acquireXboxProfile:uhs xstsToken:xsts callback:innerCallback];
        } callback:callback];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(error, NO);
    }];
}

- (void)acquireXSTSFor:(NSString *)replyingParty token:(NSString *)xblToken xstsCallback:(XSTSCallback)xstsCallback callback:(Callback)callback {
    callback(localize(@"login.msa.progress.acquireXSTS", nil), YES);

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
        xstsCallback(response[@"Token"], uhs);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSString *errorString;
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (errorData == nil) {
            callback(error, NO);
            return;
        }
        NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:kNilOptions error:nil];
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
        callback(localize(errorString, nil), NO);
    }];
}


- (void)acquireXboxProfile:(NSString *)xblUhs xstsToken:(NSString *)xblXsts callback:(Callback)callback {
    callback(localize(@"login.msa.progress.acquireXboxProfile", nil), YES);

    NSDictionary *headers = @{
        @"x-xbl-contract-version": @"2",
        @"Authorization": [NSString stringWithFormat:@"XBL3.0 x=%@;%@", xblUhs, xblXsts]
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    [manager GET:@"https://profile.xboxlive.com/users/me/profile/settings?settings=PublicGamerpic,Gamertag" parameters:nil headers:headers progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        self.authData[@"profilePicURL"] = [NSString stringWithFormat:@"%@&h=120&w=120", response[@"profileUsers"][0][@"settings"][0][@"value"]];
        self.authData[@"xboxGamertag"] = response[@"profileUsers"][0][@"settings"][1][@"value"];
        callback(nil, YES);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(error, NO);
    }];
}

- (void)acquireMinecraftToken:(NSString *)xblUhs xstsToken:(NSString *)xblXsts callback:(Callback)callback {
    callback(localize(@"login.msa.progress.acquireMCToken", nil), YES);

    NSDictionary *data = @{
        @"identityToken": [NSString stringWithFormat:@"XBL3.0 x=%@;%@", xblUhs, xblXsts]
    };

    AFHTTPSessionManager *manager = AFHTTPSessionManager.manager;
    manager.requestSerializer = AFJSONRequestSerializer.serializer;
    [manager POST:@"https://api.minecraftservices.com/authentication/login_with_xbox" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask *task, NSDictionary *response) {
        self.authData[@"accessToken"] = response[@"access_token"];
        [self checkMCProfile:response[@"access_token"] callback:callback];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        callback(error, NO);
    }];
}

- (void)checkMCProfile:(NSString *)mcAccessToken callback:(Callback)callback {
    self.authData[@"expiresAt"] = @((long)[NSDate.date timeIntervalSince1970] + 86400);

    callback(localize(@"login.msa.progress.checkMCProfile", nil), YES);

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
        callback(nil, [self saveChanges]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        if ([errorDict[@"error"] isEqualToString:@"NOT_FOUND"]) {
            // If there is no profile, use the Xbox gamertag as username with Demo mode
            self.authData[@"profileId"] = @"00000000-0000-0000-0000-000000000000";
            self.authData[@"username"] = [NSString stringWithFormat:@"Demo.%@", self.authData[@"xboxGamertag"]];

            if ([self saveChanges]) {
                callback(@"DEMO", YES);
                callback(nil, YES);
            } else {
                callback(nil, NO);
            }
            return;
        }

        callback(error, NO);
    }];
}

- (void)loginWithCallback:(Callback)callback {
    [self acquireAccessToken:self.authData[@"input"] refresh:NO callback:callback];
}

- (void)refreshTokenWithCallback:(Callback)callback {
    // Move tokens to keychain if we haven't
    if (!self.tokenData) {
        [self saveChanges];
    }

    if ([NSDate.date timeIntervalSince1970] > [self.authData[@"expiresAt"] longValue]) {
        [self acquireAccessToken:self.tokenData[@"refreshToken"] refresh:YES callback:callback];
    } else {
        callback(nil, YES);
    }
}

- (BOOL)saveChanges {
    BOOL savedToKeychain = [self setAccessToken:self.authData[@"accessToken"] refreshToken:self.authData[@"msaRefreshToken"]];
    if (!savedToKeychain) {
        showDialog(localize(@"Error", nil), @"Failed to save account tokens to keychain");
        return NO;
    }
    [self.authData removeObjectsForKeys:@[@"accessToken", @"msaRefreshToken"]];
    return [super saveChanges];
}

#pragma mark Keychain

+ (NSDictionary *)keychainQueryForKey:(NSString *)profile extraInfo:(NSDictionary *)extra {
    NSMutableDictionary *dict = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"AccountToken",
        (id)kSecAttrAccount: profile,
        (id)kSecAttrAccessible: (id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }.mutableCopy;
    if (extra) {
        [dict addEntriesFromDictionary:extra];
    }
    return dict;
}

+ (NSDictionary *)tokenDataOfProfile:(NSString *)profile {
    NSDictionary *dict = [MicrosoftAuthenticator keychainQueryForKey:profile extraInfo:@{
        (id)kSecMatchLimit: (id)kSecMatchLimitOne,
        (id)kSecReturnData: (id)kCFBooleanTrue
    }];
    CFTypeRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &result);
    if (status == errSecSuccess) {
        return [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class fromData:(__bridge NSData *)result error:nil];
    } else {
        return nil;
    }
}

+ (void)clearTokenDataOfProfile:(NSString *)profile {
    NSDictionary *dict = [MicrosoftAuthenticator keychainQueryForKey:profile extraInfo:nil];
    SecItemDelete((__bridge CFDictionaryRef)dict);
}

- (BOOL)setAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{
        @"accessToken": accessToken,
        @"refreshToken": refreshToken,
    } requiringSecureCoding:YES error:nil];
    NSDictionary *dict = [MicrosoftAuthenticator keychainQueryForKey:self.authData[@"xuid"] extraInfo:@{
        (id)kSecValueData: data
    }];
    SecItemDelete((__bridge CFDictionaryRef)dict);
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    return status == errSecSuccess;
}

- (NSDictionary *)tokenData {
    return [MicrosoftAuthenticator tokenDataOfProfile:self.authData[@"xuid"]];
}

@end
