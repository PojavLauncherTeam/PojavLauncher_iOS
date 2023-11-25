#import <UIKit/UIKit.h>

void loadPreferences(BOOL reset);
void toggleIsolatedPref(BOOL forceEnable);

id getPrefObject(NSString *key);
BOOL getPrefBool(NSString *key);
float getPrefFloat(NSString *key);
NSInteger getPrefInt(NSString *key);

void setPrefObject(NSString *key, id value);
void setPrefBool(NSString *key, BOOL value);
void setPrefFloat(NSString *key, float value);
void setPrefInt(NSString *key, NSInteger value);

void resetWarnings();

BOOL getEntitlementValue(NSString *key);

UIEdgeInsets getDefaultSafeArea();
CGRect getSafeArea();
void setSafeArea(CGRect safeArea);

NSString* getSelectedJavaHome(NSString* defaultJRETag, int minVersion);

NSArray* getRendererKeys(BOOL containsDefault);
NSArray* getRendererNames(BOOL containsDefault);
