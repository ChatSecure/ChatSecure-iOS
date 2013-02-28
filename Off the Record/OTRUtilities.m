//
//  OTRUtilities.m
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRUtilities.h"

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

@end


