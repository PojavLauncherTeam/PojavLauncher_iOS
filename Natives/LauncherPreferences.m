#import "LauncherPreferences.h"

NSMutableDictionary *prefDict;
NSString* prefPath;

void loadPreferences() {
    prefPath = [@(getenv("POJAV_HOME"))
      stringByAppendingPathComponent:@"launcher_preferences.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:prefPath]) {
        prefDict = [[NSMutableDictionary alloc] init];
        prefDict[@"button_scale"] = @(100);
        prefDict[@"selected_version"] = @"1.7.10";
        prefDict[@"vertype_release"] = @YES;
        prefDict[@"vertype_snapshot"] = @NO;
        prefDict[@"vertype_oldalpha"] = @NO;
        prefDict[@"vertype_oldbeta"] = @NO;
        prefDict[@"time_longPressTrigger"] = @(400);
        prefDict[@"default_ctrl"] = @"default.json";
        prefDict[@"java_args"] = @"";
        // prefDict[@"custom_envVars"] = @""; // TODO
        [prefDict writeToFile:prefPath atomically:YES];
    } else {
        prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
    }
}

id getPreference(NSString* key) {
    NSObject *object = prefDict[key];
    if (object == [NSNull null] || object == nil) {
        NSLog(@"LauncherPreferences: %@ is NULL", key);
    }
    return object;
}

void setPreference(NSString* key, id value) {
    prefDict[key] = value;
    [prefDict writeToFile:prefPath atomically:YES];
}
