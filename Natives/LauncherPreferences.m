#import "LauncherPreferences.h"

NSMutableDictionary *prefDict;
NSString* prefPath;
// environment variables dict
NSMutableDictionary *envPrefDict;
// version type dict
NSMutableDictionary *verPrefDict;
// warnings dict
NSMutableDictionary *warnPrefDict;

#if CONFIG_RELEASE == 1
# define CONFIG_TYPE @NO
#else
# define CONFIG_TYPE @YES
#endif

id getPreference(NSString* key) {
    if (!(envPrefDict[key] == [NSNull null] || envPrefDict[key] == nil)) {
        return envPrefDict[key];
    } else if (!(verPrefDict[key] == [NSNull null] || verPrefDict[key] == nil)) {
        return verPrefDict[key];
    } else if (!(warnPrefDict[key] == [NSNull null] || warnPrefDict[key] == nil)) {
        return warnPrefDict[key];
    } else if (!(prefDict[key] == [NSNull null] || prefDict[key] == nil) || [key hasPrefix:@"internal_"]) {
        return prefDict[key];
    } else {
        NSLog(@"LauncherPreferences: Unknown key %@", key);
    }
    
    NSLog(@"[Pre-init] LauncherPreferences: %@ is NULL", key);
    return nil;
}

NSMutableDictionary *getDictionary(NSString *type) {
    if([type containsString:@"env"]) {
        return envPrefDict;
    } else if([type containsString:@"ver"]) {
        return verPrefDict;
    } else if([type containsString:@"warn"]) {
        return warnPrefDict;
    } else if([type containsString:@"base"]) {
        return prefDict;
    }
    
    return nil;
}

int getJavaVersion(NSString* java) {
    if (java.length == 0) {
        return 0;
    } else if ([java hasPrefix:@"java-"] && [java hasSuffix:@"-openjdk"]) {
        return [java substringWithRange:NSMakeRange(5, java.length - 13)].intValue;
    } else {
        NSLog(@"FIXME: What is the Java version of %@?", java);
        return 0;
    }
}

int getSelectedJavaVersion() {
    return getJavaVersion([getPreference(@"java_home") lastPathComponent]);
}

void setDefaultValueForPref(NSMutableDictionary *dict, NSString* key, id value) {
    if (!dict[key]) {
        dict[key] = value;
        NSLog(@"[Pre-init] Set default value for key %@", value);
    }
}

void setPreference(NSString* key, id value) {
    if (!(envPrefDict[key] == [NSNull null] || envPrefDict[key] == nil)) {
        envPrefDict[key] = value;
        prefDict[@"env_vars"] = envPrefDict;
    } else if (!(verPrefDict[key] == [NSNull null] || verPrefDict[key] == nil)) {
        verPrefDict[key] = value;
        prefDict[@"ver_types"] = verPrefDict;
    } else if (!(warnPrefDict[key] == [NSNull null] || warnPrefDict[key] == nil)) {
        warnPrefDict[key] = value;
        prefDict[@"warnings"] = warnPrefDict;
    } else if (!(prefDict[key] == [NSNull null] || prefDict[key] == nil) || [key hasPrefix:@"internal_"]) {
        prefDict[key] = value;
    } else {
        NSLog(@"LauncherPreferences: Unknown key %@", key);
    }
    [prefDict writeToFile:prefPath atomically:YES];
}

void loadPreferences() {
    assert(getenv("POJAV_HOME"));
    prefPath = [@(getenv("POJAV_HOME"))
      stringByAppendingPathComponent:@"launcher_preferences.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:prefPath]) {
        prefDict = [[NSMutableDictionary alloc] init];
        envPrefDict = [[NSMutableDictionary alloc] init];
        verPrefDict = [[NSMutableDictionary alloc] init];
        warnPrefDict = [[NSMutableDictionary alloc] init];
    } else {
        prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
        envPrefDict = prefDict[@"env_vars"];
        verPrefDict = prefDict[@"ver_types"];
        warnPrefDict = prefDict[@"warnings"];
    }

    assert(prefDict);

    // set default value
    // TODO: organize the plist with nested arrays
    setDefaultValueForPref(envPrefDict, @"resolution", @(100)); // e
    setDefaultValueForPref(prefDict, @"button_scale", @(100)); //
    setDefaultValueForPref(prefDict, @"selected_version", @"1.7.10");
    setDefaultValueForPref(verPrefDict, @"vertype_release", @YES);
    setDefaultValueForPref(verPrefDict, @"vertype_snapshot", @NO);
    setDefaultValueForPref(verPrefDict, @"vertype_oldalpha", @NO);
    setDefaultValueForPref(verPrefDict, @"vertype_oldbeta", @NO);
    setDefaultValueForPref(envPrefDict, @"time_longPressTrigger", @(400));
    setDefaultValueForPref(envPrefDict, @"default_ctrl", @"default.json");
    setDefaultValueForPref(envPrefDict, @"game_directory", @"default");
    setDefaultValueForPref(envPrefDict, @"java_args", @"");
    setDefaultValueForPref(envPrefDict, @"allocated_memory", [NSNumber numberWithFloat:roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.30)]);
    setDefaultValueForPref(prefDict, @"debug_logging", CONFIG_TYPE);
    setDefaultValueForPref(prefDict, @"arccapes_enable", @YES);
    setDefaultValueForPref(envPrefDict, @"java_home", @"");
    setDefaultValueForPref(envPrefDict, @"renderer", @"libgl4es_114.dylib");
    setDefaultValueForPref(warnPrefDict, @"option_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"local_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"mem_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"java_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"demo_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"jb_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"customctrl_warn", @YES);
    setDefaultValueForPref(prefDict, @"a7_allow", @NO);
    setDefaultValueForPref(prefDict, @"slideable_hotbar", @NO);
    setDefaultValueForPref(prefDict, @"virtmouse_enable", @NO);
    setDefaultValueForPref(prefDict, @"check_sha", @YES);
    if (0 != [fileManager fileExistsAtPath:@"/var/mobile/Documents/.pojavlauncher"]) {
        setDefaultValueForPref(prefDict, @"disable_home_symlink", @NO);
    } else {
        setDefaultValueForPref(prefDict, @"disable_home_symlink", @YES);
    }
    
    prefDict[@"env_vars"] = envPrefDict;
    prefDict[@"ver_types"] = verPrefDict;
    prefDict[@"warnings"] = warnPrefDict;
        
    [prefDict writeToFile:prefPath atomically:YES];
}
