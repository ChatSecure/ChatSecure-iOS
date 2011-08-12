//
//  AIMRateParamsChange.m
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateParamsChange.h"


@implementation AIMRateParamsChange

@synthesize rateParams;
@synthesize rateCode;

- (id)initWithSnac:(SNAC *)aSnac {
	if ((self = [super init])) {
		NSData * snacData = [aSnac innerContents];
		if ([snacData length] < 2) {
			[super dealloc];
			return nil;
		}
		rateCode = flipUInt16(*(const UInt16 *)[snacData bytes]);
		const char * bytes = &((const char *)[snacData bytes])[2];
		int length = (int)([snacData length] - 2);
		NSMutableArray * paramArray = [[NSMutableArray alloc] init];
		while (length > 2) {
			int remaining = length;
			AIMRateParams * params = [[AIMRateParams alloc] initWithPointer:bytes length:&remaining];
			if (!params) break;
			[paramArray addObject:[params autorelease]];
			length -= remaining;
			bytes = &bytes[remaining];
		}
		rateParams = [[NSArray alloc] initWithArray:paramArray];
		[paramArray release];
	}
	return self;
}

- (void)dealloc {
	[rateParams release];
	[super dealloc];
}

@end
