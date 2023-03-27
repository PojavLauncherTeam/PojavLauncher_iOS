#include <CommonCrypto/CommonDigest.h>

#import "authenticator/BaseAuthenticator.h"
#import "AFNetworking.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceUtils.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

/*
todo for now - might change anytime
- make the entire download work anyways
- cleanup later, before merging?
- possibility fix incorrect stuff

- Prevent download when account=local
- download Log4J patch (or use existing one?)
- download a vanilla version (tested)
- download a modded ver with inheritsFrom:
 + not downloaded
 + inherit version not found
 + no internet connection (?)
- download a modded ver without inheritsFrom
- SHA check:
 + client json (tested)
 + libraries (tested)
 + client jar (tested)
 + assets
- download assets
 + new structure
 + old structure (mapped)
*/  

@implementation MinecraftResourceUtils

static AFURLSessionManager* manager;

// Check if the account has permission to download
+ (BOOL)checkAccessWithDialog:(BOOL)show {
    // for now
    BOOL accessible = [BaseAuthenticator.current.authData[@"username"] hasPrefix:@"Demo."] || BaseAuthenticator.current.authData[@"xboxGamertag"] != nil;
    if (!accessible && show) {
        showDialog(currentVC(), localize(@"Error", nil), @"Minecraft can't be legally installed when logged in with a local account. Please switch to an online account to continue.");
    }
    return accessible;
}

// Check SHA of the file
+ (BOOL)checkSHAIgnorePref:(NSString *)sha forFile:(NSString *)path altName:(NSString *)altName logSuccess:(BOOL)logSuccess {
    if (sha == nil) {
        // When sha = skip, only check for file existence
        BOOL existence = [NSFileManager.defaultManager fileExistsAtPath:path];
        if (existence) {
            NSLog(@"[MCDL] Warning: couldn't find SHA for %@, have to assume it's good.", path);
        }
        return existence;
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data == nil) {
        NSLog(@"[MCDL] SHA1 checker: file doesn't exist: %@", path.lastPathComponent);
        return NO;
    }

    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *localSHA = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [localSHA appendFormat:@"%02x", digest[i]];
    }

    BOOL check = [sha isEqualToString:localSHA];
    if (!check || ([getPreference(@"debug_logging") boolValue] && logSuccess)) {
        NSLog(@"[MCDL] SHA1 %@ for %@%@",
          (check ? @"passed" : @"failed"), 
          (altName ? altName : path.lastPathComponent),
          (check ? @"" : [NSString stringWithFormat:@" (expected: %@, got: %@)", sha, localSHA]));
    }
    return check;
}

+ (BOOL)checkSHA:(NSString *)sha forFile:(NSString *)path altName:(NSString *)altName logSuccess:(BOOL)logSuccess {
    if ([getPreference(@"check_sha") boolValue]) {
        return [self checkSHAIgnorePref:sha forFile:path altName:altName logSuccess:logSuccess];
    } else {
        return [NSFileManager.defaultManager fileExistsAtPath:path];
    }
}

+ (BOOL)checkSHA:(NSString *)sha forFile:(NSString *)path altName:(NSString *)altName {
    return [self checkSHA:sha forFile:path altName:altName logSuccess:YES];
}

// Handle inheritsFrom
+ (void)processVersion:(NSMutableDictionary *)json inheritsFrom:(NSMutableDictionary *)inheritsFrom {
    [self insertSafety:inheritsFrom from:json arr:@[
        @"assetIndex", @"assets", @"id",
        @"inheritsFrom",
        @"mainClass", @"minecraftArguments",
        @"optifineLib", @"releaseTime", @"time", @"type"
    ]];
    inheritsFrom[@"arguments"] = json[@"arguments"];

    for (NSMutableDictionary *lib in json[@"libraries"]) {
        NSString *libName = [lib[@"name"] substringToIndex:[lib[@"name"] rangeOfString:@":" options:NSBackwardsSearch].location];
        int i;
        for (i = 0; i < [inheritsFrom[@"libraries"] count]; i++) {
            NSMutableDictionary *libAdded = inheritsFrom[@"libraries"][i];
            NSString *libAddedName = [libAdded[@"name"] substringToIndex:[libAdded[@"name"] rangeOfString:@":" options:NSBackwardsSearch].location];

            if ([libAdded[@"name"] hasPrefix:libName]) {
                inheritsFrom[@"libraries"][i] = lib;
                i = -1;
                break;
            }
        }

        if (i != -1) {
            [inheritsFrom[@"libraries"] addObject:lib];
        }
    }

    //inheritsFrom[@"inheritsFrom"] = nil;
}

+ (void)processVersion:(NSMutableDictionary *)json inheritsFrom:(id)object progress:(NSProgress *)mainProgress callback:(MDCallback)callback success:(void (^)(NSMutableDictionary *json))success {
    [self downloadClientJson:object progress:mainProgress callback:callback success:^(NSMutableDictionary *inheritsFrom){
        [self processVersion:json inheritsFrom:inheritsFrom];
        [self downloadClientJson:inheritsFrom[@"assetIndex"] progress:mainProgress callback:callback success:^(NSMutableDictionary *assetJson){
            inheritsFrom[@"assetIndexObj"] = assetJson;
            success(inheritsFrom);
        }];
    }];
}

// Download the client and assets index file
+ (void)downloadClientJson:(NSObject *)version progress:(NSProgress *)mainProgress callback:(MDCallback)callback success:(void (^)(NSMutableDictionary *json))success {
    ++mainProgress.totalUnitCount;

    BOOL isAssetIndex = NO;
    NSString *versionStr, *versionURL, *versionSHA;
    if ([version isKindOfClass:[NSDictionary class]]) {
        isAssetIndex = [version valueForKey:@"totalSize"] != nil;
        versionStr = [version valueForKey:@"id"];
        versionURL = [version valueForKey:@"url"];
        versionSHA = versionURL.stringByDeletingLastPathComponent.lastPathComponent;
    } else {
        versionStr = (NSString *)version;
        versionSHA = nil;
    }

    if (mainProgress) {
        callback([NSString stringWithFormat:localize(@"launcher.mcl.downloading_file", nil), versionStr], mainProgress, nil);
    }

    NSString *jsonPath;
    if (isAssetIndex) {
        versionStr = [NSString stringWithFormat:@"assets/indexes/%@", versionStr];
        jsonPath = [NSString stringWithFormat:@"%s/%@.json", getenv("POJAV_GAME_DIR"), versionStr];
    } else {
        jsonPath = [NSString stringWithFormat:@"%1$s/versions/%2$@/%2$@.json", getenv("POJAV_GAME_DIR"), versionStr];
    }

    if (![self checkSHA:versionSHA forFile:jsonPath altName:nil]) {
        if (![self checkAccessWithDialog:YES]) {
            callback(nil, nil, nil);
            return;
        }

        NSString *verPath = jsonPath.stringByDeletingLastPathComponent;
        NSError *error;
        [NSFileManager.defaultManager createDirectoryAtPath:verPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            NSString *errorStr = [NSString stringWithFormat:@"Failed to create directory %@: %@", verPath, error.localizedDescription];
            NSLog(@"[MCDL] Error: %@", errorStr);
            showDialog(currentVC(), localize(@"Error", nil), errorStr);
            callback(nil, nil, nil);
            return;
        }

        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:versionURL]];

        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull progress){
            callback([NSString stringWithFormat:localize(@"launcher.mcl.downloading_file", nil), jsonPath.lastPathComponent], mainProgress, progress);
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            [NSFileManager.defaultManager removeItemAtPath:jsonPath error:nil];
            return [NSURL fileURLWithPath:jsonPath];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error != nil) { // FIXME: correct?
                NSString *errorStr = [NSString stringWithFormat:localize(@"launcher.mcl.error_download", NULL), versionURL, error.localizedDescription];
                NSLog(@"[MCDL] Error: %@ %@", errorStr, NSThread.callStackSymbols);
                showDialog(currentVC(), localize(@"Error", nil), errorStr);
                callback(nil, nil, nil);
                return;
            } else {
                // A version from the offical server won't likely to have inheritsFrom, so return immediately
                if (![self checkSHA:versionSHA forFile:jsonPath altName:nil]) {
                    // Abort when a downloaded file's SHA mismatches
                    showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Failed to verify file %@: SHA1 mismatch", versionStr]);
                    callback(nil, nil, nil);
                    return;
                }
                ++mainProgress.completedUnitCount;

                NSMutableDictionary *json = parseJSONFromFile(jsonPath);
                if (isAssetIndex) {
                    success(json);
                    return;
                }

                [self downloadClientJson:json[@"assetIndex"] progress:mainProgress callback:callback success:^(NSMutableDictionary *assetJson){
                    json[@"assetIndexObj"] = assetJson;
                    success(json);
                }];
            }
        }];
        [downloadTask resume];
    } else {
        NSMutableDictionary *json = parseJSONFromFile(jsonPath);
        if (json == nil) {
            callback(nil, nil, nil);
            return;
        }
        if (isAssetIndex) {
            success(json);
            return;
        }
        if (json[@"inheritsFrom"] == nil) {
            if (json[@"assetIndex"] == nil) {
                success(json);
                return;
            }
            ++mainProgress.completedUnitCount;
            [self downloadClientJson:json[@"assetIndex"] progress:mainProgress callback:callback success:^(NSMutableDictionary *assetJson){
                json[@"assetIndexObj"] = assetJson;
                success(json);
            }];
            return;
        }

        // Find the inheritsFrom
        id inheritsFrom = [self findVersion:json[@"inheritsFrom"] inList:remoteVersionList];
        if (inheritsFrom != nil) {
            [self processVersion:json inheritsFrom:inheritsFrom progress:mainProgress callback:callback success:success];
            return;
        }

        // Try using local json
        NSMutableDictionary *inheritsFromDict = parseJSONFromFile([NSString stringWithFormat:@"%1$s/versions/%2$@/%2$@.json", getenv("POJAV_GAME_DIR"), json[@"inheritsFrom"]]);
        if (inheritsFromDict != nil) {
            [self processVersion:json inheritsFrom:inheritsFromDict];
            success(inheritsFromDict);
            return;
        }

        // If the inheritsFrom is not found, return an error
        showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Could not find inheritsFrom=%@ for version %@", json[@"inheritsFrom"], versionStr]);
    }
}

+ (void)insertSafety:(NSMutableDictionary *)targetVer from:(NSDictionary *)fromVer arr:(NSArray *)arr {
    for (NSString *key in arr) {
        if (([fromVer[key] isKindOfClass:NSString.class] && [fromVer[key] length] > 0) || targetVer[key] == nil) {
            targetVer[key] = fromVer[key];
        } else {
            NSLog(@"[MCDL] insertSafety: how to insert %@?", key);
        }
    }
}

+ (void)tweakVersionJson:(NSMutableDictionary *)json {
    // Exclude some libraries
    for (NSMutableDictionary *library in json[@"libraries"]) {
        library[@"skip"] = @(
            // Exclude platform-dependant libraries
            library[@"downloads"][@"classifiers"] != nil ||
            library[@"natives"] != nil ||
            // Exclude LWJGL libraries
            [library[@"name"] hasPrefix:@"org.lwjgl"]
        );

        if ([library[@"name"] hasPrefix:@"net.java.dev.jna:jna:"]) {
            // Special handling for LabyMod 1.8.9 and Forge 1.12.2(?)
            // we have libjnidispatch 5.8.0 in Frameworks directory
            NSString *versionStr = [library[@"name"] componentsSeparatedByString:@":"][2];
            NSArray<NSString *> *version = [versionStr componentsSeparatedByString:@"."];
            if (!(version[0].intValue < 5 || version[1].intValue < 13 || version[2].intValue < 1)) {
                NSLog(@"[MCDL] Warning: JNA version required by %@ is %@ > 5.13.0, compatibility might be broken.", json[@"id"], versionStr);
            }
            library[@"name"] = @"net.java.dev.jna:jna:5.13.0";
            library[@"downloads"][@"artifact"][@"path"] = @"net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar";
            library[@"downloads"][@"artifact"][@"url"] = @"https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar";
            library[@"downloads"][@"artifact"][@"sha1"] = @"1200e7ebeedbe0d10062093f32925a912020e747";
        }
    }

    // Add the client as a library
    NSMutableDictionary *client = [[NSMutableDictionary alloc] init];
    client[@"downloads"] = [[NSMutableDictionary alloc] init];
    if (json[@"downloads"][@"client"] == nil) {
        client[@"downloads"][@"artifact"] = [[NSMutableDictionary alloc] init];
        client[@"skip"] = @YES;
    } else {
        client[@"downloads"][@"artifact"] = json[@"downloads"][@"client"];
    }
    client[@"downloads"][@"artifact"][@"path"] = [NSString stringWithFormat:@"../versions/%1$@/%1$@.jar", json[@"id"]];
    client[@"name"] = [NSString stringWithFormat:@"%@.jar", json[@"id"]];
    [json[@"libraries"] addObject:client];
}

+ (BOOL)downloadClientLibraries:(NSArray *)libraries progress:(NSProgress *)mainProgress callback:(void (^)(NSString *stage, NSProgress *progress))callback {
    callback(@"Begin: download libraries", nil);

    __block BOOL cancel = NO;

    dispatch_group_t group = dispatch_group_create();

    for (NSDictionary *library in libraries) {
        if (cancel) {
            NSLog(@"[MCDL] Task download libraries is cancelled");
            return NO;
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        NSString *name = library[@"name"];

        NSMutableDictionary *artifact = library[@"downloads"][@"artifact"];
        if (artifact == nil && [name containsString:@":"]) {
            NSLog(@"[MCDL] Unknown artifact object for %@, attempting to generate one", name);
            artifact = [[NSMutableDictionary alloc] init];
            NSString *prefix = library[@"url"] == nil ? @"https://libraries.minecraft.net/" : [library[@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
            NSArray *libParts = [name componentsSeparatedByString:@":"];
            artifact[@"path"] = [NSString stringWithFormat:@"%1$@/%2$@/%3$@/%2$@-%3$@.jar", [libParts[0] stringByReplacingOccurrencesOfString:@"." withString:@"/"], libParts[1], libParts[2]];
            artifact[@"url"] = [NSString stringWithFormat:@"%@%@", prefix, artifact[@"path"]];
            artifact[@"sha1"] = library[@"checksums"][0];
        }

        NSString *path = [NSString stringWithFormat:@"%s/libraries/%@", getenv("POJAV_GAME_DIR"), artifact[@"path"]];
        NSString *sha1 = artifact[@"sha1"];
        NSString *url = artifact[@"url"];
        if ([library[@"skip"] boolValue]) {
            callback([NSString stringWithFormat:@"Skipped library %@", name], nil);
            ++mainProgress.completedUnitCount;
            continue;
        } else if ([self checkSHA:sha1 forFile:path altName:nil]) { 
            ++mainProgress.completedUnitCount;
            continue;
        }

        if (![self checkAccessWithDialog:YES]) {
            callback(nil, nil);
            cancel = YES;
            continue;
        }

        dispatch_group_enter(group);
        [NSFileManager.defaultManager createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull progress){
            callback([NSString stringWithFormat:localize(@"launcher.mcl.downloading_file", nil), name], progress);
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
            return [NSURL fileURLWithPath:path];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error != nil) {
                cancel = YES;
                NSString *errorStr = [NSString stringWithFormat:localize(@"launcher.mcl.error_download", NULL), url, error.localizedDescription];
                NSLog(@"[MCDL] Error: %@ %@", errorStr, NSThread.callStackSymbols);
                showDialog(currentVC(), localize(@"Error", nil), errorStr);
                callback(nil, nil);
            } else if (![self checkSHA:sha1 forFile:path altName:nil]) {
                // Abort when a downloaded file's SHA mismatches
                cancel = YES;
                showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Failed to verify file %@: SHA1 mismatch", path.lastPathComponent]);
                callback(nil, nil);
            }
            dispatch_group_leave(group);
            ++mainProgress.completedUnitCount;
        }];
        [downloadTask resume];
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    callback(@"Finished: download libraries", nil);
    return !cancel;
}

+ (BOOL)downloadClientAssets:(NSDictionary *)assets progress:(NSProgress *)mainProgress callback:(void (^)(NSString *stage, NSProgress *progress))callback {
    callback(@"Begin: download assets", nil);

    dispatch_group_t group = dispatch_group_create();
    __block int verifiedCount = 0;
    __block int jobsAvailable = 10;
    for (NSString *name in assets[@"objects"]) {
        if (jobsAvailable < 0) {
            break;
        } else if (jobsAvailable == 0) {
            //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            while (jobsAvailable == 0) {
                usleep(1000);
            }
        }

        NSString *hash = assets[@"objects"][name][@"hash"];
        NSString *pathname = [NSString stringWithFormat:@"%@/%@", [hash substringToIndex:2], hash];

        /* Special case for 1.19+
         * Since 1.19-pre1, setting the window icon on macOS goes through ObjC.
         * However, if an IOException occurs, it won't try to set.
         * We skip downloading the icon file to trigger this. */
        if ([name hasSuffix:@"icons/minecraft.icns"]) {
            [NSFileManager.defaultManager removeItemAtPath:pathname error:nil];
            continue;
        }

        --jobsAvailable;
        dispatch_group_enter(group);
        NSString *path;
        if ([assets[@"map_to_resources"] boolValue]) {
            path = [NSString stringWithFormat:@"%s/resources/%@", getenv("POJAV_GAME_DIR"), name];
        } else {
            path = [NSString stringWithFormat:@"%s/assets/objects/%@", getenv("POJAV_GAME_DIR"), pathname];
        }
        if ([self checkSHA:hash forFile:path altName:name logSuccess:NO]) { 
            if (++verifiedCount % (mainProgress.totalUnitCount/10) == 0) {
                mainProgress.completedUnitCount = verifiedCount;
            }
            ++jobsAvailable;
            dispatch_group_leave(group);
            continue;
        }

        if (![self checkAccessWithDialog:NO]) {
            dispatch_group_leave(group);
            break;
        }

        NSError *err;
        [NSFileManager.defaultManager createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:&err];
        //NSLog(@"path %@ err %@", path, err);
        usleep(1000); // avoid overloading queue
        NSString *url = [NSString stringWithFormat:@"https://resources.download.minecraft.net/%@", pathname];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull progress){
            callback([NSString stringWithFormat:localize(@"launcher.mcl.downloading_file", nil), name], progress);
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
            return [NSURL fileURLWithPath:path];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error != nil) {
                if (jobsAvailable < 0) {
                    dispatch_group_leave(group);
                    return;
                }
                jobsAvailable = -3;
                NSString *errorStr = [NSString stringWithFormat:localize(@"launcher.mcl.error_download", NULL), url, error.localizedDescription];
                NSLog(@"[MCDL] Error: %@ %@", errorStr, NSThread.callStackSymbols);
                showDialog(currentVC(), localize(@"Error", nil), errorStr);
                callback(nil, nil);
            } else if (![self checkSHA:hash forFile:path altName:name logSuccess:NO]) {
                // Abort when a downloaded file's SHA mismatches
                if (jobsAvailable < 0) {
                    dispatch_group_leave(group);
                    return;
                }
                jobsAvailable = -2;
                showDialog(currentVC(), localize(@"Error", nil), [NSString stringWithFormat:@"Failed to verify file %@: SHA1 mismatch", path.lastPathComponent]);
                callback(nil, nil);
            }
            ++verifiedCount;
            ++jobsAvailable;
            mainProgress.completedUnitCount = verifiedCount;
            dispatch_group_leave(group);
        }];
        [downloadTask resume];
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    callback(@"Finished: download assets", nil);
    if ([getPreference(@"check_sha") boolValue]) {
        NSLog(@"[MCDL] SHA1 passed for %d/%d asset files", verifiedCount, [assets[@"objects"] count]);
        if ([assets[@"objects"] count] - verifiedCount < 3) {
            NSLog(@"Note: some files of 1.19+ are skipped to workaround an issue");
        }
    }
    return jobsAvailable != -1;
}

+ (void)downloadVersion:(NSObject *)version callback:(MDCallback)callback {
    manager = [[AFURLSessionManager alloc] init];
    NSProgress *mainProgress = [NSProgress progressWithTotalUnitCount:0];
    [self downloadClientJson:version progress:mainProgress callback:callback success:^(NSMutableDictionary *json) {
        [self tweakVersionJson:json];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL success;

            mainProgress.totalUnitCount = [json[@"libraries"] count] + [json[@"assetIndexObj"][@"objects"] count];
            id wrappedCallback = ^(NSString *s, NSProgress *p) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(s, s?mainProgress:nil, p);
                });
            };

            success = [self downloadClientLibraries:json[@"libraries"] progress:mainProgress callback:wrappedCallback];
            if (!success) return;

            success = [self downloadClientAssets:json[@"assetIndexObj"] progress:mainProgress callback:wrappedCallback];
            if (!success) return;

            isUseStackQueueCall = json[@"arguments"] != nil;

            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil, mainProgress, nil);
            });
        });
    }];
}

+ (void)processJVMArgs:(NSMutableDictionary *)json {
    // Parse Forge 1.17+ additional JVM Arguments
    if (json[@"inheritsFrom"] == nil || json[@"arguments"][@"jvm"] == nil) {
        return;
    }

    json[@"arguments"][@"jvm_processed"] = [[NSMutableArray alloc] init];

    NSDictionary *varArgMap = @{
        @"${classpath_separator}": @":",
        @"${library_directory}": [NSString stringWithFormat:@"%s/libraries", getenv("POJAV_GAME_DIR")],
        @"${version_name}": json[@"id"]
    };

    for (id arg in json[@"arguments"][@"jvm"]) {
        if ([arg isKindOfClass:NSString.class]) {
            NSString *argStr = arg;
            for (NSString *key in varArgMap.allKeys) {
                argStr = [argStr stringByReplacingOccurrencesOfString:key withString:varArgMap[key]];
            }
            [json[@"arguments"][@"jvm_processed"] addObject:argStr];
        }
    }
}

+ (NSObject *)findVersion:(NSString *)version inList:(NSArray *)list {
    for (id object in list) {
        NSString *item;
        if ([object isKindOfClass:[NSDictionary class]]) {
            item = [object valueForKey:@"id"];
        } else {
            item = (NSString *)object;
        }
        if ([version isEqualToString:item]) {
            return object;
        }
    }
    return nil;
}

+ (NSObject *)findNearestVersion:(NSObject *)version expectedType:(int)type {
    if (type != TYPE_RELEASE && type != TYPE_SNAPSHOT) {
        // Only support finding for releases and snapshot for now
        return nil;
    }

    if ([version isKindOfClass:NSString.class]){
        // Find in inheritsFrom
        NSDictionary *versionDict = parseJSONFromFile([NSString stringWithFormat:@"%1$s/versions/%2$@/%2$@.json", getenv("POJAV_GAME_DIR"), version]);
        NSAssert(versionDict != nil, @"version should not be null");
        if (versionDict[@"inheritsFrom"] == nil) {
            // How then?
            return nil; 
        }
        NSObject *inheritsFrom = [self findVersion:versionDict[@"inheritsFrom"] inList:remoteVersionList];
        if (type == TYPE_RELEASE) {
            return inheritsFrom;
        } else if (type == TYPE_SNAPSHOT) {
            return [self findNearestVersion:inheritsFrom expectedType:type];
        }
    }

    NSString *versionType = [version valueForKey:@"type"];
    int index = [remoteVersionList indexOfObject:(NSDictionary *)version];
    if ([versionType isEqualToString:@"release"] && type == TYPE_SNAPSHOT) {
        // Returns the (possible) latest snapshot for the version
        NSDictionary *result = remoteVersionList[index + 1];
        // Sometimes, a release is followed with another release (1.16->1.16.1), go lower in this case
        if ([result[@"type"] isEqualToString:@"release"]) {
            return [self findNearestVersion:result expectedType:type];
        }
        return result;
    } else if ([versionType isEqualToString:@"snapshot"] && type == TYPE_RELEASE) {
        while (remoteVersionList.count > abs(index)) {
            // In case the snapshot has yet attached to a release, perform a reverse find
            NSDictionary *result = remoteVersionList[abs(index)];
            // Returns the corresponding release for the snapshot, or latest release if none found
            if ([result[@"type"] isEqualToString:@"release"]) {
                return result;
            }
            // Continue to decrement, later abs() it
            index--;
        }
    }

    // No idea on handling everything else
    return nil;
}

@end
