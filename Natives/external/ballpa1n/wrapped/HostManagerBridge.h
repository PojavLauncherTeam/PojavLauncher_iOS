//
//  WhatCanINameThis.h
//  ballpa1n
//
//  Created by Lakhan Lothiyi on 20/10/2022.
//

#import <Foundation/Foundation.h>

#ifndef HostManagerBridge_h
#define HostManagerBridge_h

@interface HostManager : NSObject
+(NSString *)GetModelName;
+(NSString *)GetModelIdentifier;
+(NSString *)GetModelArchitecture;
+(NSString *)GetModelNumber;
+(NSString *)GetModelBoard;
+(NSString *)GetModelChip;
+(NSString *)GetPlatformName;
+(NSString *)GetPlatformVersion;
+(NSString *)GetPlatformIdentifier;
+(NSString *)GetKernelName;
+(NSString *)GetKernelVersion;
+(NSString *)GetKernelIdentifier;
@end

#endif /* HostManagerBridge_h */
