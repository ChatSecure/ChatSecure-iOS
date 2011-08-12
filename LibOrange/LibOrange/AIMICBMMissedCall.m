//
//  AIMICBMMissedCall.m
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMMissedCall.h"


@implementation AIMICBMMissedCall

@synthesize channel;
@synthesize senderInfo;
@synthesize numMissed;
@synthesize reason;

- (id)initWithData:(NSData *)data {
	const char * ptr = [data bytes];
	int len = (int)[data length];
	if ((self = [self initWithPointer:ptr length:&len])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 6) {
			[super dealloc];
			return nil;
		}
		channel = flipUInt16(*(const UInt16 *)ptr);
		int len = *length - 2;
		const char * nickPtr = &ptr[2];
		senderInfo = [[AIMNickWInfo alloc] initWithPointer:nickPtr length:&len];
		if (*length - (len + 2) < 4 || !senderInfo) {
			[super dealloc];
			return nil;
		}
		const char * remaining = &ptr[2 + len];
		numMissed = flipUInt16(*(const UInt16 *)remaining);
		reason = flipUInt16(((const UInt16 *)remaining)[1]);
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 numMissedFlip = flipUInt16(numMissed);
	UInt16 reasonFlip = flipUInt16(reason);
	UInt16 channelFlip = flipUInt16(channel);
	
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&channelFlip length:2];
	[encoded appendData:[senderInfo encodePacket]];
	[encoded appendBytes:&numMissedFlip length:2];
	[encoded appendBytes:&reasonFlip length:2];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

+ (NSArray *)decodeArray:(NSData *)listData {
	NSMutableArray * missedCalls = [NSMutableArray array];
	int len = (int)[listData length];
	const char * bytes = (const char *)[listData bytes];
	while (len > 0) {
		int used = len;
		AIMICBMMissedCall * missed = [[AIMICBMMissedCall alloc] initWithPointer:bytes length:&used];
		if (!missed) break;
		[missedCalls addObject:missed];
		[missed release];
		len -= used;
		bytes = &bytes[used];
	}
	return missedCalls;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"missedcallData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"missedcallData"]])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMICBMMissedCall allocWithZone:zone] initWithData:[self encodePacket]];
}

- (void)dealloc {
	[senderInfo release];
	[super dealloc];
}

@end
