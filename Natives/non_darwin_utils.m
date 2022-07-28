#import <Foundation/Foundation.h>

// This is only compiled when building on non-Apple platforms

int __isPlatformVersionAtLeast(int platform, int major, int minor, int patch) {
    NSOperatingSystemVersion version;
    version.majorVersion = major;
    version.minorVersion = minor;
    version.patchVersion = patch;
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}
