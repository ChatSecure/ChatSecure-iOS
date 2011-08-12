//
//  AIMFeedbagItem.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagItem.h"


@implementation AIMFeedbagItem

@synthesize itemName;
@synthesize groupID;
@synthesize itemID;
@synthesize classID;
@synthesize attributes;

#pragma mark OSCAR Packet

- (id)initWithData:(NSData *)data {
	const char * bytes = [data bytes];
	int length = (int)[data length];
	self = [self initWithPointer:bytes length:&length];
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if ((self = [super init])) {
		if (*_length < 10) {
			[super dealloc];
			return nil;
		}
		UInt16 nameLength = flipUInt16(*(const UInt16 *)ptr);
		if (nameLength + 10 > *_length) {
			[super dealloc];
			return nil;
		}
		
		self.itemName = decodeString16([NSData dataWithBytes:ptr length:nameLength+2]);
		
		groupID = flipUInt16(*((const UInt16 *)(&ptr[nameLength + 2])));
		itemID = flipUInt16(*((const UInt16 *)(&ptr[nameLength + 4])));
		classID = flipUInt16(*((const UInt16 *)(&ptr[nameLength + 6])));
		
		int maxLength = *_length - (nameLength + 8);
		NSArray * immutableAttributes = [TLV decodeTLVLBlock:&ptr[nameLength + 8] length:&maxLength];
		
		if (!immutableAttributes) {
			self.itemName = nil;
			[super dealloc];
			return nil;
		}
		
		*_length = maxLength + (nameLength + 8);
		
		attributes = [[NSMutableArray alloc] initWithArray:immutableAttributes];
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	NSData * nameString = encodeString16(self.itemName);
	UInt16 groupFlip = flipUInt16(groupID);
	UInt16 itemFlip = flipUInt16(itemID);
	UInt16 classFlip = flipUInt16(classID);
	[encoded appendData:nameString];
	[encoded appendBytes:&groupFlip length:2];
	[encoded appendBytes:&itemFlip length:2];
	[encoded appendBytes:&classFlip length:2];
	[encoded appendData:[TLV encodeTLVLBlock:attributes]];
	
	// create an immutable version
	NSData * immutableItem = [NSData dataWithData:encoded];
	[encoded release];
	return immutableItem;
}

#pragma mark Other Methods

- (TLV *)attributeOfType:(UInt16)type {
	for (TLV * attribute in self.attributes) {
		if ([attribute type] == type) return attribute;
	}
	return nil;
}

+ (NSArray *)decodeArray:(NSData *)arrayData {
	NSMutableArray * decodedArray = [[NSMutableArray alloc] init];
	const char * bytes = [arrayData bytes];
	int dataLength = (int)[arrayData length];
	while (dataLength > 0) {
		int currentLength = dataLength;
		AIMFeedbagItem * item = [[AIMFeedbagItem alloc] initWithPointer:bytes length:&currentLength];
		if (!item) {
			[decodedArray release];
			return nil;
		}
		[decodedArray addObject:item];
		[item release];
		dataLength -= currentLength;
		bytes = &bytes[currentLength];
	}

	// create an immutable array
	NSArray * items = [NSArray arrayWithArray:decodedArray];
	[decodedArray release];
	return items;
}

#pragma mark NSCopying

- (AIMFeedbagItem *)copyWithZone:(NSZone *)zone {
	return [[AIMFeedbagItem allocWithZone:zone] initWithData:[self encodePacket]];
}

- (AIMFeedbagItem *)copy {
	return [[AIMFeedbagItem alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.itemName forKey:@"name"];
	[aCoder encodeInt:groupID forKey:@"group"];
	[aCoder encodeInt:itemID forKey:@"item"];
	[aCoder encodeInt:classID forKey:@"class"];
	[aCoder encodeObject:self.attributes forKey:@"attributes"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		self.itemName = [aDecoder decodeObjectForKey:@"name"];
		self.groupID = [aDecoder decodeIntForKey:@"group"];
		self.itemID = [aDecoder decodeIntForKey:@"item"];
		self.classID = [aDecoder decodeIntForKey:@"class"];
		attributes = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:@"attributes"]];
	}
	return self;
}

#pragma mark Misc

- (NSString *)description {
	return [NSString stringWithFormat:@"%@: name=\"%@\" groupID=%d itemID=%d classID=%d", 
			[super description], itemName, groupID, itemID, classID];
}

- (void)dealloc {
	self.attributes = nil;
	self.itemName = nil;
	[super dealloc];
}

@end
