#import "LauncherPreferences.h"
#import <CoreFoundation/CoreFoundation.h>

NSMutableDictionary *prefDict;
NSString* prefPath;
// developer debug dict
NSMutableDictionary *debugPrefDict;
// environment variables dict
NSMutableDictionary *envPrefDict;
// warnings dict
NSMutableDictionary *warnPrefDict;

id getPreference(NSString* key) {
    if (!(debugPrefDict[key] == [NSNull null] || debugPrefDict[key] == nil)) {
        return debugPrefDict[key];
    } else if (!(envPrefDict[key] == [NSNull null] || envPrefDict[key] == nil)) {
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
    if (!(debugPrefDict[key] == [NSNull null] || debugPrefDict[key] == nil)) {
        debugPrefDict[key] = value;
        prefDict[@"debugs"] = debugPrefDict;
    } else if (!(envPrefDict[key] == [NSNull null] || envPrefDict[key] == nil)) {
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

void fillDefaultWarningDict() {
    setDefaultValueForPref(warnPrefDict, @"option_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"local_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"mem_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"java_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"demo_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"jb_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"int_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"auto_ram_warn", @YES);
}

NSMutableDictionary* getDictionarySafe(NSString* key) {
    if (prefDict[key] == nil) {
        return [[NSMutableDictionary alloc] init];
    }
    return prefDict[key];
}

void loadPreferences(BOOL reset) {
    assert(getenv("POJAV_HOME"));
    prefPath = [@(getenv("POJAV_HOME"))
      stringByAppendingPathComponent:@"launcher_preferences.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
    if (reset) {
        [prefDict removeAllObjects];
    } else if (![fileManager fileExistsAtPath:prefPath]) {
        prefDict = [[NSMutableDictionary alloc] init];
    }
    debugPrefDict = getDictionarySafe(@"debugs");
    envPrefDict = getDictionarySafe(@"env_vars");
    warnPrefDict = getDictionarySafe(@"warnings");

    // set default value
    setDefaultValueForPref(envPrefDict, @"resolution", @(100));
    setDefaultValueForPref(prefDict, @"button_scale", @(100));
    setDefaultValueForPref(prefDict, @"selected_version", @"1.7.10");
    setDefaultValueForPref(prefDict, @"selected_version_type", @(0));
    setDefaultValueForPref(envPrefDict, @"press_duration", @(400));
    setDefaultValueForPref(envPrefDict, @"mouse_scale", @(100));
    setDefaultValueForPref(envPrefDict, @"mouse_speed", @(100));
    setDefaultValueForPref(envPrefDict, @"default_ctrl", @"default.json");
    setDefaultValueForPref(envPrefDict, @"game_directory", @"default");
    setDefaultValueForPref(envPrefDict, @"java_args", @"");
    setDefaultValueForPref(envPrefDict, @"allocated_memory", [NSNumber numberWithFloat:roundf(([[NSProcessInfo processInfo] physicalMemory] / 1048576) * 0.25)]);
    setDefaultValueForPref(prefDict, @"debug_logging", @(CONFIG_RELEASE != 1));
    setDefaultValueForPref(prefDict, @"cosmetica", @YES);
    setDefaultValueForPref(envPrefDict, @"java_home", @"java-8-openjdk");
    setDefaultValueForPref(envPrefDict, @"renderer", @"auto");
    fillDefaultWarningDict();
    setDefaultValueForPref(prefDict, @"a7_allow", @NO);
    setDefaultValueForPref(prefDict, @"slideable_hotbar", @NO);
    setDefaultValueForPref(prefDict, @"virtmouse_enable", @NO);
    setDefaultValueForPref(prefDict, @"check_sha", @YES);
    setDefaultValueForPref(prefDict, @"auto_ram", @(!getEntitlementValue(@"com.apple.private.memorystatus")));
    setDefaultValueForPref(prefDict, @"unsupported_warn_counter", @(0));

    // Debug settings
    setDefaultValueForPref(debugPrefDict, @"debug_ipad_ui", @(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad));
    setDefaultValueForPref(debugPrefDict, @"debug_show_layout_bounds", @NO);
    setDefaultValueForPref(debugPrefDict, @"debug_show_layout_overlap", @NO);

    // Migrate some prefs
    setPreference(@"java_home", [getPreference(@"java_home") lastPathComponent]);

    prefDict[@"debugs"] = debugPrefDict;
    prefDict[@"env_vars"] = envPrefDict;
    prefDict[@"warnings"] = warnPrefDict;

    [prefDict writeToFile:prefPath atomically:YES];
}

void resetWarnings() {
    [warnPrefDict removeAllObjects];
    fillDefaultWarningDict();
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
