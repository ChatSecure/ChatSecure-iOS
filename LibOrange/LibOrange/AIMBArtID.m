//
//  AIMBArtID.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBArtID.h"


@implementation AIMBArtID

@synthesize type;
@synthesize flags;
@synthesize length;
@synthesize opaqueData;

- (id)initWithType:(UInt16)aType flags:(UInt8)theFlags opaqueData:(NSData *)theData {
	if ((self = [super init])) {
		if ([theData length] > 255) {
			[super dealloc];
			return nil;
		}
		type = aType;
		flags = theFlags;
		length = (UInt8)[theData length];
		opaqueData = [theData copy];
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	const char * bytes = [data bytes];
	int _length = (int)[data length];
	if ((self = [self initWithPointer:bytes length:&_length])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if ((self = [super init])) {
		if (*_length < 4) {
			[super dealloc];
			return nil;
		}
		type = flipUInt16(*(const UInt16 *)ptr);
		flags = (UInt8)(ptr[2]);
		length = (UInt8)(ptr[3]);
		if (length + 4 > *_length) {
			[super dealloc];
			return nil;
		}
		opaqueData = [[NSData alloc] initWithBytes:&ptr[4] length:length];
		*_length = length + 4;
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 typeFlip = flipUInt16(type);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&typeFlip length:2];
	[encoded appendBytes:&flags length:1];
	[encoded appendBytes:&length length:1];
	[encoded appendData:opaqueData];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

- (BOOL)dataFlagIsSet {
	UInt8 dataFlagDat = flags & BART_FLAG_DATA;
	if (dataFlagDat != 0) return YES;
	else return NO;
}

- (BOOL)isEqualToBartID:(AIMBArtID *)anotherID {
	if ([self flags] != [anotherID flags]) return NO;
	if ([self type] != [anotherID type]) return NO;
	if (![[self opaqueData] isEqualToData:[anotherID opaqueData]]) return NO;
	return YES;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:type forKey:@"type"];
	[aCoder encodeInt:flags forKey:@"flags"];
	[aCoder encodeInt:length forKey:@"length"];
	[aCoder encodeObject:opaqueData forKey:@"opaqueData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		type = (UInt16)[aDecoder decodeIntForKey:@"type"];
		flags = (UInt8)[aDecoder decodeIntForKey:@"flags"];
		length = (UInt8)[aDecoder decodeIntForKey:@"length"];
		opaqueData = [[aDecoder decodeObjectForKey:@"opaqueData"] retain];
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMBArtID alloc] initWithData:[self encodePacket]];
}

#pragma mark Lists

+ (NSArray *)decodeArray:(NSData *)arrayData {
	NSMutableArray * decoded = [[NSMutableArray alloc] init];
	const char * bytes = [arrayData bytes];
	int length = (int)[arrayData length];
	while (length > 0) {
		int remLen = length;
		AIMBArtID * bid = [[AIMBArtID alloc] initWithPointer:bytes length:&remLen];
		if (!bid) break;
		length -= remLen;
		bytes = &bytes[remLen];
		[decoded addObject:bid];
		[bid release];
	}
	
	NSArray * immutable = [NSArray arrayWithArray:decoded];
	[decoded release];
	return immutable;
}

+ (NSData *)encodeArray:(NSArray *)array {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	for (AIMBArtID * bid in array) {
		[encoded appendData:[bid encodePacket]];
	}
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark Memory Management

- (void)dealloc {
	[opaqueData release];
	[super dealloc];
}

@end
