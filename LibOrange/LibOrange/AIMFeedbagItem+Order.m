//
//  AIMFeedbagItem+Order.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagItem+Order.h"


@implementation AIMFeedbagItem (Order)

- (NSArray *)groupOrder {
	TLV * orderAttr = [self attributeOfType:FEEDBAG_ATTRIBUTE_ORDER];
	if (!orderAttr) return [NSArray array];
	NSMutableArray * numbers = [[NSMutableArray alloc] init];
	const UInt16 * nums = [[orderAttr tlvData] bytes];
	int numsCount = (int)[[orderAttr tlvData] length] / 2;
	for (int i = 0; i < numsCount; i++) {
		UInt16 theNum = flipUInt16(nums[i]);
		[numbers addObject:[NSNumber numberWithUnsignedShort:theNum]];
	}
	
	NSArray * immutable = [NSArray arrayWithArray:numbers];
	[numbers release];
	return immutable;
}

- (BOOL)orderChangeToItem:(AIMFeedbagItem *)newItem added:(NSArray **)added removed:(NSArray **)removed {
	NSArray * ourOrder = [self groupOrder];
	NSArray * theirOrder = [newItem groupOrder];
	if (!ourOrder || !theirOrder) return NO;
	NSMutableArray * _added = [NSMutableArray array];
	NSMutableArray * _removed = [NSMutableArray array];
	for (NSNumber * n in theirOrder) {
		if (![ourOrder containsObject:n]) {
			[_added addObject:n];
		}
	}
	for (NSNumber * n in ourOrder) {
		if (![theirOrder containsObject:n]) {
			[_removed addObject:n];
		}
	}
	if (added) *added = _added;
	if (removed) *removed = _removed;
	if ([_added count] > 0 || [_removed count] > 0) return YES;
	return NO;
}


- (TLV *)orderByAddingID:(UInt16)theID {
	NSMutableArray * existingOrder = [NSMutableArray arrayWithArray:[self groupOrder]];
	[existingOrder addObject:[NSNumber numberWithUnsignedShort:theID]];
	NSMutableData * encodedOrder = [[NSMutableData alloc] init];
	for (NSNumber * n in existingOrder) {
		UInt16 flipShort = flipUInt16([n unsignedShortValue]);
		[encodedOrder appendBytes:&flipShort length:2];
	}
	return [[[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[encodedOrder autorelease]] autorelease];
}

- (TLV *)orderByRemovingID:(UInt16)theID {
	NSMutableArray * existingOrder = [NSMutableArray arrayWithArray:[self groupOrder]];
	NSNumber * obj = [NSNumber numberWithUnsignedShort:theID];
	if ([existingOrder containsObject:obj]) [existingOrder removeObject:obj];
	NSMutableData * encodedOrder = [[NSMutableData alloc] init];
	for (NSNumber * n in existingOrder) {
		UInt16 flipShort = flipUInt16([n unsignedShortValue]);
		[encodedOrder appendBytes:&flipShort length:2];
	}
	return [[[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[encodedOrder autorelease]] autorelease];
}

- (AIMFeedbagItem *)itemByAddingOrderItem:(UInt16)newItem {
	AIMFeedbagItem * thisCopy = [self copy];
	BOOL exists = NO;
	TLV * newOrder = [self orderByAddingID:newItem];
	for (int i = 0; i < [thisCopy.attributes count]; i++) {
		TLV * attr = [thisCopy.attributes objectAtIndex:i];
		if ([attr type] == FEEDBAG_ATTRIBUTE_ORDER) {
			exists = YES;
			// replace
			[thisCopy.attributes replaceObjectAtIndex:i withObject:newOrder];
			break;
		}
	}
	if (!exists) {
		[thisCopy.attributes addObject:newOrder];
	}
	return [thisCopy autorelease];
}

- (AIMFeedbagItem *)itemByRemovingOrderItem:(UInt16)newItem {
	AIMFeedbagItem * thisCopy = [self copy];
	BOOL exists = NO;
	TLV * newOrder = [self orderByRemovingID:newItem];
	for (int i = 0; i < [thisCopy.attributes count]; i++) {
		TLV * attr = [thisCopy.attributes objectAtIndex:i];
		if ([attr type] == FEEDBAG_ATTRIBUTE_ORDER) {
			exists = YES;
			// replace
			[thisCopy.attributes replaceObjectAtIndex:i withObject:newOrder];
			break;
		}
	}
	if (!exists) {
		[thisCopy.attributes addObject:newOrder];
	}
	return [thisCopy autorelease];
}

@end
