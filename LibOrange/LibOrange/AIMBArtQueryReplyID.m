//
//  AIMBArtQueryReplyID.m
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBArtQueryReplyID.h"


@implementation AIMBArtQueryReplyID

@synthesize initialID;
@synthesize replyCode;
@synthesize usedID;

- (id)initWithData:(NSData *)data {
	int len = (int)[data length];
	if ((self = [self initWithPointer:[data bytes] length:&len])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 9) {
			[super dealloc];
			return nil;
		}
		int used = *length;
		initialID = [[AIMBArtID alloc] initWithPointer:ptr length:&used];
		if (!initialID) {
			[super dealloc];
			return nil;
		}
		if (used + 5 > *length) {
			[initialID release];
			[super dealloc];
			return nil;
		}
		replyCode = *(const UInt8 *)(&ptr[used]);
		const char * newBytes = &ptr[used + 1];
		int newLen = *length - (used + 1);
		usedID = [[AIMBArtID alloc] initWithPointer:newBytes length:&newLen];
		if (!usedID) {
			[initialID release];
			[super dealloc];
			return nil;
		}
		*length = newLen + 1 + used;
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendData:[initialID encodePacket]];
	[encoded appendBytes:&replyCode length:1];
	[encoded appendData:[usedID encodePacket]];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"encoded"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"encoded"]])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMBArtQueryReplyID alloc] initWithData:[self encodePacket]];
}

- (void)dealloc {
	[initialID release];
	[usedID release];
	[super dealloc];
}

@end
