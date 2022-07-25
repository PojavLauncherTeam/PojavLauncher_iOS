#import <Foundation/Foundation.h>
#import "log.h"
#import "LauncherPreferences.h"

void regLog(const char *message,...) {
    va_list args;
    va_start(args, message);
    NSLog(@"%@",[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:message] arguments:args]);
    va_end(args);
}

void debugLog(const char *message,...)
{
    if([getPreference(@"debug_logging") boolValue]) {
        va_list args;
        va_start(args, message);
        NSLog(@"%@",[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:message] arguments:args]);
        va_end(args);
    } else {
        static BOOL debugLog_warned = NO;
        if (debugLog_warned) return;
        debugLog_warned = YES;
        NSLog(@"WARNING!!! DEBUG LOG DISABLED");
    }
}
