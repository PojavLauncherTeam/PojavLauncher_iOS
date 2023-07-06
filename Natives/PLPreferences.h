#import <Foundation/Foundation.h>

@interface PLPreferences : NSObject

@property(nonatomic) NSString *globalPath, *instancePath;
@property(nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary *> *globalPref, *instancePref;

- (id)initWithGlobalPath:(NSString *)path;
- (id)initWithAutomaticMigrator;

- (void)toggleIsolationForced:(BOOL)forced;
- (id)getObject:(NSString *)key;
- (BOOL)setObject:(NSString *)key value:(id)value;
- (void)reset;

@end
