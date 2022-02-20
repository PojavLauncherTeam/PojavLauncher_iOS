#import <Foundation/Foundation.h>

void loadPreferences();
id getPreference(NSString* key);
NSMutableDictionary* getDictionary(NSString *type);
void setDefaultValueForPref(NSMutableDictionary *dict, NSString* key, id value);
void setPreference(NSString* key, id value);
