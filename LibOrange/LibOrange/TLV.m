//
//  TLV.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TLV.h"


@implementation TLV

@synthesize type;
@synthesize tlvData;

- (id)initWithData:(NSData *)data {
	int length = (int)[data length];
	const char * bytes = (const char *)[data bytes];
	[self initWithPointer:bytes length:&length];
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 4) {
			[super dealloc];
			return nil;
		}
		type = flipUInt16(*(UInt16 *)ptr);
		UInt16 following = flipUInt16(((UInt16 *)ptr)[1]);
		if (following + 4 > *length) {
			[super dealloc];
			return nil;
		}
		
		tlvData = [[NSData alloc] initWithBytes:&ptr[4]
										 length:following];
		
		*length = 4 + following;
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt16 fType = [self flippedType];
	UInt16 fLength = [self flippedLength];
	[encoded appendBytes:&fType length:2];
	[encoded appendBytes:&fLength length:2];
	[encoded appendData:tlvData];
	
	// create an immutable version of the data.
	NSData * immutableData = [NSData dataWithData:encoded];
	[encoded release];
	return immutableData;
}

- (id)initWithType:(UInt16)_type data:(NSData *)_tlvData {
	if ((self = [super init])) {
		type = _type;
		tlvData = [_tlvData retain];
	}
	return self;
}

- (UInt16)flippedType {
	return flipUInt16(type);
}
- (UInt16)flippedLength {
	return flipUInt16([tlvData length]);
}

#pragma mark Arrays

// decode a plain array, no start.
+ (NSArray *)decodeTLVArray:(NSData *)arrayData {
	int length = (int)[arrayData length];
	int index = 0;
	const char * bytes = [arrayData bytes];
	NSMutableArray * array = [[NSMutableArray alloc] init];
	while (length > 0) {
		int remaining = length;
		TLV * tlv = [[TLV alloc] initWithPointer:&bytes[index]
										  length:&remaining];
		if (!tlv) break;
		index += remaining;
		length -= remaining;
		[array addObject:tlv];
		[tlv release];
	}
	
	// create an immutable version
	NSArray * immutableList = [NSArray arrayWithArray:array];
	[array release];
	return immutableList;
}

+ (NSData *)encodeTLVArray:(NSArray *)array {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	for (TLV * t in array) {
		[encoded appendData:[t encodePacket]];
	}
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

// decode a UInt16 (count) followed by that many elements.
+ (NSArray *)decodeTLVBlock:(const char *)ptr length:(int *)length {
	if (*length < 2) return nil;
	UInt16 elementCount = flipUInt16(*(UInt16 *)ptr);
	if (4 * elementCount + 2 > *length) {
		// there is not enough room for that many
		// tlv headers.
		return nil;
	}
	
	const char * currentAddress = &ptr[2];
	int currentLength = *length - 2;
	int totalUsed = 0;
	NSMutableArray * elements = [[NSMutableArray alloc] init];
	
	for (int i = 0; i < elementCount; i++) {
		if (currentLength < 4) {
			[elements release];
			return nil;
		}
		
		// will become the bytes used after the init method.
		int bytesUsed = currentLength;
		TLV * nextPacket = [[TLV alloc] initWithPointer:currentAddress length:&bytesUsed];
		if (!nextPacket) {
			[elements release];
			return nil;
		}
		
		[elements addObject:nextPacket];
		[nextPacket release];
		
		currentLength -= bytesUsed;
		totalUsed += bytesUsed;
		currentAddress = &currentAddress[bytesUsed];
	}
	
	if ([elements count] < elementCount) {
		// unmatching element count.
		[elements release];
		return nil;
	}
	
	*length = totalUsed + 2;
	
	// creat an immutable version.
	NSArray * immutableObjects = [NSArray arrayWithArray:elements];
	[elements release];
	return immutableObjects;
}

// decode a UInt16 (length) followed by that many bytes of elements.
+ (NSArray *)decodeTLVLBlock:(const char *)ptr length:(int *)length {
	if (*length < 2) return nil;
	UInt16 totalLength = flipUInt16(*(UInt16 *)ptr);
	if (totalLength + 2 > *length) {
		// there is not enough room for that many
		// tlv headers.
		return nil;
	}
	
	const char * currentAddress = &ptr[2];
	int currentLength = totalLength;
	NSMutableArray * elements = [[NSMutableArray alloc] init];
	
	while (currentLength > 0) {
		if (currentLength < 4) {
			[elements release];
			return nil;
		}
		
		// will become the bytes used after the init method.
		int bytesUsed = currentLength;
		TLV * nextPacket = [[TLV alloc] initWithPointer:currentAddress length:&bytesUsed];
		if (!nextPacket) {
			[elements release];
			return nil;
		}
		
		[elements addObject:nextPacket];
		[nextPacket release];
		
		currentLength -= bytesUsed;
		currentAddress = &currentAddress[bytesUsed];
		
		if (currentLength >= totalLength) break;
	}
	
	*length = totalLength + 2;
	
	// creat an immutable version.
	NSArray * immutableObjects = [NSArray arrayWithArray:elements];
	[elements release];
	return immutableObjects;
}

// encode TLVBlock (count + data)
+ (NSData *)encodeTLVBlock:(NSArray *)tlvs {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt16 countFlip = flipUInt16([tlvs count]);
	[encoded appendBytes:&countFlip length:2];
	for (int i = 0; i < [tlvs count]; i++) {
		TLV * packet = [tlvs objectAtIndex:i];
		[encoded appendData:[packet encodePacket]];
	}
	
	// create immutable data.
	NSData * immutableData = [NSData dataWithData:encoded];
	[encoded release];
	return immutableData;
}

// encode TLVLBlock (length + data)
+ (NSData *)encodeTLVLBlock:(NSArray *)tlvs {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	// we will make two bytes of space in the data.
	UInt16 lengthBlock = 0;
	[encoded appendBytes:&lengthBlock length:2];
	for (int i = 0; i < [tlvs count]; i++) {
		TLV * packet = [tlvs objectAtIndex:i];
		[encoded appendData:[packet encodePacket]];
	}
	
	lengthBlock = flipUInt16([encoded length] - 2);
	[encoded replaceBytesInRange:NSMakeRange(0, 2)
					   withBytes:&lengthBlock];
	
	// create immutable data.
	NSData * immutableData = [NSData dataWithData:encoded];
	[encoded release];
	return immutableData;
}

- (id)description {
	return [NSString stringWithFormat:@"TLV %d", type];
}

#pragma mark NSCopying

- (TLV *)copyWithZone:(NSZone *)zone {
	return [[TLV allocWithZone:zone] initWithData:[self encodePacket]];
}

- (TLV *)copy {
	return [[TLV alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		type = [aDecoder decodeIntForKey:@"type"];
		tlvData = [aDecoder decodeObjectForKey:@"data"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:type forKey:@"type"];
	[aCoder encodeObject:tlvData forKey:@"data"];
}

- (void)dealloc {
	self.tlvData = nil;
	[super dealloc];
}

@end
