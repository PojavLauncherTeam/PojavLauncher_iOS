#import "config.h"
#import "LauncherPreferences.h"
#import "UIKit+hook.h"
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
    setDefaultValueForPref(warnPrefDict, @"local_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"mem_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"auto_ram_warn", @YES);
    setDefaultValueForPref(warnPrefDict, @"limited_ram_warn", @YES);
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

    setDefaultValueForPref(envPrefDict, @"resolution", @(100));
    setDefaultValueForPref(envPrefDict, @"gesture_mouse", @YES);
    setDefaultValueForPref(envPrefDict, @"gesture_hotbar", @YES);
    setDefaultValueForPref(envPrefDict, @"press_duration", @(400));
    setDefaultValueForPref(envPrefDict, @"mouse_scale", @(100));
    setDefaultValueForPref(envPrefDict, @"mouse_speed", @(100));
    setDefaultValueForPref(envPrefDict, @"gyroscope_enable", @NO);
    setDefaultValueForPref(envPrefDict, @"gyroscope_invert_x_axis", @NO);
    setDefaultValueForPref(envPrefDict, @"gyroscope_sensitivity", @(100));
    setDefaultValueForPref(envPrefDict, @"default_ctrl", @"default.json");
    setDefaultValueForPref(envPrefDict, @"default_gamepad_ctrl", @"default.json");
    setDefaultValueForPref(envPrefDict, @"game_directory", @"default");
    setDefaultValueForPref(envPrefDict, @"java_args", @"");
    setDefaultValueForPref(envPrefDict, @"env_variables", @"");
    setDefaultValueForPref(envPrefDict, @"allocated_memory", [NSNumber numberWithFloat:roundf((NSProcessInfo.processInfo.physicalMemory / 1048576) * 0.25)]);
    setDefaultValueForPref(envPrefDict, @"jitstreamer_server", @"69.69.0.1");
    setDefaultValueForPref(envPrefDict, @"max_framerate", @YES);
    setDefaultValueForPref(envPrefDict, @"renderer", @"auto");
    setDefaultValueForPref(envPrefDict, @"fullscreen_airplay", @YES);
    setDefaultValueForPref(envPrefDict, @"hardware_hide", @NO);
    setDefaultValueForPref(envPrefDict, @"silence_other_audio", @NO);
    setDefaultValueForPref(envPrefDict, @"silence_with_switch", @NO);
    setDefaultValueForPref(envPrefDict, @"disable_haptics", @NO);
    setDefaultValueForPref(envPrefDict, @"java_homes", @{
        @"0": @{
            @"1_16_5_older": @"8",
            @"1_17_newer": @"17",
            @"install_jar": @"8"
        }.mutableCopy,
        @"8": @"internal",
        @"17": @"internal",
    }.mutableCopy);
    // stub pref
    setDefaultValueForPref(prefDict, @"manage_runtime", @"");
    
    setDefaultValueForPref(prefDict, @"button_scale", @(100));
    setDefaultValueForPref(prefDict, @"selected_account", @"");
    setDefaultValueForPref(prefDict, @"selected_version", @"1.7.10");
    setDefaultValueForPref(prefDict, @"selected_version_type", @(0));
    setDefaultValueForPref(prefDict, @"appicon", @"AppIcon-Light");
    setDefaultValueForPref(prefDict, @"debug_logging", @(CONFIG_RELEASE != 1));
    setDefaultValueForPref(prefDict, @"cosmetica", @YES);
    setDefaultValueForPref(prefDict, @"controller_type", @"xbox");
    setDefaultValueForPref(prefDict, @"slimmed", @NO);
    setDefaultValueForPref(prefDict, @"slideable_hotbar", @NO);
    setDefaultValueForPref(prefDict, @"virtmouse_enable", @NO);
    setDefaultValueForPref(prefDict, @"check_sha", @YES);
    setDefaultValueForPref(prefDict, @"auto_ram", @(!getEntitlementValue(@"com.apple.private.memorystatus")));
    setDefaultValueForPref(prefDict, @"legacy_version_counter", @(0));
    setDefaultValueForPref(prefDict, @"hidden_sidebar", @(realUIIdiom == UIUserInterfaceIdiomPhone));
    setDefaultValueForPref(prefDict, @"enable_altkit", @YES);
    
    setDefaultValueForPref(debugPrefDict, @"debug_skip_wait_jit", @NO);
    setDefaultValueForPref(debugPrefDict, @"debug_hide_home_indicator", @NO);
    setDefaultValueForPref(debugPrefDict, @"debug_ipad_ui", @(realUIIdiom == UIUserInterfaceIdiomPad));
    setDefaultValueForPref(debugPrefDict, @"debug_auto_correction", @YES);
    setDefaultValueForPref(debugPrefDict, @"debug_show_layout_bounds", @NO);
    setDefaultValueForPref(debugPrefDict, @"debug_show_layout_overlap", @NO);
    
    fillDefaultWarningDict();

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

#pragma mark Safe area

CGRect getSafeArea() {
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    UIEdgeInsets safeArea = UIEdgeInsetsFromString(getPreference(@"control_safe_area"));
    if (screenBounds.size.width < screenBounds.size.height) {
        safeArea = UIEdgeInsetsMake(safeArea.right, safeArea.top, safeArea.left, safeArea.bottom);
    }
    return UIEdgeInsetsInsetRect(screenBounds, safeArea);
}

void setSafeArea(CGRect frame) {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    UIEdgeInsets safeArea;
    // TODO: make safe area consistent across opposite orientations?
    if (screenSize.width < screenSize.height) {
        safeArea = UIEdgeInsetsMake(
            frame.origin.x,
            screenSize.height - CGRectGetMaxY(frame),
            screenSize.width - CGRectGetMaxX(frame),
            frame.origin.y);
    } else {
        safeArea = UIEdgeInsetsMake(
            frame.origin.y,
            frame.origin.x,
            screenSize.height - CGRectGetMaxY(frame),
            screenSize.width - CGRectGetMaxX(frame));
    }
    setPreference(@"control_safe_area", NSStringFromUIEdgeInsets(safeArea));
}

UIEdgeInsets getDefaultSafeArea() {
    UIEdgeInsets safeArea = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    if (screenSize.width < screenSize.height) {
        safeArea.left = safeArea.top;
        safeArea.right = safeArea.bottom;
    }
    safeArea.top = safeArea.bottom = 0;
    return safeArea;
}

#pragma mark Java runtime

NSString* getSelectedJavaHome(NSString* defaultJRETag, int minVersion) {
    NSDictionary *pref = getPreference(@"java_homes");
    NSDictionary<NSString *, NSString *> *selected = pref[@"0"];
    NSString *selectedVer = selected[defaultJRETag];
    if ([defaultJRETag isEqualToString:@"install_jar"] && minVersion > selectedVer.intValue) {
        NSArray *sortedVersions = [pref.allKeys valueForKeyPath:@"self.integerValue"];
        sortedVersions = [sortedVersions sortedArrayUsingSelector:@selector(compare:)];
        for (NSNumber *version in sortedVersions) {
            if (version.intValue >= minVersion) {
                selectedVer = version.stringValue;
                break;
            }
        }
        if (!selectedVer) {
            NSLog(@"Error: requested Java >= %d was not installed!", minVersion);
            return nil;
        }
    }

    id selectedDir = pref[selectedVer];
    if ([selectedDir isEqualToString:@"internal"]) {
        selectedDir = [NSString stringWithFormat:@"%s/java_runtimes/java-%@-openjdk", getenv("BUNDLE_PATH"), selectedVer];
    } else {
        selectedDir = [NSString stringWithFormat:@"%s/java_runtimes/%@", getenv("POJAV_HOME"), selectedDir];
    }

    if ([NSFileManager.defaultManager fileExistsAtPath:selectedDir]) {
        return selectedDir;
    } else {
        NSLog(@"Error: selected runtime for %@ does not exist: %@", defaultJRETag, selectedDir);
        return nil;
    }
}
