//
//  OTRUtilities.m
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRUtilities.h"
#import "OTRManagedBuddy.h"
#import "OTRManagedGroup.h"

@implementation OTRUtilities


+(NSString *)stripHTML:(NSString *)string
{
    NSRange range;
    NSString *finalString = [string copy];
    while ((range = [finalString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        finalString = [finalString stringByReplacingCharactersInRange:range withString:@""];
    return finalString;
}

+(NSString *)uniqueString
{
    NSString *result = nil;
	
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	if (uuid)
	{
		result = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
		CFRelease(uuid);
	}
	
	return result;
}

+(void)deleteAllBuddiesAndMessages
{
    //Delete all stored buddies
    [OTRManagedBuddy MR_deleteAllMatchingPredicate:nil];
    //Delete all stored messages
    [OTRManagedMessageAndStatus MR_deleteAllMatchingPredicate:nil];
    //Delete all Groups
    [OTRManagedGroup MR_deleteAllMatchingPredicate:nil];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

+(BOOL)dateInLast24Hours:(NSDate *)date
{
    if([date timeIntervalSinceNow] < (24*60*60))
    {
        return YES;
    }
    return NO;
    
}
+(BOOL)dateInLast7Days:(NSDate *)date
{
    if([date timeIntervalSinceNow] < (7*24*60*60))
    {
        return YES;
    }
    return NO;
}

@end


