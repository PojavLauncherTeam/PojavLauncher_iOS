#import <UIKit/UIKit.h>

#define JRE8_HOME_JB @"/usr/lib/jvm/java-8-openjdk"
#define JRE16_HOME_JB @"/usr/lib/jvm/java-16-openjdk"
#define JRE17_HOME_JB @"/usr/lib/jvm/java-17-openjdk"

void loadPreferences(BOOL reset);
id getPreference(NSString* key);
NSMutableDictionary* getDictionary(NSString *type);
int getJavaVersion(NSString* java);
int getSelectedJavaVersion();
void setDefaultValueForPref(NSMutableDictionary *dict, NSString* key, id value);
void setPreference(NSString* key, id value);
void resetWarnings();

CGRect getDefaultSafeArea();
BOOL getEntitlementValue(NSString *key);
