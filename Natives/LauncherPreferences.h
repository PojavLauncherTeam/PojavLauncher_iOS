#import <UIKit/UIKit.h>

void loadPreferences(BOOL reset);
void toggleIsolatedPref(BOOL forceEnable);

id getPrefObject(NSString *key);
static inline BOOL getPrefBool(NSString *key) {
    return [getPrefObject(key) boolValue];
}
static inline float getPrefFloat(NSString *key) {
    return [getPrefObject(key) floatValue];
}
static inline NSInteger getPrefInt(NSString *key) {
    return [getPrefObject(key) intValue];
}

void setPrefObject(NSString *key, id value);
static inline void setPrefBool(NSString *key, BOOL value) {
    setPrefObject(key, @(value));
}
static inline void setPrefFloat(NSString *key, float value) {
    setPrefObject(key, @(value));
}
static inline void setPrefInt(NSString *key, NSInteger value) {
    setPrefObject(key, @(value));
}

void resetWarnings();

BOOL getEntitlementValue(NSString *key);

UIEdgeInsets getDefaultSafeArea();
CGRect getSafeArea();
void setSafeArea(CGRect safeArea);

NSString* getSelectedJavaHome(NSString* defaultJRETag, int minVersion);

NSArray* getRendererKeys(BOOL containsDefault);
NSArray* getRendererNames(BOOL containsDefault);
