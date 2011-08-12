//
//  AIMIMRendezvous.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMIMRendezvous.h"

NSString * IPv4AddrToString (UInt32 ipAddr) {
	NSMutableString * str = [[NSMutableString alloc] init];
	const unsigned char * bytes = (const unsigned char *)&ipAddr;
	for (int i = 0; i < 4; i++) {
		[str appendFormat:@"%d%s", bytes[i], (i == 3 ? "" : ".")];
	}
	NSString * immutable = [NSString stringWithString:str];
	[str release];
	return immutable;
}

@implementation AIMIMRendezvous

@synthesize type;
@synthesize cookie;
@synthesize service;
@synthesize params;

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 26) {
			[super dealloc];
			return nil;
		}
		type = flipUInt16(*(const UInt16 *)ptr);
		cookie = [[AIMICBMCookie alloc] initWithCookieData:&ptr[2]];
		service = [[AIMCapability alloc] initWithUUID:[NSData dataWithBytes:&ptr[10] length:16]];
		int len = *length - 26;
		self.params = [TLV decodeTLVArray:[NSData dataWithBytes:&ptr[26] length:len]];
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	int len = (int)[data length];
	if ((self = [self initWithPointer:[data bytes] length:&len])) {
		
	}
	return self;
}

- (id)initWithICBMMessage:(AIMICBMMessageToClient *)msg {
	TLV * rendezvousIM = nil;
	for (TLV * tag in [msg icbmTlvs]) {
		if ([tag type] == TLV_RV_DATA) {
			rendezvousIM = tag;
		}
	}
	if (!rendezvousIM) {
		[super init];
		[super dealloc];
		return nil;
	}
	if ((self = [self initWithData:[rendezvousIM tlvData]])) {
		
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 typeFlip = flipUInt16(type);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&typeFlip length:2];
	[encoded appendData:[cookie cookieData]];
	[encoded appendData:[service uuid]];
	[encoded appendData:[TLV encodeTLVArray:self.params]];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark Data Extraction

- (NSString *)remoteAddress {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_VERIFIED_IP_ADDR && [[tag tlvData] length] == 4) {
			UInt32 ipAddrRaw = *(const UInt32 *)[[tag tlvData] bytes];
			return IPv4AddrToString(ipAddrRaw);
		}
	}
	return nil;
}
- (NSString *)internalAddress {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_PROPOSER_IP_ADDR && [[tag tlvData] length] == 4) {
			UInt32 ipAddrRaw = *(const UInt32 *)[[tag tlvData] bytes];
			return IPv4AddrToString(ipAddrRaw);
		}
	}
	return nil;
}
- (NSString *)proxyAddress {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_IP_ADDR && [[tag tlvData] length] == 4) {
			UInt32 ipAddrRaw = *(const UInt32 *)[[tag tlvData] bytes];
			return IPv4AddrToString(ipAddrRaw);
		}
	}
	return nil;
}
- (UInt16)remotePort {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_PORT && [[tag tlvData] length] == 2) {
			return flipUInt16(*(const UInt16 *)[[tag tlvData] bytes]);
		}
	}
	return 0;
}
- (UInt16)sequenceNumber {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_SEQUENCE_NUM && [[tag tlvData] length] == 2) {
			return flipUInt16(*(const UInt16 *)[[tag tlvData] bytes]);
		}
	}
	return 0;
}
- (UInt16)cancelReason {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_CANCEL_REASON && [[tag tlvData] length] == 2) {
			return flipUInt16(*(const UInt16 *)[[tag tlvData] bytes]);
		}
	}
	return 4;
}
- (BOOL)isProxyFlagSet {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_REQUEST_USE_ARS) {
			return YES;
		}
	}
	return NO;
}
- (RVServiceData *)serviceData {
	for (TLV * tag in [self params]) {
		if ([tag type] == TLV_RV_SERVICE_DATA) {
			RVServiceData * sd = [[RVServiceData alloc] initWithData:[tag tlvData]];
			return [sd autorelease];
		}
	}
	return nil;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"data"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"data"]])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMIMRendezvous allocWithZone:zone] initWithData:[self encodePacket]];
}

- (void)dealloc {
	self.cookie = nil;
	self.service = nil;
	self.params = nil;
	[super dealloc];
}

@end
