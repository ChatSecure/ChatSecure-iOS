//
//  AIMRateParamsReply.m
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateParamsReply.h"


@implementation AIMRateParamsReply

@synthesize numClasses;
@synthesize rateParameters;
@synthesize rateMembers;

- (id)initWithData:(NSData *)replyData {
	if ((self = [super init])) {
		if ([replyData length] < 2) {
			[super dealloc];
			return nil;
		}
		const char * bytes = [replyData bytes];
		numClasses = flipUInt16(*(const UInt16 *)bytes);
		NSMutableArray * rateParamsM = [NSMutableArray array];
		NSMutableArray * rateMembersM = [NSMutableArray array];
		const char * startBytes = &bytes[2];
		int lengthRem = (int)([replyData length] - 2);
		for (int i = 0; i < numClasses; i++) {
			int len = lengthRem;
			AIMRateParams * params = [[AIMRateParams alloc] initWithPointer:startBytes length:&len];
			if (!params) {
				[super dealloc];
				return nil;
			}
			startBytes = &startBytes[len];
			lengthRem -= len;
			[rateParamsM addObject:params];
			[params release];
		}
		for (int i = 0; i < numClasses; i++) {
			int len = lengthRem;
			AIMRateMembers * members = [[AIMRateMembers alloc] initWithPointer:startBytes length:&len];
			if (!members) {
				[super dealloc];
				return nil;
			}
			startBytes = &startBytes[len];
			lengthRem -= len;
			[rateMembersM addObject:members];
			[members release];
		}
		rateParameters = [rateParamsM retain];
		rateMembers = [rateMembersM retain];
	}
	return self;
}

- (void)dealloc {
	[rateParameters release];
	[rateMembers release];
	[super dealloc];
}

@end
