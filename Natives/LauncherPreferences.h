#import <Foundation/Foundation.h>

#define JRE8_HOME_JB @"/usr/lib/jvm/java-8-openjdk"
#define JRE16_HOME_JB @"/usr/lib/jvm/java-16-openjdk"
#define JRE17_HOME_JB @"/usr/lib/jvm/java-17-openjdk"

void loadPreferences();
id getPreference(NSString* key);
NSMutableDictionary* getDictionary(NSString *type);
int getSelectedJavaVersion();
void setDefaultValueForPref(NSMutableDictionary *dict, NSString* key, id value);
void setPreference(NSString* key, id value);
