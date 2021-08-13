#import <Foundation/Foundation.h>

void loadPreferences();
id getPreference(NSString* key);
void setDefaultValueForPref(NSString* key, id value);
void setPreference(NSString* key, id value);
