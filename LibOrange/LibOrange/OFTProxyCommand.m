//
//  OFTProxyCommand.m
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTProxyCommand.h"

@implementation OFTProxyCommand

@synthesize length;
@synthesize commandType;
@synthesize flags;
@synthesize commandData;

- (id)initWithCommandType:(UInt16)cmdType flags:(UInt16)theFlags cmdData:(NSData *)cmdData {
	if ((self = [super init])) {
		length = [cmdData length] + 10;
		commandType = cmdType;
		flags = theFlags;
		commandData = [cmdData retain];
	}
	return self;
}
- (id)initWithFileDescriptor:(int)fd {
	if ((self = [super init])) {
		char lengthBuff[2];
		if (!fdRead(fd, lengthBuff, 2)) {
			[super dealloc];
			return nil;
		}
		length = flipUInt16(*(const UInt16 *)lengthBuff);
		if (length < 10) {
			[super dealloc];
			return nil;
		}
		char * restOfData = (char *)malloc(length);
		if (!fdRead(fd, restOfData, length)) {
			free(restOfData);
			[super dealloc];
			return nil;
		}
		commandType = flipUInt16(*(const UInt16 *)(&restOfData[2]));
		flags = flipUInt16(*(const UInt16 *)(&restOfData[8]));
		commandData = [[NSData alloc] initWithBytes:&restOfData[10] length:(length - 10)];
		free(restOfData);
	}
	return self;
}
- (NSData *)encodePacket {
	UInt16 lenFlip = flipUInt16(length);
	UInt16 cmdTypeFlip = flipUInt16(commandType);
	UInt16 packetVerFlip = flipUInt16(0x044A);
	UInt16 flagsFlip = flipUInt16(flags);
	UInt32 unknown = 0;
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&lenFlip length:2];
	[encoded appendBytes:&packetVerFlip length:2];
	[encoded appendBytes:&cmdTypeFlip length:2];
	[encoded appendBytes:&unknown length:4];
	[encoded appendBytes:&flagsFlip length:2];
	[encoded appendData:commandData];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}
- (BOOL)writeToFileDescriptor:(int)fd {
	NSData * data = [self encodePacket];
	if (!data) return NO;
	int written = 0;
	const char * bytes = [data bytes];
	int toWrite = (int)[data length];
	while (written < toWrite) {
		int wrote = (int)write(fd, &bytes[written], toWrite - written);
		if (wrote <= 0) {
			return NO;
		}
		written += wrote;
	}
	return YES;
}

- (void)dealloc {
	[commandData release];
	[super dealloc];
}

@end
