//
//  AIMFeedbagStatus.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagStatus.h"


@implementation AIMFeedbagStatus

- (id)initWithCodeData:(NSData *)statusCodes {
	if ((self = [super init])) {
		if ([statusCodes length] % 2 != 0) {
			[super dealloc];
			return nil;
		}
		NSMutableArray * codes = [[NSMutableArray alloc] init];
		const UInt16 * nums = [statusCodes bytes];
		int numNums = (int)[statusCodes length] / 2;
		for (int i = 0; i < numNums; i++) {
			UInt16 num = flipUInt16(nums[i]); 
			// TODO: validate as an actual enum value.
			[codes addObject:[NSNumber numberWithUnsignedShort:num]];
		}
		statTypeVals = [[NSArray alloc] initWithArray:codes];
		[codes release];
	}
	return self;
}
- (NSUInteger)statusCodeCount {
	return [statTypeVals count];
}
- (AIMFeedbagStatusType)statusAtIndex:(NSUInteger)index {
	return (AIMFeedbagStatusType)[[statTypeVals objectAtIndex:index] unsignedShortValue];
}
- (void)dealloc {
	[statTypeVals release];
	[super dealloc];
}

@end
