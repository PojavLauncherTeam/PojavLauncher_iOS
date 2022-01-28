#import "LauncherPreferences.h"

NSMutableDictionary *prefDict;
NSString* prefPath;

#if CONFIG_RELEASE == 1
# define CONFIG_TYPE @NO
#else
# define CONFIG_TYPE @YES
#endif

id getPreference(NSString* key) {
    NSObject *object = prefDict[key];
    if (object == [NSNull null] || object == nil) {
        NSLog(@"LauncherPreferences: %@ is NULL", key);
    }
    return object;
}

void setDefaultValueForPref(NSString* key, id value) {
    if (!prefDict[key]) {
        prefDict[key] = value;
        NSLog(@"[Pre-init] Set default value for key %@", value);
    }
}

void setPreference(NSString* key, id value) {
    prefDict[key] = value;
    [prefDict writeToFile:prefPath atomically:YES];
}

void loadPreferences() {
    assert(getenv("POJAV_HOME"));
    prefPath = [@(getenv("POJAV_HOME"))
      stringByAppendingPathComponent:@"launcher_preferences.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:prefPath]) {
        prefDict = [[NSMutableDictionary alloc] init];
    } else {
        prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
    }

    assert(prefDict);

    // set default value
    setDefaultValueForPref(@"resolution", @(100));
    setDefaultValueForPref(@"button_scale", @(100));
    setDefaultValueForPref(@"selected_version", @"1.7.10");
    setDefaultValueForPref(@"vertype_release", @YES);
    setDefaultValueForPref(@"vertype_snapshot", @NO);
    setDefaultValueForPref(@"vertype_oldalpha", @NO);
    setDefaultValueForPref(@"vertype_oldbeta", @NO);
    setDefaultValueForPref(@"time_longPressTrigger", @(400));
    setDefaultValueForPref(@"default_ctrl", @"default.json");
    setDefaultValueForPref(@"game_directory", @"default");
    setDefaultValueForPref(@"java_args", @"");
    setDefaultValueForPref(@"allocated_memory", [NSNumber numberWithFloat:roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.30)]);
    setDefaultValueForPref(@"debug_logging", CONFIG_TYPE);
    setDefaultValueForPref(@"java_home", @"");
    setDefaultValueForPref(@"renderer", @"libgl4es_114.dylib");
    setDefaultValueForPref(@"option_warn", @YES);
    setDefaultValueForPref(@"local_warn", @YES);
    setDefaultValueForPref(@"mem_warn", @YES);
    setDefaultValueForPref(@"java_warn", @YES);
    setDefaultValueForPref(@"demo_warn", @YES);
    setDefaultValueForPref(@"jb_warn", @YES);
    setDefaultValueForPref(@"customctrl_warn", @YES);
    setDefaultValueForPref(@"disable_gl4es_shaderconv", @NO);
    setDefaultValueForPref(@"slideable_hotbar", @NO);
    if (0 != [fileManager fileExistsAtPath:@"/var/mobile/Documents/.pojavlauncher"]) {
        setDefaultValueForPref(@"disable_home_symlink", @NO);
    } else {
        setDefaultValueForPref(@"disable_home_symlink", @YES);
    }
    [prefDict writeToFile:prefPath atomically:YES];
}
