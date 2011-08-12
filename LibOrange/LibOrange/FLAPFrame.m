//
//  FLAPFrame.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FLAPFrame.h"


@implementation FLAPFrame

@synthesize identifier;
@synthesize channel;
@synthesize sequenceNumber;
@synthesize frameData;

// creates a packet with data.
- (id)initWithData:(NSData *)data {
	int length = (int)[data length];
	const char * bytes = (const char *)[data bytes];
	self = [self initWithPointer:bytes length:&length];
	return self;
}

// creates a packet with data at an address.
// returns length in *length of the amount
// of bytes it used.
- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 6) {
			[super dealloc];
			return nil;
		}
		
		identifier = ptr[0];
		if (identifier != '*') {
			[super dealloc];
			return nil;
		}
		
		channel = ptr[1];
		
		// second UInt16 of the data contains
		// the sequence number.
		sequenceNumber = flipUInt16(((UInt16 *)ptr)[1]);
		
		// the data length, third UInt16 in the data.
		UInt16 dataLength = flipUInt16(((UInt16 *)ptr)[2]);
		
		if (dataLength + 6 > *length) {
			[super dealloc];
			return nil;
		}
		
		frameData = [[NSData alloc] initWithBytes:&ptr[6]
										   length:dataLength];
		
		*length = dataLength + 6;
	}
	return self;
}

// encodes the packet, this should work so that
// [initWithData:[self encodePacket]] returns
// a replica of the data provided.
- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt16 fSequenceNumber = [self flippedSequenceNumber];
	UInt16 fLength = [self flippedFrameLength];
	[encoded appendBytes:&identifier length:1];
	[encoded appendBytes:&channel length:1];
	[encoded appendBytes:&fSequenceNumber length:2];
	[encoded appendBytes:&fLength length:2];
	[encoded appendData:frameData];
	
	// create an immutable object.
	NSData * immutableData = [NSData dataWithData:encoded];
	[encoded release];
	return immutableData;
}

- (id)initWithChannel:(UInt8)_channel sequenceNumber:(UInt16)_sequenceNumber data:(NSData *)_frameData {
	if ((self = [super init])) {
		identifier = '*';
		channel = _channel;
		sequenceNumber = _sequenceNumber;
		frameData = [_frameData retain];
	}
	return self;
}

- (UInt16)flippedSequenceNumber {
	return flipUInt16(sequenceNumber);
}
- (UInt16)flippedFrameLength {
	return flipUInt16([frameData length]);
}

#pragma mark NSCopying

- (FLAPFrame *)copyWithZone:(NSZone *)zone {
	return [[FLAPFrame allocWithZone:zone] initWithData:[self encodePacket]];
}

- (FLAPFrame *)copy {
	return [[FLAPFrame alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoder

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		identifier = [aDecoder decodeIntForKey:@"identifier"];
		channel = [aDecoder decodeIntForKey:@"channel"];
		sequenceNumber = [aDecoder decodeIntForKey:@"sequence"];
		// we create a copy of this that we own, just in the case
		// that NSCoder does some funky stuff, which I hope it doesn't.
		frameData = [[aDecoder decodeObjectForKey:@"frameData"] copy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:identifier forKey:@"identifier"];
	[aCoder encodeInt:channel forKey:@"channel"];
	[aCoder encodeInt:sequenceNumber forKey:@"sequence"];
	[aCoder encodeObject:frameData forKey:@"frameData"];
}

- (void)dealloc {
	self.frameData = nil;
	[super dealloc];
}

@end
