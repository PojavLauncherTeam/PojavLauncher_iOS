#import <UIKit/UIKit.h>

void loadPreferences(BOOL reset);
id getPreference(NSString* key);
NSMutableDictionary* getDictionary(NSString *type);
int getJavaVersion(NSString* java);
int getSelectedJavaVersion();
void setDefaultValueForPref(NSMutableDictionary *dict, NSString* key, id value);
void setPreference(NSString* key, id value);
void resetWarnings();

BOOL getEntitlementValue(NSString *key);

UIEdgeInsets getDefaultSafeArea();
CGRect getSafeArea();
void setSafeArea(CGRect safeArea);
