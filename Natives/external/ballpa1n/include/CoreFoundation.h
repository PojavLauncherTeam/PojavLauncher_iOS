#import <CoreFoundation/CoreFoundation.h>

extern CFURLRef CFCopyHomeDirectoryURLForUser(CFStringRef user);
extern CFDictionaryRef _CFCopySystemVersionDictionary(void);
extern CFBundleRef _CFBundleCreateWithExecutableURLIfLooksLikeBundle(CFAllocatorRef allocator, CFURLRef url);
