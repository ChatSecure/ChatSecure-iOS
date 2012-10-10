//
//  AIMICBMMessageToServer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMMessageToServer.h"


@implementation AIMICBMMessageToServer

@synthesize channel;
@synthesize cookie;
@synthesize loginID;
@synthesize icbmTlvs;

- (id)initWithMessage:(NSString *)msg toUser:(NSString *)user isAutoreply:(BOOL)isAutorep {
	if ((self = [super init])) {
		channel = 1;
		self.cookie = [AIMICBMCookie randomCookie];
		self.loginID = user;
		
		NSData * asciiData = [msg dataUsingEncoding:NSASCIIStringEncoding];
		NSData * unicodeData = [msg dataUsingEncoding:NSUTF16BigEndianStringEncoding];
		if (!asciiData && !unicodeData) {
			NSLog(@"Failed to encode message: %@", msg);
			// send the other user a little surprise.
			asciiData = [@"Failed to encode message" dataUsingEncoding:NSASCIIStringEncoding];
		}
		
		NSMutableData * imTextData = [[NSMutableData alloc] init];
		UInt16 encoding = (asciiData != nil) ? 0 : flipUInt16(2);
		UInt16 language = 0;
		[imTextData appendBytes:&encoding length:2];
		[imTextData appendBytes:&language length:2];
		[imTextData appendData:(asciiData != nil ? asciiData : unicodeData)];
		UInt8 caps = 1;
		
		TLV * capabilities = [[TLV alloc] initWithType:TLV_ICBM__IM_DATA_TAGS_IM_CAPABILITIES data:[NSData dataWithBytes:&caps length:1]];
		TLV * imText = [[TLV alloc] initWithType:TLV_ICBM__IM_DATA_TAGS_IM_TEXT data:imTextData];
		[imTextData release];
		
		NSMutableData * imDataBytes = [[NSMutableData alloc] init];
		[imDataBytes appendData:[capabilities encodePacket]];
		[imDataBytes appendData:[imText encodePacket]];
		TLV * imData = [[TLV alloc] initWithType:TLV_ICBM__TAGS_IM_DATA data:imDataBytes];
		[imDataBytes release];
		[imText release];
		[capabilities release];
		
		if (isAutorep) {
			TLV * autoresp = [[TLV alloc] initWithType:TLV_ICBM__TAGS_AUTO_RESPONSE data:nil];
			self.icbmTlvs = [NSArray arrayWithObjects:imData, autoresp, nil];
			[autoresp release];
		} else {
			TLV * store = [[TLV alloc] initWithType:TLV_ICBM__TAGS_STORE data:nil];
			self.icbmTlvs = [NSArray arrayWithObjects:imData, store, nil];
			[store release];
		}
		[imData release];
	}
	return self;
}
- (id)initWithRVData:(NSData *)rvData toUser:(NSString *)user cookie:(AIMICBMCookie *)theCookie {
	if ((self = [super init])) {
		self.cookie = theCookie;
		self.channel = 2;
		self.loginID = user;
		TLV * data = [[TLV alloc] initWithType:TLV_RV_DATA data:rvData];
		self.icbmTlvs = [NSArray arrayWithObject:data];
		[data release];
	}
	return self;
}
- (id)initWithRVDataInitProp:(NSData *)rvData toUser:(NSString *)user cookie:(AIMICBMCookie *)theCookie {
	if ((self = [super init])) {
		self.cookie = theCookie;
		self.channel = 2;
		self.loginID = user;
		TLV * data = [[TLV alloc] initWithType:TLV_RV_DATA data:rvData];
		TLV * hostAck = [[TLV alloc] initWithType:TLV_ICBM__TAGS_REQUEST_HOST_ACK data:[NSData data]];
		self.icbmTlvs = [NSArray arrayWithObjects:data, hostAck, nil];
		[hostAck release];
		[data release];
	}
	return self;
}
- (NSData *)encodePacket {
	UInt16 channelFlip = flipUInt16(channel);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendData:[cookie cookieData]];
	[encoded appendBytes:&channelFlip length:2];
	[encoded appendData:encodeString8(loginID)];
	[encoded appendData:[TLV encodeTLVArray:icbmTlvs]];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

- (void)dealloc {
	self.icbmTlvs = nil;
	self.loginID = nil;
	self.cookie = nil;
	[super dealloc];
}

@end
