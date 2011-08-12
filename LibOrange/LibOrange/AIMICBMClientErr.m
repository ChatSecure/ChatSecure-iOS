//
//  AIMICBMClientErr.m
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMClientErr.h"


@implementation AIMICBMClientErr

@synthesize cookie;
@synthesize channel;
@synthesize loginID;
@synthesize code;
@synthesize errorInfo;

- (id)initWithSNAC:(SNAC *)incomingSnac {
	if ((self = [super init])) {
		if ([[incomingSnac innerContents] length] < 13) {
			[super dealloc];
			return nil;
		}
		const char * bytes = (const char *)[incomingSnac.innerContents bytes];
		int length = (int)[[incomingSnac innerContents] length];
		cookie = [[AIMICBMCookie alloc] initWithCookieData:bytes];
		channel = flipUInt16(*(const UInt16 *)(&bytes[8]));
		UInt8 nickLen = *(const UInt8 *)(&bytes[10]);
		if (nickLen + 12 > length) {
			[cookie release];
			[super dealloc];
			return nil;
		}
		loginID = [[NSString alloc] initWithBytes:&bytes[11] length:nickLen encoding:NSASCIIStringEncoding];
		if (!loginID) {
			[cookie release];
			[super dealloc];
			return nil;
		}
		code = flipUInt16(*(const UInt16 *)(&bytes[11 + nickLen]));
		errorInfo = [[NSData alloc] initWithBytes:&bytes[11 + nickLen + 2] length:(length - (11 + nickLen + 2))];
	}
	return self;
}
- (SNAC *)encodeOutgoingSnac:(UInt32)reqID {
	NSData * loginIDData = [loginID dataUsingEncoding:NSASCIIStringEncoding];
	UInt8 nameLen = [loginIDData length];
	NSMutableData * data = [[NSMutableData alloc] init];
	[data appendData:[cookie cookieData]];
	[data appendNetworkOrderUInt16:channel];
	[data appendBytes:&nameLen length:1];
	[data appendData:loginIDData];
	[data appendNetworkOrderUInt16:code];
	if ([errorInfo length] > 0) [data appendData:errorInfo];
	
	NSData * immutable = [NSData dataWithData:data];
	[data release];
	return [[[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__CLIENT_ERR) flags:0 requestID:reqID data:immutable] autorelease];
}

- (void)dealloc {
	self.cookie = nil;
	self.loginID = nil;
	self.errorInfo = nil;
    [super dealloc];
}

@end
