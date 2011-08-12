//
//  AIMCapability.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMCapability.h"

@interface AIMCapability (Private)

+ (NSData *)defaultUUID;

@end

@implementation AIMCapability

@synthesize uuid;

- (id)initWithType:(AIMCapabilityType)capType {
	if ((self = [super init])) {
		NSDictionary * caps = [AIMCapability uuidsForCapTypes];
		for (NSNumber * type in caps) {
			if ([type intValue] == capType) {
				uuid = [[caps objectForKey:type] retain];
			}
		}
		if (!uuid) {
			[super dealloc];
			return nil;
		}
	}
	return self;
}
- (id)initWithUUID:(NSData *)capUUID {
	if ((self = [super init])) {
		uuid = [capUUID retain];
	}
	return self;
}

- (BOOL)isEqualToCapability:(AIMCapability *)anotherCap {
	if ([[self uuid] isEqual:[anotherCap uuid]]) {
		return YES;
	}
	return NO;
}

- (AIMCapabilityType)capabilityType {
	NSDictionary * caps = [AIMCapability uuidsForCapTypes];
	for (NSNumber * type in caps) {
		NSData * _uuid = [caps objectForKey:type];
		if ([_uuid isEqualToData:uuid]) {
			return [type intValue];
		}
	}
	return AIMCapabilityOther;
}

- (NSString *)description {
	AIMCapabilityType capType = [self capabilityType];
	if (capType == AIMCapabilityFileTransfer) return @"File transfers";
	else if (capType == AIMCapabilityDirectIM) return @"Direct IM";
	else return @"Unknown";
}

- (void)dealloc {
	[uuid release];
	[super dealloc];
}

+ (NSDictionary *)uuidsForCapTypes {
	static NSDictionary * dict = nil;
	if (!dict) {
		char _fileTransfer[2];
		char _getFile[2];
		char _directIM[2];
		NSMutableDictionary * builder = [NSMutableDictionary dictionary];
		NSMutableData * defaultDat = [NSMutableData dataWithData:[AIMCapability defaultUUID]];
		_fileTransfer[0] = 0x13;
		_fileTransfer[1] = 0x43;
		_getFile[0] = 0x13;
		_getFile[1] = 0x48;
		_directIM[0] = 0x13;
		_directIM[1] = 0x45;
		[defaultDat replaceBytesInRange:NSMakeRange(2, 2) withBytes:_fileTransfer];
		NSData * fileTransfers = [[defaultDat copy] autorelease];
		[defaultDat replaceBytesInRange:NSMakeRange(2, 2) withBytes:_directIM];
		NSData * directIM = [[defaultDat copy] autorelease];
		[defaultDat replaceBytesInRange:NSMakeRange(2, 2) withBytes:_getFile];
		NSDate * getFile = [[defaultDat copy] autorelease];
		
		[builder setObject:fileTransfers forKey:[NSNumber numberWithInt:AIMCapabilityFileTransfer]];
		[builder setObject:directIM forKey:[NSNumber numberWithInt:AIMCapabilityDirectIM]];
		[builder setObject:getFile forKey:[NSNumber numberWithInt:AIMCapabilityGetFiles]];
		
		dict = [[NSDictionary alloc] initWithDictionary:builder];
	}
	return dict;
}

+ (NSData *)defaultUUID {
	char data[16];
	data[0] = 0x09;
	data[1] = 0x46;
	data[2] = 0x00; // XX
	data[3] = 0x00; // YY
	data[4] = 0x4c;
	data[5] = 0x7f;
	data[6] = 0x11;
	data[7] = 0xd1;
	data[8] = 0x82;
	data[9] = 0x22;
	data[10] = 0x44;
	data[11] = 0x45;
	data[12] = 0x53;
	data[13] = 0x54;
	data[14] = 0x00;
	data[15] = 0x00;
	return [NSData dataWithBytes:data length:16];
}

+ (BOOL)compareCapArray:(NSArray *)arr1 toArray:(NSArray *)arr2 {
	if ([arr1 count] != [arr2 count]) return NO;
	for (int i = 0; i < [arr1 count]; i++) {
		AIMCapability * cap1 = [arr1 objectAtIndex:i];
		AIMCapability * cap2 = [arr2 objectAtIndex:i];
		if (![cap1 isEqualToCapability:cap2]) return NO;
	}
	return YES;
}

+ (TLV *)filetransferCapabilitiesBlock {
	char caps[16];
	memcpy(caps, "\x09\x46\x13\x43\x4C\x7F\x11\xD1\x82\x22\x44\x45\x53\x54", 14);
	caps[14] = 0;
	caps[15] = 0;
	return [[[TLV alloc] initWithType:1 data:[NSData dataWithBytes:caps length:16]] autorelease];
}

@end
