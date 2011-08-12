//
//  AIMRateParams.m
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateParams.h"


@implementation AIMRateParams

@synthesize classId;
@synthesize windowSize;
@synthesize clearThreshold;
@synthesize alertThreshold;
@synthesize limitThreshold;
@synthesize disconnectThreshold;
@synthesize currentAverage;
@synthesize maxAverage;
@synthesize lastArrivalDelta;
@synthesize droppingSNACs;

- (id)initWithData:(NSData *)data {
	const char * ptr = [data bytes];
	int length = (int)[data length];
	if ((self = [self initWithPointer:ptr length:&length])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 35) {
			[super dealloc];
			return nil;
		}
		const UInt32 * fieldArray = (const UInt32 *)&ptr[2];
		classId = flipUInt16(*(const UInt16 *)ptr);
		windowSize = flipUInt32(fieldArray[0]);
		clearThreshold = flipUInt32(fieldArray[1]);
		alertThreshold = flipUInt32(fieldArray[2]);
		limitThreshold = flipUInt32(fieldArray[3]);
		disconnectThreshold = flipUInt32(fieldArray[4]);
		currentAverage = flipUInt32(fieldArray[5]);
		maxAverage = flipUInt32(fieldArray[6]);
		// lastArrivalDelta = flipUInt32(fieldArray[7]);
		// droppingSNACs = (UInt8)(ptr[34]);
		*length = 30;
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 flipClassId = flipUInt16(classId);
	UInt32 flipWindowSize = flipUInt32(windowSize);
	UInt32 flipClearThreshold = flipUInt32(clearThreshold);
	UInt32 flipAlertThreshold = flipUInt32(alertThreshold);
	UInt32 flipLimitThreshold = flipUInt32(limitThreshold);
	UInt32 flipDisconnectThreshold = flipUInt32(disconnectThreshold);
	UInt32 flipCurrentAverage = flipUInt32(currentAverage);
	UInt32 flipMaxAverage = flipUInt32(maxAverage);
	// UInt32 flipLastArrivalDelta = flipUInt32(lastArrivalDelta);
	
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&flipClassId length:2];
	[encoded appendBytes:&flipWindowSize length:4];
	[encoded appendBytes:&flipClearThreshold length:4];
	[encoded appendBytes:&flipAlertThreshold length:4];
	[encoded appendBytes:&flipLimitThreshold length:4];
	[encoded appendBytes:&flipDisconnectThreshold length:4];
	[encoded appendBytes:&flipCurrentAverage length:4];
	[encoded appendBytes:&flipMaxAverage length:4];
	// [encoded appendBytes:&flipLastArrivalDelta length:4];
	// [encoded appendBytes:&droppingSNACs length:1];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"packetData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"packetData"]])) {
		// wee
	}
	return self;
}

#pragma mark NSCopying

- (AIMRateParams *)copyWithZone:(NSZone *)z {
	return [[AIMRateParams allocWithZone:z] initWithData:[self encodePacket]];
}

- (id)copy {
	return [[AIMRateParams alloc] initWithData:[self encodePacket]];
}

@end
