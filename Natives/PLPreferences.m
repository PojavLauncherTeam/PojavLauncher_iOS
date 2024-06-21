#import "LauncherPreferences.h"
#import "PLPreferences.h"
#import "UIKit+hook.h"
#import "config.h"
#import "utils.h"

@interface PLPreferences()
@end

@implementation PLPreferences

+ (id)defaultPrefForGlobal:(BOOL)global {
    // Preferences that can be isolated
    NSMutableDictionary<NSString *, NSMutableDictionary *> *defaults = @{
        @"general": @{
            @"check_sha": @YES,
            @"cosmetica": @YES,
            @"debug_logging": @(!CONFIG_RELEASE),
        }.mutableCopy,
        @"video": @{ // Video & Audio
            @"renderer": @"auto",
            @"resolution": @(100),
            @"max_framerate": @YES,
            @"performance_hud": @NO,
            @"fullscreen_airplay": @YES,
            @"silence_other_audio": @NO,
            @"silence_with_switch": @NO
        }.mutableCopy,
        @"control": @{
            @"default_ctrl": @"default.json",
            @"control_safe_area": UIApplication.sharedApplication ? NSStringFromUIEdgeInsets(getDefaultSafeArea()) : @"",
            @"default_gamepad_ctrl": @"default.json",
            @"controller_type": @"xbox",
            @"hardware_hide": @YES,
            @"recording_hide": @YES,
            @"gesture_mouse": @YES,
            @"gesture_hotbar": @YES,
            @"disable_haptics": @NO,
            @"slideable_hotbar": @NO,
            @"press_duration": @(400),
            @"button_scale": @(100),
            @"mouse_scale": @(100),
            @"mouse_speed": @(100),
            @"virtmouse_enable": @NO,
            @"gyroscope_enable": @NO,
            @"gyroscope_invert_x_axis": @NO,
            @"gyroscope_sensitivity": @(100)
        }.mutableCopy,
        @"java": @{
            @"java_homes": @{
                @"0": @{
                    @"1_16_5_older": @"8",
                    @"1_17_newer": @"17",
                    @"execute_jar": @"8"
                }.mutableCopy,
                @"8": @"internal",
                @"17": @"internal",
                @"21": @"internal"
            }.mutableCopy,
            @"java_args": @"",
            @"env_variables": @"",
            @"auto_ram": @(!getEntitlementValue(@"com.apple.private.memorystatus")),
            @"allocated_memory": [NSNumber numberWithFloat:roundf((NSProcessInfo.processInfo.physicalMemory / 1048576) * 0.25)]
        }.mutableCopy,
        @"internal": @{
            @"isolated": @NO,
            @"latest_version": [NSDictionary new]
        }.mutableCopy
    }.mutableCopy;

    if (global) {
        // Preferences that cannot be isolated
        NSDictionary *general = @{
            @"game_directory": @"default",
            @"hidden_sidebar": @(realUIIdiom == UIUserInterfaceIdiomPhone),
            @"appicon": @"AppIcon-Light"
        };
        [defaults[@"general"] addEntriesFromDictionary:general];

        defaults[@"java"][@"manage_runtime"] = @""; // stub
        defaults[@"debug"] = @{
            @"debug_skip_wait_jit": @NO,
            @"debug_hide_home_indicator": @NO,
            @"debug_ipad_ui": @(realUIIdiom == UIUserInterfaceIdiomPad),
            @"debug_auto_correction": @YES,
            @"debug_show_layout_bounds": @NO,
            @"debug_show_layout_overlap": @NO
        }.mutableCopy;
        defaults[@"warnings"] = @{
            @"local_warn": @YES,
            @"mem_warn": @YES,
            @"auto_ram_warn": @YES,
            @"limited_ram_warn": @YES
        }.mutableCopy;
        // TODO: isolate this or add account picker into profile editor(?)
        defaults[@"internal"][@"selected_account"] = @"";
    }

    return defaults;
}

+ (id)getPreference:(NSString *)key from:(NSDictionary *)pref {
    for (NSDictionary *section in pref.allValues) {
        if ([section isKindOfClass:NSDictionary.class] && section[key]) {
            return section[key];
        }
    }
    return nil;
}

+ (id)getOldLayoutPreference:(NSString *)key from:(NSDictionary *)pref {
    // Find preference in the root dictionary first
    if (pref[key]) {
        return pref[key];
    }
    // Find preference in subdictionaries
    id value = [self getPreference:key from:pref];
    if (!value) {
        NSLog(@"[PLPreferences] Migrator could not find preference %@", key);
    }
    return value;
}

- (id)initWithGlobalPath:(NSString *)path {
    self = [super init];
    self.globalPath = path;
    self.globalPref = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    [self saveGlobalPref];
    return self;
}

- (id)initWithAutomaticMigrator {
    self = [super init];
    self.globalPath = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"launcher_preferences_v2.plist"];
    NSMutableDictionary *pref = [NSMutableDictionary dictionaryWithContentsOfFile:self.globalPath];

    NSString *oldPath = [@(getenv("POJAV_HOME")) stringByAppendingPathComponent:@"launcher_preferences.plist"];
    NSMutableDictionary *oldPref = [NSMutableDictionary dictionaryWithContentsOfFile:oldPath];

    if (pref || !oldPref[@"env_vars"]) {
        // Initialize or load existing v2 layout
        self.globalPref = pref;
    } else {
        NSDebugLog(@"[PLPreferences] Migrating to %@", self.globalPath.lastPathComponent);
        // Perform migration from v1 layout
        self.globalPref = [NSMutableDictionary new];
        for (NSString *section in self.globalPref.allKeys) {
            for (NSString *key in self.globalPref[section].allKeys) {
                id value = [PLPreferences getOldLayoutPreference:key from:oldPref];
                if (value) {
                    self.globalPref[section][key] = value;
                }
            }
        }
    }

    [self saveGlobalPref];
    return self;
}

- (id)setDefaultsForPref:(NSMutableDictionary *)pref global:(BOOL)global {
    NSMutableDictionary<NSString *, NSMutableDictionary *> *defaults = [PLPreferences defaultPrefForGlobal:global];
    if (!pref) {
        NSLog(@"[PLPreferences] Initializing default values for %@ preferences", global ? @"global" : @"isolated");
        return defaults;
    }

    for (NSString *section in defaults.allKeys) {
        if (!pref[section]) {
            NSDebugLog(@"[PLPreferences] Set default values for section %@", section);
            pref[section] = defaults[section];
            continue;
        }
        for (NSString *key in defaults[section].allKeys) {
            if (pref[section][key]) continue;
            id value = defaults[section][key];
            NSDebugLog(@"[PLPreferences] Set default vaule: %@: %@", key, value);
            pref[section][key] = value;
        }
    }
    return pref;
}

- (void)setGlobalPref:(NSMutableDictionary *)pref {
    _globalPref = [self setDefaultsForPref:pref global:YES];
}

- (void)setInstancePref:(NSMutableDictionary *)pref {
    _instancePref = [self setDefaultsForPref:pref global:NO];
}

- (void)toggleIsolationForced:(BOOL)force {
    NSMutableDictionary *instancePref = [NSMutableDictionary dictionaryWithContentsOfFile:self.instancePath];
    if (force || [instancePref[@"internal"][@"isolated"] boolValue]) {
        NSLog(@"[PLPreferences] Using isolated preferences from %@", self.instancePath.stringByResolvingSymlinksInPath);
        self.instancePref = instancePref;
        if (!instancePref) {
            // Copy preferences from the global one
            for (NSString *section in self.instancePref) {
                for (NSString *key in self.instancePref[section].allKeys) {
                    self.instancePref[section][key] = self.globalPref[section][key];
                }
            }
        }

        // Declare that itself is isolated
        self.instancePref[@"internal"][@"isolated"] = @YES;

        [self saveInstancePref];
    } else if (self.instancePref) {
        NSLog(@"[PLPreferences] Using global preferences");
        _instancePref = nil;
    }
}

- (id)getObject:(NSString *)key {
    id value = [self.instancePref valueForKeyPath:key];
    if (!value) {
        value = [self.globalPref valueForKeyPath:key];
    }
    if (!value) {
        NSLog(@"[PLPreferences] Getter could not find preference %@", key);
    }
    return value;
}

- (BOOL)setObject:(NSString *)key value:(id)value {
    if ([self.instancePref valueForKeyPath:key]) {
        [self.instancePref setValue:value forKeyPath:key];
        [self saveInstancePref];
        return YES;
    } else if ([self.globalPref valueForKeyPath:key]) {
        [self.globalPref setValue:value forKeyPath:key];
        [self saveGlobalPref];
        return YES;
    }
    NSLog(@"[PLPreferences] Setter could not find preference %@", key);
    return NO;
}

- (void)reset {
    if (self.instancePref) {
        [NSFileManager.defaultManager removeItemAtPath:self.instancePath error:nil];
        [self toggleIsolationForced:YES];
        // Only reset isolated values
        return;
    }

    self.globalPref = nil;
    [self saveGlobalPref];
}

- (void)saveGlobalPref {
    [self.globalPref writeToFile:self.globalPath atomically:YES];
}

- (void)saveInstancePref {
    [self.instancePref writeToFile:self.instancePath atomically:YES];
}

@end
