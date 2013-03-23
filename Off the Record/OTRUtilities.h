//
//  OTRUtilities.h
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRUtilities : NSObject


+(NSString *)stripHTML:(NSString *)string;
+(NSString *)uniqueString;

+(void)deleteAllBuddiesAndMessages;

+(BOOL)dateInLast24Hours:(NSDate *)date;
+(BOOL)dateInLast7Days:(NSDate *)date;

@end
