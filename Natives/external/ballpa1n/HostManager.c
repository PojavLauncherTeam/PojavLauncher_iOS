// Thanks to this mf named Capt Inc for his ballpa1n

#import "HostManager.h"
#import <stddef.h>
#import <stdint.h>
#import <stdlib.h>
#import <string.h>
#import <sys/sysctl.h>
#import <CoreFoundation/CoreFoundation.h>
#import "include/CoreFoundation.h"
#import "include/IOKitLib.h"

int HostManagerModelName(char **name) {
    int retval = 1;
    
    int err = 0;
    
    err = HostManagerModelNamePrimary(name);
    if (err == 0) {
        retval = err;
        return retval;
    }
    
    err = HostManagerModelNameSecondary(name);
    if (err == 0) {
        retval = err;
        return retval;
    }
    
    return retval;
}

int HostManagerModelNamePrimary(char **name) {
    int retval = 1;
    char *outName = NULL;
    
    Boolean status = FALSE;
    
    io_registry_entry_t registry = IO_OBJECT_NULL;
    CFDataRef dataObj = NULL;
    CFStringRef stringObj = NULL;
    char *string = NULL;
    
    if (name == NULL) {
        goto end;
    }
    
    registry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product");
    if (registry == IO_OBJECT_NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("product-description");
    dataObj = IORegistryEntryCreateCFProperty(registry, key, kCFAllocatorDefault, 0);
    if (dataObj == NULL) {
        goto end;
    }
    
    stringObj = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(dataObj), CFDataGetLength(dataObj), kCFStringEncodingUTF8, FALSE);
    if (stringObj == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(stringObj);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    status = CFStringGetCString(stringObj, string, size, kCFStringEncodingUTF8);
    if (!status) {
        goto end;
    }
    
    retval = 0;
    outName = string;
    
end:
    if (registry != IO_OBJECT_NULL) {
        IOObjectRelease(registry);
    }
    if (dataObj != NULL) {
        CFRelease(dataObj);
    }
    if (stringObj != NULL) {
        CFRelease(stringObj);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (name != NULL) {
        *name = outName;
    }
    return retval;
}

int HostManagerModelNameSecondary(char **name) {
    int retval = 1;
    char *outName = NULL;
    
    Boolean status = FALSE;
    
    CFURLRef url1 = NULL;
    CFURLRef url2 = NULL;
    CFStringRef path = NULL;
    CFDictionaryRef dict = NULL;
    CFStringRef *keys = NULL;
    char *string = NULL;
    
    if (name == NULL) {
        goto end;
    }
    
    url1 = CFCopyHomeDirectoryURLForUser(NULL);
    if (url1 == NULL) {
        goto end;
    }
    
    url2 = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, url1, CFSTR("Library/Preferences/com.apple.SystemProfiler.plist"), FALSE);
    if (url2 == NULL) {
        goto end;
    }
    
    path = CFURLCopyPath(url2);
    if (path == NULL) {
        goto end;
    }
    
    dict = CFPreferencesCopyAppValue(CFSTR("CPU Names"), path);
    if (dict == NULL) {
        goto end;
    }
    
    CFIndex keysSize = CFDictionaryGetCount(dict) * sizeof(CFStringRef *);
    keys = malloc(keysSize);
    memset(keys, 0, keysSize);
    CFDictionaryGetKeysAndValues(dict, (void *)keys, NULL);
    
    CFStringRef key = keys[0];
    CFStringRef value = CFDictionaryGetValue(dict, key);
    if (value == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(value);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    status = CFStringGetCString(value, string, size, kCFStringEncodingUTF8);
    if (!status) {
        goto end;
    }
    
    retval = 0;
    outName = string;
    
end:
    if (url1 != NULL) {
        CFRelease(url1);
    }
    if (url2 != NULL) {
        CFRelease(url2);
    }
    if (path != NULL) {
        CFRelease(path);
    }
    if (dict != NULL) {
        CFRelease(dict);
    }
    if (keys != NULL) {
        free(keys);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (name != NULL) {
        *name = outName;
    }
    return retval;
}

int HostManagerModelIdentifier(char **identifier) {
    int retval = 1;
    char *outIdentifier = NULL;
    
    int err = 0;
    
    char *string = NULL;
    
    if (identifier == NULL) {
        goto end;
    }
    
    const char *key = "hw.product";
    
    size_t size = 0;
    err = sysctlbyname(key, NULL, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    err = sysctlbyname(key, string, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    retval = 0;
    outIdentifier = string;
    
end:
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (identifier != NULL) {
        *identifier = outIdentifier;
    }
    return retval;
}

int HostManagerModelArchitecture(char **architecture) {
    int retval = 1;
    char *outArchitecture = NULL;
    
    int err = 0;
    
    if (architecture == NULL) {
        goto end;
    }
    
    int arm64Value = 0;
    int ptrauthValue = 0;
    int x86_64Value = 0;
    
    size_t arm64Size = sizeof(arm64Value);
    err = sysctlbyname("hw.optional.arm64", &arm64Value, &arm64Size, NULL, 0);
    if (err != 0) {
        arm64Value = 0;
    }
    
    size_t ptrauthSize = sizeof(ptrauthValue);
    err = sysctlbyname("hw.optional.arm.FEAT_PAuth", &ptrauthValue, &ptrauthSize, NULL, 0);
    if (err != 0) {
        ptrauthValue = 0;
    }
    
    size_t x86_64Size = sizeof(x86_64Value);
    err = sysctlbyname("hw.optional.x86_64", &x86_64Value, &x86_64Size, NULL, 0);
    if (err != 0) {
        x86_64Value = 0;
    }
    
    const char *arch = NULL;
    if (arm64Value == 1) {
        if (ptrauthValue == 1) {
            arch = "arm64e";
        }
        else {
            arch = "arm64";
        }
    }
    else if (x86_64Value == 1) {
        arch = "x86_64";
    }
    else {
        goto end;
    }
    
    retval = 0;
    outArchitecture = strdup(arch);
    
end:
    if (architecture != NULL) {
        *architecture = outArchitecture;
    }
    return retval;
}

int HostManagerModelNumber(char **number) {
    int retval = 1;
    char *outNumber = NULL;
    
    Boolean status = FALSE;
    
    io_registry_entry_t registry = IO_OBJECT_NULL;
    CFDataRef dataObj = NULL;
    CFStringRef stringObj = NULL;
    char *string = NULL;
    
    if (number == NULL) {
        goto end;
    }
    
    registry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/");
    if (registry == IO_OBJECT_NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("regulatory-model-number");
    dataObj = IORegistryEntryCreateCFProperty(registry, key, kCFAllocatorDefault, 0);
    if (dataObj == NULL) {
        goto end;
    }
    
    stringObj = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(dataObj), CFDataGetLength(dataObj), kCFStringEncodingUTF8, FALSE);
    if (stringObj == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(stringObj);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    status = CFStringGetCString(stringObj, string, size, kCFStringEncodingUTF8);
    if (!status) {
        goto end;
    }
    
    retval = 0;
    outNumber = string;
    
end:
    if (registry != IO_OBJECT_NULL) {
        IOObjectRelease(registry);
    }
    if (dataObj != NULL) {
        CFRelease(dataObj);
    }
    if (stringObj != NULL) {
        CFRelease(stringObj);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (number != NULL) {
        *number = outNumber;
    }
    return retval;
}

int HostManagerModelBoard(char **board) {
    int retval = 1;
    char *outBoard = NULL;
    
    int err = 0;
    
    char *string = NULL;
    
    if (board == NULL) {
        goto end;
    }
    
    const char *key = "hw.target";
    
    size_t size = 0;
    err = sysctlbyname(key, NULL, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    err = sysctlbyname(key, string, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    retval = 0;
    outBoard = string;
    
end:
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (board != NULL) {
        *board = outBoard;
    }
    return retval;
}

int HostManagerModelChip(char **chip) {
    int retval = 1;
    char *outChip = NULL;
    
    Boolean status = FALSE;
    
    io_registry_entry_t registry = IO_OBJECT_NULL;
    CFDataRef dataObj = NULL;
    CFStringRef stringObj = NULL;
    CFMutableStringRef uppercaseStringObj = NULL;
    char *string = NULL;
    
    if (chip == NULL) {
        goto end;
    }
    
    registry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/");
    if (registry == IO_OBJECT_NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("platform-name");
    dataObj = IORegistryEntryCreateCFProperty(registry, key, kCFAllocatorDefault, 0);
    if (dataObj == NULL) {
        goto end;
    }
    
    stringObj = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(dataObj), CFDataGetLength(dataObj), kCFStringEncodingUTF8, FALSE);
    if (stringObj == NULL) {
        goto end;
    }
    
    uppercaseStringObj = CFStringCreateMutableCopy(kCFAllocatorDefault, CFStringGetLength(stringObj), stringObj);
    if (uppercaseStringObj == NULL) {
        goto end;
    }
    
    CFStringCapitalize(uppercaseStringObj, NULL);
    
    CFIndex length = CFStringGetLength(uppercaseStringObj);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    status = CFStringGetCString(uppercaseStringObj, string, size, kCFStringEncodingUTF8);
    if (!status) {
        goto end;
    }
    
    retval = 0;
    outChip = string;
    
end:
    if (registry != IO_OBJECT_NULL) {
        IOObjectRelease(registry);
    }
    if (dataObj != NULL) {
        CFRelease(dataObj);
    }
    if (stringObj != NULL) {
        CFRelease(stringObj);
    }
    if (uppercaseStringObj != NULL) {
        CFRelease(uppercaseStringObj);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (chip != NULL) {
        *chip = outChip;
    }
    return retval;
}

int HostManagerPlatformName(char **name) {
    int retval = 1;
    char *outName = NULL;
    
    Boolean success = FALSE;
    
    CFDictionaryRef dict = NULL;
    char *string = NULL;
    
    if (name == NULL) {
        goto end;
    }
    
    dict = _CFCopySystemVersionDictionary();
    if (dict == NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("ProductName");
    CFStringRef value = CFDictionaryGetValue(dict, key);
    if (value == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(value);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    success = CFStringGetCString(value, string, size, kCFStringEncodingUTF8);
    if (!success) {
        goto end;
    }
    
    if (strcmp(string, "iPhone OS") == 0) {
        free(string);
        string = NULL;
        string = strdup("iOS");
    }
    
    retval = 0;
    outName = string;
    
end:
    if (dict != NULL) {
        CFRelease(dict);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (name != NULL) {
        *name = outName;
    }
    return retval;
}

int HostManagerPlatformVersion(char **version) {
    int retval = 1;
    char *outVersion = NULL;
    
    Boolean success = FALSE;
    
    CFDictionaryRef dict = NULL;
    char *string = NULL;
    
    if (version == NULL) {
        goto end;
    }
    
    dict = _CFCopySystemVersionDictionary();
    if (dict == NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("ProductVersion");
    CFStringRef value = CFDictionaryGetValue(dict, key);
    if (value == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(value);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    success = CFStringGetCString(value, string, size, kCFStringEncodingUTF8);
    if (!success) {
        goto end;
    }
    
    retval = 0;
    outVersion = string;
    
end:
    if (dict != NULL) {
        CFRelease(dict);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (version != NULL) {
        *version = outVersion;
    }
    return retval;
}

int HostManagerPlatformIdentifier(char **identifier) {
    int retval = 1;
    char *outIdentifier = NULL;
    
    Boolean success = FALSE;
    
    CFDictionaryRef dict = NULL;
    char *string = NULL;
    
    if (identifier == NULL) {
        goto end;
    }
    
    dict = _CFCopySystemVersionDictionary();
    if (dict == NULL) {
        goto end;
    }
    
    CFStringRef key = CFSTR("ProductBuildVersion");
    CFStringRef value = CFDictionaryGetValue(dict, key);
    if (value == NULL) {
        goto end;
    }
    
    CFIndex length = CFStringGetLength(value);
    if (length == 0) {
        goto end;
    }
    
    CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    if (size == 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    success = CFStringGetCString(value, string, size, kCFStringEncodingUTF8);
    if (!success) {
        goto end;
    }
    
    retval = 0;
    outIdentifier = string;
    
end:
    if (dict != NULL) {
        CFRelease(dict);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (identifier != NULL) {
        *identifier = outIdentifier;
    }
    return retval;
}

int HostManagerKernelName(char **name) {
    int retval = 1;
    char *outName = NULL;
    
    int err = 0;
    
    char *string = NULL;
    
    if (name == NULL) {
        goto end;
    }
    
    const char *key = "kern.ostype";
    
    size_t size = 0;
    err = sysctlbyname(key, NULL, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    err = sysctlbyname(key, string, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    retval = 0;
    outName = string;
    
end:
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (name != NULL) {
        *name = outName;
    }
    return retval;
}

int HostManagerKernelVersion(char **version) {
    int retval = 1;
    char *outVersion = NULL;
    
    int err = 0;
    
    char *string = NULL;
    
    if (version == NULL) {
        goto end;
    }
    
    const char *key = "kern.osrelease";
    
    size_t size = 0;
    err = sysctlbyname(key, NULL, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    string = malloc(size);
    memset(string, 0, size);
    
    err = sysctlbyname(key, string, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    retval = 0;
    outVersion = string;
    
end:
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (version != NULL) {
        *version = outVersion;
    }
    return retval;
}

int HostManagerKernelIdentifier(char **identifier) {
    int retval = 1;
    char *outIdentifier = NULL;
    
    int err = 0;
    
    char *rawString = NULL;
    char *string = NULL;
    
    if (identifier == NULL) {
        goto end;
    }
    
    const char *key = "kern.version";
    
    size_t size = 0;
    err = sysctlbyname(key, NULL, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    rawString = malloc(size);
    memset(rawString, 0, size);
    
    err = sysctlbyname(key, rawString, &size, NULL, 0);
    if (err != 0) {
        goto end;
    }
    
    const char *leftCursor = "xnu-";
    const char *rightCursor = "~";
    
    char *cursorBegin = strstr(rawString, leftCursor);
    cursorBegin = (char *)((uintptr_t)cursorBegin + strlen(leftCursor));
    char *cursorEnd = strstr(cursorBegin, rightCursor);
    size_t cursorLength = (uintptr_t)cursorEnd - (uintptr_t)cursorBegin;
    
    size_t stringSize = cursorLength + 1;
    string = malloc(stringSize);
    memset(string, 0, stringSize);
    
    memcpy(string, cursorBegin, cursorLength);
    string[cursorLength] = 0;
    
    retval = 0;
    outIdentifier = string;
    
end:
    if (rawString != NULL) {
        free(rawString);
    }
    if (retval != 0) {
        if (string != NULL) {
            free(string);
        }
    }
    
    if (identifier != NULL) {
        *identifier = outIdentifier;
    }
    return retval;
}
