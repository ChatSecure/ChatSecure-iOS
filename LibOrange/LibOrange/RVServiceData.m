//
//  RVServiceData.m
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RVServiceData.h"


@implementation RVServiceData

@synthesize multipleFilesFlag;
@synthesize totalFileCount;
@synthesize totalBytes;
@synthesize fileName;

- (id)initWithData:(NSData *)data {
	int len = (int)[data length];
	if ((self = [self initWithPointer:[data bytes] length:&len])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 8) {
			[super dealloc];
			return nil;
		}
		multipleFilesFlag = flipUInt16(*(const UInt16 *)ptr);
		totalFileCount = flipUInt16(((const UInt16 *)ptr)[1]);
		totalBytes = flipUInt32(((const UInt32 *)ptr)[1]);
		NSMutableString * _fileName = [[NSMutableString alloc] init];
		for (int i = 8; i < *length; i++) {
			char c = ptr[i];
			if (c == 0) {
				*length = i + 1;
				break;
			}
			[_fileName appendFormat:@"%c", c];
		}
		fileName = [[NSString alloc] initWithString:_fileName];
		[_fileName release];
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 mffFlip = flipUInt16(multipleFilesFlag);
	UInt16 tfcFlip = flipUInt16(totalFileCount);
	UInt32 tbFlip = flipUInt32(totalBytes);
	UInt8 nullB = 0;
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&mffFlip length:2];
	[encoded appendBytes:&tfcFlip length:2];
	[encoded appendBytes:&tbFlip length:4];
	[encoded appendData:[fileName dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
	[encoded appendBytes:&nullB length:1];
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket] forKey:@"packetData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [self initWithData:[aDecoder decodeObjectForKey:@"packetData"]])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[RVServiceData allocWithZone:zone] initWithData:[self encodePacket]];
}

- (void)dealloc {
	self.fileName = nil;
	[super dealloc];
}

@end
