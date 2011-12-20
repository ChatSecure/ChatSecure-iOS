//
//  SNAC.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SNAC.h"

SNAC_ID SNAC_ID_NEW (UInt16 foodgroup, UInt16 type) {
	SNAC_ID sid;
	sid.foodgroup = foodgroup;
	sid.type = type;
	return sid;
}
SNAC_ID SNAC_ID_FLIP (SNAC_ID sid) {
	SNAC_ID flipped;
	flipped.foodgroup = flipUInt16(sid.foodgroup);
	flipped.type = flipUInt16(sid.type);
	return flipped;
}
BOOL SNAC_ID_IS_EQUAL (SNAC_ID sid, SNAC_ID sid1) {
	if (sid.foodgroup == sid1.foodgroup && sid.type == sid1.type) return YES;
	return NO;
}
UInt32 SNAC_ID_ENCODE (SNAC_ID sid) {
	SNAC_ID flipped = SNAC_ID_FLIP(sid);
	UInt32 encoded = 0;
	char * buffer = (char *)&encoded;
	memcpy(buffer, &flipped.foodgroup, 2);
	memcpy(&buffer[2], &flipped.type, 2);
	return encoded;
}
SNAC_ID SNAC_ID_DECODE (UInt32 buf) {
	const char * buffer = (const char *)&buf;
	SNAC_ID sid;
	memcpy(&sid.foodgroup, buffer, 2);
	memcpy(&sid.type, &buffer[2], 2);
	return sid;
}

@implementation SNAC

@synthesize snac_id;
@synthesize snac_flags;
@synthesize requestID;
@synthesize data;

- (id)initWithData:(NSData *)_data {
	int length = (int)[_data length];
	self = [self initWithPointer:[_data bytes]
						  length:&length];
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	// *length will not be changed, because we will use
	// the entire buffer to fill our snac.
	if ((self = [super init])) {
		innerContents = nil;
		if (*length < 10) {
			[super dealloc];
			return nil;
		}
		snac_id.foodgroup = flipUInt16(*(UInt16 *)ptr);
		snac_id.type = flipUInt16(((UInt16 *)ptr)[1]);
		flags = flipUInt16(((UInt16 *)ptr)[2]);
		requestID = flipUInt32(*(UInt32 *)(&ptr[6]));
		data = [[NSData alloc] initWithBytes:&ptr[10]
									  length:(*length - 10)];
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt32 fID = SNAC_ID_ENCODE(snac_id);
	UInt16 fFlags = [self flippedFlags];
	UInt32 fRequestID = [self flippedRequestID];
	[encoded appendBytes:&fID length:4];
	[encoded appendBytes:&fFlags length:2];
	[encoded appendBytes:&fRequestID length:4];
	[encoded appendData:data];
	
	// create an immutable copy of encoded
	NSData * immutableSnac = [NSData dataWithData:encoded];
	[encoded release];
	return immutableSnac;
}

- (id)initWithID:(SNAC_ID)_id flags:(UInt16)_flags requestID:(UInt32)reqID data:(NSData *)_data {
	if ((self = [super init])) {
		innerContents = nil;
		snac_id = _id;
		snac_flags = _flags;
		requestID = reqID;
		data = [_data retain];
	}
	return self;
}

- (UInt16)flippedFlags {
	return flipUInt16(flags);
}
- (UInt32)flippedRequestID {
	return flipUInt32(requestID);
}

// removes a possible TLVlBlock, this should always bee used,
// rather than accessing the data property.
- (NSData *)innerContents {
	if (innerContents) return innerContents;
	// check if there is a TLVlBlock blocking our way,
	// no pun intended.
	UInt16 containsTLV = flags & SNAC_FLAG_OPT_TLV_PRESENT;
	if (containsTLV != 0) {
		// we could get the length easily, but instead
		// we are using the TLV class.
		const char * bytes = [data bytes];
		int length = (int)[data length];
		NSArray * theData = [TLV decodeTLVLBlock:bytes length:&length];
		NSAssert(theData != nil, @"A SNAC came in claiming to have a TLVlBlock header, but it didn't");
		int contentsLength = (int)[data length] - length;
		innerContents = [[NSData alloc] initWithBytes:&bytes[length] length:contentsLength];
		return innerContents;
	} else {
		innerContents = [data retain];
		return data;
	}
}

- (BOOL)isLastResponse {
	UInt16 areMore = flags & SNAC_FLAG_MORE_REPLIES_FOLLOW;
	if (areMore != 0) return NO;
	return YES;
}

#pragma mark NSCopying

- (SNAC *)copyWithZone:(NSZone *)zone {
	return [[SNAC allocWithZone:zone] initWithData:[self encodePacket]];
}

- (SNAC *)copy {
	return [[SNAC alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	NSData * encodedData = [aDecoder decodeDataObject];
	self = [self initWithData:encodedData];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeDataObject:[self encodePacket]];
}

- (void)dealloc {
	[data release];
	[innerContents release];
	[super dealloc];
}

@end
