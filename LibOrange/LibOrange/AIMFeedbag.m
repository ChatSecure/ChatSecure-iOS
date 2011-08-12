//
//  AIMFeedbag.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbag.h"


@implementation AIMFeedbag

@synthesize items;
@synthesize updateTime;
@synthesize numClasses;

- (id)initWithSnac:(SNAC *)feedbagReply {
	if ((self = [self initWithData:[feedbagReply innerContents]])) {
		
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	if ((self = [super init])) {
		UInt16 numItems = 0;
		const char * bytes = [data bytes];
		int bytesLength = (int)[data length];
		
		if ([data length] < 3) {
			[super dealloc];
			return nil;
		}
		
		numClasses = *(const UInt8 *)bytes;
		numItems = flipUInt16(*((const UInt16 *)(&bytes[1])));
		
		bytes = &bytes[3];
		bytesLength = bytesLength - 7;
		items = [[NSMutableArray alloc] init];
		
		while (numItems > 0) {
			if (bytesLength <= 0) {
				NSLog(@"Warning: feedbag overflow, ignoring.");
				break;
			} else if (bytesLength <= 4) break;
			
			int leftOver = bytesLength;
			AIMFeedbagItem * item = [[AIMFeedbagItem alloc] initWithPointer:bytes length:&leftOver];
			if (!item) {
				NSLog(@"Warning: possible missing item.");
				break;
			}
			
			[items addObject:item];
			[item release];
			bytesLength -= leftOver;
			bytes = &bytes[leftOver];
			
			numItems -= 1;
		}
		if (bytesLength == 4) {
			updateTime = flipUInt32(*(const UInt32 *)bytes);
		}
	}
	return self;
}

- (NSData *)encodePacket {
	UInt16 numItemsRev = flipUInt16((UInt16)[items count]);
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&numClasses length:1];
	[encoded appendBytes:&numItemsRev length:2];
	for (int i = 0; i < [items count]; i++) {
		[encoded appendData:[[items objectAtIndex:i] encodePacket]];
	}
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark Searches and Generators

- (AIMFeedbagItem *)itemWithItemID:(UInt16)itemID {
	for (AIMFeedbagItem * item in items) {
		if ([item itemID] == itemID && [item classID] == FEEDBAG_BUDDY) return item;
	}
	return nil;
}
- (AIMFeedbagItem *)groupWithGroupID:(UInt16)groupID {
	for (AIMFeedbagItem * item in items) {
		if ([item groupID] == groupID) return item;
	}
	return nil;
}

- (UInt16)randomItemID {
	for (UInt16 i = (arc4random() % 10000) + 2000; i < 0xFFFE; i++) {
		BOOL exists = NO;
		for (AIMFeedbagItem * item in items) {
			if ([item itemID] == i) {
				exists = YES;
				break;
			}
		}
		if (!exists) return i;
	}
	return 0;
}
- (UInt16)randomGroupID {
	for (UInt16 i = (arc4random() % 10000) + 2000; i < 0xFFFE; i++) {
		if (![self groupWithGroupID:i]) return i;
	}
	return 0;
}

- (void)appendFeedbagItems:(AIMFeedbag *)anotherFeedbag {
	for (AIMFeedbagItem * item in [anotherFeedbag items]) {
		if ([item itemID] == 0) {
			if ([self groupWithGroupID:[item groupID]] == nil) {
				[items addObject:item];
			}
		} else {
			if ([self itemWithItemID:[item itemID]] == nil) {
				[items addObject:item];
			}
		}
	}
	self.updateTime = [anotherFeedbag updateTime];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		numClasses = [aDecoder decodeIntForKey:@"numClasses"];
		items = [aDecoder decodeObjectForKey:@"items"];
		updateTime = [aDecoder decodeIntForKey:@"utime"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:numClasses forKey:@"numClasses"];
	[aCoder encodeObject:items forKey:@"items"];
	[aCoder encodeInt:updateTime forKey:@"utime"];
}

- (void)dealloc {
	[items release];
	[super dealloc];
}

@end
