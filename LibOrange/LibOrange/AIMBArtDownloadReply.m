//
//  AIMBArtDownloadReply.m
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBArtDownloadReply.h"


@implementation AIMBArtDownloadReply

@synthesize username;
@synthesize replyInfo;
@synthesize dataLen;
@synthesize assetData;

- (id)initWithData:(NSData *)replyData {
	if ((self = [super init])) {
		if ([replyData length] < 12) {
			[super dealloc];
			return nil;
		}
		username = [decodeString8(replyData) retain];
		if (!username) {
			[super dealloc];
			return nil;
		}
		int usedLen = (int)[username length] + 1;
		if (usedLen + 11 > [replyData length]) {
			[username release];
			[super dealloc];
			return nil;
		}
		int len = (int)[replyData length] - usedLen;
		const char * repBytes = &((const char *)[replyData bytes])[usedLen];
		replyInfo = [[AIMBArtQueryReplyID alloc] initWithPointer:repBytes length:&len];
		if (!replyInfo) {
			[username release];
			[super dealloc];
			return nil;
		}
		usedLen += len;
		if (usedLen + 2 > [replyData length]) {
			[username release];
			[replyInfo release];
			[super dealloc];
			return nil;
		}
		dataLen = flipUInt16(*(const UInt16 *)(&repBytes[len]));
		usedLen += 2;
		if (usedLen + dataLen > [replyData length]) {
			[username release];
			[replyInfo release];
			[super dealloc];
			return nil;
		}
		assetData = [[NSData alloc] initWithBytes:&repBytes[len + 2] length:dataLen];
	}
	return self;
}

- (void)dealloc {
	[username release];
	[replyInfo release];
	[assetData release];
	[super dealloc];
}

@end
