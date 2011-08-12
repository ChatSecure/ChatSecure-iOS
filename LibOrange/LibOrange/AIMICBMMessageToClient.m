//
//  AIMICBMMessageToClient.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMMessageToClient.h"


@implementation AIMICBMMessageToClient

@synthesize cookie;
@synthesize channel;
@synthesize nickInfo;
@synthesize icbmTlvs;

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 10) {
			[super dealloc];
			return nil;
		}
		cookie = [[AIMICBMCookie alloc] initWithCookieData:ptr];
		channel = flipUInt16(*(const UInt16 *)(&ptr[8]));
		const char * nickInfoStart = &ptr[10];
		int nickInfoLen = *length - 10;
		nickInfo = [[AIMNickWInfo alloc] initWithPointer:nickInfoStart length:&nickInfoLen];
		if (!nickInfo) {
			[cookie release];
			[super dealloc];
			return nil;
		}
		const char * tlvsStart = &ptr[10 + nickInfoLen];
		int tlvsLen = *length - (10 + nickInfoLen);
		icbmTlvs = [[TLV decodeTLVArray:[NSData dataWithBytes:tlvsStart length:tlvsLen]] retain];
		if (!icbmTlvs) {
			[nickInfo release];
			[cookie release];
			[super dealloc];
			return nil;
		}
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	int len = (int)[data length];
	if ((self = [self initWithPointer:[data bytes] length:&len])) {
		
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 channelFlip = flipUInt16(channel);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendData:[cookie cookieData]];
	[encoded appendBytes:&channelFlip length:2];
	[encoded appendData:[nickInfo encodePacket]];
	NSData * tlvBlock = [TLV encodeTLVBlock:icbmTlvs];
	NSData * tlvArray = [NSData dataWithBytes:&((const char *)[tlvBlock bytes])[2] length:([tlvBlock length] - 2)];
	[encoded appendData:tlvArray];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

- (NSString *)extractMessageContents {
	TLV * imData = nil;
	for (TLV * aTlv in icbmTlvs) {
		if ([aTlv type] == TLV_ICBM__TAGS_IM_DATA) {
			imData = aTlv;
		}
	}
	if (!imData) return nil;
	NSArray * dataTags = [TLV decodeTLVArray:[imData tlvData]];
	if (!dataTags) return nil;
	NSData * imText = nil;
	for (TLV * imDataInf in dataTags) {
		if ([imDataInf type] == TLV_ICBM__IM_DATA_TAGS_IM_TEXT) {
			// get the IM_TEXT, and read from the fourth byte.
			imText = [imDataInf tlvData];
		}
	}
	if ([imText length] < 4 || !imText) {
		return nil;
	}
	
	UInt16 encoding = flipUInt16(*(const UInt16 *)([imText bytes]));
	NSString * messageText = nil;
	if (encoding == 0) {
		const char * start = &((const char *)[imText bytes])[4];
		messageText = [[NSString alloc] initWithBytes:start length:([imText length] - 4) encoding:NSASCIIStringEncoding];
	} else if (encoding == 2) {
		const char * start = &((const char *)[imText bytes])[4];
		messageText = [[NSString alloc] initWithBytes:start length:([imText length] - 4) encoding:NSUnicodeStringEncoding];
	} else if (encoding == 3) {
		const char * start = &((const char *)[imText bytes])[4];
		messageText = [[NSString alloc] initWithBytes:start length:([imText length] - 4) encoding:NSWindowsCP1252StringEncoding];
	}
	return [messageText autorelease];
}

- (BOOL)isAutoResponse {
	for (TLV * aTlv in icbmTlvs) {
		if ([aTlv type] == TLV_ICBM__TAGS_AUTO_RESPONSE) {
			return YES;
		}
	}
	return NO;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"icbmData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"icbmData"]])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMICBMMessageToClient allocWithZone:zone] initWithData:[self encodePacket]];
}

- (void)dealloc {
	[cookie release];
	[nickInfo release];
	[icbmTlvs release];
	[super dealloc];
}

@end
