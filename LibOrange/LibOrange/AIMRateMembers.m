//
//  AIMRateMembers.m
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateMembers.h"


@implementation AIMRateMembers

@synthesize classId;
@synthesize numMembers;
@synthesize rateMembers;

- (id)initWithData:(NSData *)data {
	const char * ptr = [data bytes];
	int length = (int)[data length];
	if ((self = [self initWithPointer:ptr length:&length])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 4) {
			[super dealloc];
			return nil;
		}
		classId = flipUInt16(*(const UInt16 *)(ptr));
		numMembers = flipUInt16(*(const UInt16 *)(&ptr[2]));
		if (4 + (numMembers * 4) > *length) {
			[super dealloc];
			return nil;
		}
		rateMembers = (SNAC_ID *)malloc(sizeof(SNAC_ID) * (numMembers + 1));
		for (int i = 0; i < (int)numMembers; i++) {
			const char * currentSnacData = &ptr[4 + (i * 4)];
			UInt16 foodgroup = flipUInt16(*(const UInt16 *)(currentSnacData));
			UInt16 smallType = flipUInt16(*(const UInt16 *)(&currentSnacData[2]));
			SNAC_ID snac;
			snac.foodgroup = foodgroup;
			snac.type = smallType;
			rateMembers[i] = snac;
		}
		*length = (4 + (4 * numMembers));
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 flipClassId = flipUInt16(classId);
	UInt16 flipNumMembers = flipUInt16(numMembers);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&flipClassId length:2];
	[encoded appendBytes:&flipNumMembers length:2];
	for (int i = 0; i < (int)numMembers; i++) {
		SNAC_ID snac = rateMembers[i];
		UInt16 flipFoodgroup = flipUInt16(snac.foodgroup);
		UInt16 flipType = flipUInt16(snac.type);
		[encoded appendBytes:&flipFoodgroup length:2];
		[encoded appendBytes:&flipType length:2];
	}
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMRateMembers allocWithZone:zone] initWithData:[self encodePacket]];
}

- (id)copy {
	return [[AIMRateMembers alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"packetData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"packetData"]])) {
		
	}
	return self;
}

- (void)dealloc {
	free(rateMembers);
	[super dealloc];
}

@end
