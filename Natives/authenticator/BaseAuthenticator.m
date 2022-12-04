#import "BaseAuthenticator.h"
#import "../LauncherPreferences.h"
#import "../ios_uikit_bridge.h"
#import "../utils.h"

@implementation BaseAuthenticator

static BaseAuthenticator *current = nil;

+ (id)current {
    if (current == nil) {
        [self loadSavedName:getPreference(@"selected_account")];
    }
    return current;
}

+ (void)setCurrent:(BaseAuthenticator *)auth {
    current = auth;
}

+ (id)loadSavedName:(NSString *)name {
    NSMutableDictionary *authData = parseJSONFromFile([NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), name]);
    if (authData[@"error"] != nil) {
        NSError *error = ((NSError *)authData[@"error"]);
        if (error.code != NSFileReadNoSuchFileError) {
            showDialog(currentVC(), localize(@"Error", nil), error.localizedDescription);
        }
        return nil;
    }
    if ([authData[@"accessToken"] length] < 5) {
        return [[LocalAuthenticator alloc] initWithData:authData];
    } else { 
        return [[MicrosoftAuthenticator alloc] initWithData:authData];
    }
}

- (id)initWithData:(NSMutableDictionary *)data {
    current = self = [self init];
    self.authData = data;
    return self;
}

- (id)initWithInput:(NSString *)string {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"input"] = string;
    return [self initWithData:data];
}

- (void)loginWithCallback:(Callback)callback {
}

- (void)refreshTokenWithCallback:(Callback)callback {
}

- (BOOL)saveChanges {
    NSError *error;

    [self.authData removeObjectForKey:@"input"];

    NSString *newPath = [NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), self.authData[@"username"]];
    if (self.authData[@"oldusername"] != nil && ![self.authData[@"username"] isEqualToString:self.authData[@"oldusername"]]) {
        NSString *oldPath = [NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), self.authData[@"oldusername"]];
        [NSFileManager.defaultManager moveItemAtPath:oldPath toPath:newPath error:&error];
        // handle error?
    }

    [self.authData removeObjectForKey:@"oldusername"];

    error = saveJSONToFile(self.authData, newPath);

    if (error != nil) {
        showDialog(currentVC(), @"Error while saving file", error.localizedDescription);
    }
    return error == nil;
}

@end
