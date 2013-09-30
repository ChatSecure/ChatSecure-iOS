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


+(NSString *)stripHTML:(NSString *)string;
+(NSString *)uniqueString;

+(void)deleteAllBuddiesAndMessages;

+(BOOL)dateInLast24Hours:(NSDate *)date;
+(BOOL)dateInLast7Days:(NSDate *)date;

+(NSArray *)cipherSuites;

+(NSString *)currentAppVersionString;
+(NSString *)lastLaunchVersion;
+(BOOL)isFirstLaunchOnCurrentVersion;

@end
