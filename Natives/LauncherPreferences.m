#import "LauncherPreferences.h"
#import <CoreFoundation/CoreFoundation.h>

NSMutableDictionary *prefDict;
NSString* prefPath;
// environment variables dict
NSMutableDictionary *envPrefDict;
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
        NSLog(@"[Pre-init] LauncherPreferences: Set default %@: %@", key, value);
    }
}

void setPreference(NSString* key, id value) {
    if (!(envPrefDict[key] == [NSNull null] || envPrefDict[key] == nil)) {
        envPrefDict[key] = value;
        prefDict[@"env_vars"] = envPrefDict;
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
        warnPrefDict = [[NSMutableDictionary alloc] init];
    } else {
        prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
        envPrefDict = prefDict[@"env_vars"];
        warnPrefDict = prefDict[@"warnings"];
    }

    assert(prefDict);

    // set default value
    setDefaultValueForPref(envPrefDict, @"resolution", @(100));
    setDefaultValueForPref(prefDict, @"button_scale", @(100));
    setDefaultValueForPref(prefDict, @"selected_version", @"1.7.10");
    setDefaultValueForPref(prefDict, @"selected_version_type", @(0));
    setDefaultValueForPref(envPrefDict, @"time_longPressTrigger", @(400));
    setDefaultValueForPref(envPrefDict, @"default_ctrl", @"default.json");
    setDefaultValueForPref(envPrefDict, @"game_directory", @"default");
    setDefaultValueForPref(envPrefDict, @"java_args", @"");
    setDefaultValueForPref(envPrefDict, @"allocated_memory", [NSNumber numberWithFloat:roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.30)]);
    setDefaultValueForPref(prefDict, @"restart_before_launch", @NO);
    setDefaultValueForPref(prefDict, @"debug_logging", CONFIG_TYPE);
    setDefaultValueForPref(prefDict, @"arccapes_enable", @YES);
    setDefaultValueForPref(envPrefDict, @"java_home", @"");
    setDefaultValueForPref(envPrefDict, @"renderer", @"auto");
    setDefaultValueForPref(warnPrefDict, @"option_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"local_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"mem_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"java_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"demo_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"jb_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"customctrl_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"int_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"ram_unjb_warn", @YES);
    setDefaultValueForPref(prefDict, @"a7_allow", @NO);
    setDefaultValueForPref(prefDict, @"slideable_hotbar", @NO);
    setDefaultValueForPref(prefDict, @"virtmouse_enable", @NO);
    setDefaultValueForPref(prefDict, @"check_sha", @YES);
    setDefaultValueForPref(prefDict, @"ram_unjb_enable", @NO);
    
    if (0 != [fileManager fileExistsAtPath:@"/var/mobile/Documents/.pojavlauncher"]) {
        setDefaultValueForPref(prefDict, @"disable_home_symlink", @NO);
    } else {
        setDefaultValueForPref(prefDict, @"disable_home_symlink", @YES);
    }

    setDefaultValueForPref(prefDict, @"control_safe_area", NSStringFromCGRect(getDefaultSafeArea()));

    prefDict[@"env_vars"] = envPrefDict;
    prefDict[@"warnings"] = warnPrefDict;

    [prefDict writeToFile:prefPath atomically:YES];
}

CGRect getDefaultSafeArea() {
    CGRect defaultSafeArea = UIScreen.mainScreen.bounds;
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    defaultSafeArea.origin.x = insets.left;
    //defaultSafeArea.origin.y = insets.top;
    defaultSafeArea.size.width -= insets.left + insets.right;
    //defaultSafeArea.size.height -= insets.bottom;
    // In some cases, the returned bounds is portrait instead of landscape
    if (defaultSafeArea.size.width < defaultSafeArea.size.height) {
        CGFloat height = defaultSafeArea.size.width;
        defaultSafeArea.size.width = defaultSafeArea.size.height;
        defaultSafeArea.size.height = height;
    }
    return defaultSafeArea;
}

CFTypeRef SecTaskCopyValueForEntitlement(void* task, NSString* entitlement, CFErrorRef  _Nullable *error);
void* SecTaskCreateFromSelf(CFAllocatorRef allocator);
BOOL getEntitlementValue(NSString *key) {
    void *secTask = SecTaskCreateFromSelf(NULL);
    CFTypeRef value = SecTaskCopyValueForEntitlement(SecTaskCreateFromSelf(NULL), key, nil);
    if (value != nil) {
        CFRelease(value);
    }
    CFRelease(secTask);

    return value != nil && [(__bridge id)value boolValue];
}
