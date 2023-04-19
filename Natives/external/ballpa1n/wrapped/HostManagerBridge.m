//
//  HostManagerBridge.m
//  ballpa1n
//
//  Created by Lakhan Lothiyi on 20/10/2022.
//

#import <Foundation/Foundation.h>
#import "HostManagerBridge.h"
#import "../HostManager.h"

@implementation HostManager
+(NSString *)GetModelName {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelName(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetModelIdentifier {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelIdentifier(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetModelArchitecture {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelArchitecture(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetModelNumber {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelNumber(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetModelBoard {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelBoard(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetModelChip {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerModelChip(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetPlatformName {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerPlatformName(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetPlatformVersion {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerPlatformVersion(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetPlatformIdentifier {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerPlatformIdentifier(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetKernelName {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerKernelName(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetKernelVersion {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerKernelVersion(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
+(NSString *)GetKernelIdentifier {
    NSString *unknown = NULL;
    char *rawMF = NULL;
    int err = HostManagerKernelIdentifier(&rawMF);
    NSString *MF = nil;
    if (err == 0) {
        NSString *str = [NSString stringWithUTF8String:rawMF];
        free(rawMF);
        if (![str isEqualToString:@""]) {
            MF = str;
        }
        else {
            MF = unknown;
        }
    }
    else {
        MF = unknown;
    }
    
    return MF;
}
@end
