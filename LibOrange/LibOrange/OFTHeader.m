//
//  OFTHeader.m
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define GOODBYE { [self dealloc]; return nil; }

#import "OFTHeader.h"

@implementation OFTHeader

@synthesize protocolVersion;
@synthesize length;
@synthesize type;
@synthesize cookie;
@synthesize encrypt;
@synthesize compress;
@synthesize totalFiles;
@synthesize filesLeft;
@synthesize totalParts;
@synthesize partsLeft;
@synthesize totalSize;
@synthesize size;
@synthesize modTime;
@synthesize checkSum;
@synthesize recvResourceForkCheckSum;
@synthesize resourceForkSize;
@synthesize creTime;
@synthesize resourceForkChecksum;
@synthesize bytesReceived;
@synthesize receivedChecksum;
@synthesize idString;
@synthesize flags;
@synthesize nameOff;
@synthesize sizeOff;
@synthesize dummy;
@synthesize macFileInf;
@synthesize encoding;
@synthesize subcode;
@synthesize fileName;

- (id)init {
	if ((self = [super init])) {
		char dummyBuffer[69];
		bzero(dummyBuffer, 69);
		protocolVersion = kProtoVer;
		length = 256;
		type = 0;
		cookie = [[NSData alloc] initWithBytes:&dummyBuffer length:8];
		checkSum = 0xFFFF0000;
		recvResourceForkCheckSum = 0;
		resourceForkChecksum = 0xFFFF0000;
		receivedChecksum = 0;
		idString = [[NSString alloc] initWithString:kIDString];
		dummy = [[NSData alloc] initWithBytes:dummyBuffer length:69];
		macFileInf = [[NSData alloc] initWithBytes:dummyBuffer length:16];
		fileName = [[NSString alloc] initWithString:@""];
		nameOff = kNameOffset;
		sizeOff = kSizeOffset;
	}
	return self;
}

- (id)initByReadingFD:(int)fileDesc {
	if ((self = [super init])) {
		char cookieBytes[8];
		char idStringBuffer[33];
		char dummyBuffer[69];
		char macFileInfD[16];
		if (!fdReadUInt32(fileDesc, &protocolVersion)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &length)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &type)) GOODBYE;
		if (!fdRead(fileDesc, cookieBytes, 8)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &encrypt)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &compress)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &totalFiles)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &filesLeft)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &totalParts)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &partsLeft)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &totalSize)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &size)) GOODBYE; // how many bytes have been sent?
		if (!fdReadUInt32(fileDesc, &modTime)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &checkSum)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &recvResourceForkCheckSum)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &resourceForkSize)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &creTime)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &resourceForkChecksum)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &bytesReceived)) GOODBYE;
		if (!fdReadUInt32(fileDesc, &receivedChecksum)) GOODBYE;
		if (!fdRead(fileDesc, idStringBuffer, 32)) GOODBYE;
		if (!fdRead(fileDesc, (char *)&flags, 1)) GOODBYE;
		if (!fdRead(fileDesc, (char *)&nameOff, 1)) GOODBYE;
		if (!fdRead(fileDesc, (char *)&sizeOff, 1)) GOODBYE;
		if (!fdRead(fileDesc, dummyBuffer, 69)) GOODBYE;
		if (!fdRead(fileDesc, macFileInfD, 16)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &encoding)) GOODBYE;
		if (!fdReadUInt16(fileDesc, &subcode)) GOODBYE;
		// how much do we have to read?
		char * nameBuffer = (char *)malloc(length - 191);
		bzero(nameBuffer, (length - 191));
		if (!fdRead(fileDesc, nameBuffer, (length - 192))) {
			free(nameBuffer);
			[self dealloc];
			return nil;
		}
		idStringBuffer[32] = 0;
		cookie = [[NSData alloc] initWithBytes:cookieBytes length:8];
		idString = [[NSString alloc] initWithUTF8String:idStringBuffer];
		dummy = [[NSData alloc] initWithBytes:dummyBuffer length:69];
		macFileInf = [[NSData alloc] initWithBytes:macFileInfD length:16];
		fileName = [[NSString alloc] initWithUTF8String:nameBuffer];
		free(nameBuffer);
		if (!cookie || !idString || !dummy || !macFileInf || !fileName) {
			[self dealloc];
			return nil;
		}
	}
	return self;
}

- (NSData *)encodePacket {
	if ([fileName length] < 64) {
		length = 256;
	} else {
		length = 192 + ([fileName length] + 1);
	}
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendNetworkOrderUInt32:protocolVersion];
	[encoded appendNetworkOrderUInt16:length];
	[encoded appendNetworkOrderUInt16:type];
	[encoded appendData:cookie];
	[encoded appendNetworkOrderUInt16:encrypt];
	[encoded appendNetworkOrderUInt16:compress];
	[encoded appendNetworkOrderUInt16:totalFiles];
	[encoded appendNetworkOrderUInt16:filesLeft];
	[encoded appendNetworkOrderUInt16:totalParts];
	[encoded appendNetworkOrderUInt16:partsLeft];
	[encoded appendNetworkOrderUInt32:totalSize];
	[encoded appendNetworkOrderUInt32:size];
	[encoded appendNetworkOrderUInt32:modTime];
	[encoded appendNetworkOrderUInt32:checkSum];
	[encoded appendNetworkOrderUInt32:recvResourceForkCheckSum];
	[encoded appendNetworkOrderUInt32:resourceForkSize];
	[encoded appendNetworkOrderUInt32:creTime];
	[encoded appendNetworkOrderUInt32:resourceForkChecksum];
	[encoded appendNetworkOrderUInt32:bytesReceived];
	[encoded appendNetworkOrderUInt32:receivedChecksum];
	[encoded appendString:idString paddToLen:32];
	[encoded appendBytes:&flags length:1];
	[encoded appendBytes:&nameOff length:1];
	[encoded appendBytes:&sizeOff length:1];
	[encoded appendData:dummy];
	[encoded appendData:macFileInf];
	[encoded appendNetworkOrderUInt16:encoding];
	[encoded appendNetworkOrderUInt16:subcode];
	if ([fileName length] < 64) {
		[encoded appendString:fileName paddToLen:64];
	} else {
		// null terminate.
		[encoded appendString:fileName paddToLen:(int)([fileName length]+1)];
	}
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

- (BOOL)writeFileFD:(int)fileDesc {
	NSData * data = [self encodePacket];
	if (!data) return NO;
	int written = 0;
	const char * bytes = [data bytes];
	int toWrite = (int)[data length];
	while (written < toWrite) {
		int wrote = (int)write(fileDesc, &bytes[written], toWrite - written);
		if (wrote <= 0) {
			return NO;
		}
		written += wrote;
	}
	return YES;
}

- (void)dealloc {
	[dummy release];
	[macFileInf release];
	[fileName release];
	[idString release];
	[cookie release];
	[super dealloc];
}

@end
