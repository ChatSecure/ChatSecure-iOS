//
//  OTRUtilities.h
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OTRConstants.h"

/*
 *  System Versioning Preprocessor Macros
 */
@interface OTRUtilities : NSObject

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

+(NSString *)stripHTML:(NSString *)string;
+(NSString *)uniqueString;

+(void)deleteAllBuddiesAndMessages;

+(BOOL)dateInLast24Hours:(NSDate *)date;
+(BOOL)dateInLast7Days:(NSDate *)date;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+(NSArray *)cipherSuites;

+(NSString *)currentAppVersionString;
+(NSString *)lastLaunchVersion;
+(BOOL)isFirstLaunchOnCurrentVersion;

+ (BOOL)currentiOSVersionHasSSLVulnerability;

@end
