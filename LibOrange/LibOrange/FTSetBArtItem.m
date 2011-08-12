//
//  FTSetBArtItem.m
//  LibOrange
//
//  Created by Alex Nichol on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTSetBArtItem.h"


@implementation FTSetBArtItem

- (id)initWithBArtID:(AIMBArtID *)bartID {
	if ((self = [super init])) {
		bid = [bartID retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	NSAssert([NSThread currentThread] == [session backgroundThread], @"Running on incorrect thread");
	AIMFeedbagItem * existingBartItem = nil;
	NSString * bartType = [NSString stringWithFormat:@"%d", [bid type]];
	for (AIMFeedbagItem * item in [feedbag items]) {
		if ([item classID] == FEEDBAG_BART) {
			if ([[item itemName] isEqual:bartType]) {
				existingBartItem = item;
				break;
			}
		}
	}
	NSData * bidData = [bid encodePacket];
	if ([bidData length] > 2) {
		bidData = [NSData dataWithBytes:&((const char *)[bidData bytes])[2] length:([bidData length] - 2)];
	}
	if (existingBartItem) {
		// update it.
		AIMFeedbagItem * newItem = [existingBartItem copy];
		TLV * bartInfoAttr = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_BART_INFO data:bidData];
		newItem.attributes = [NSArray arrayWithObject:bartInfoAttr];
		[bartInfoAttr release];
		SNAC * update = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[newItem encodePacket]];
		snacs = [[NSArray arrayWithObject:update] retain];
		snacIndex = -1;
		[newItem release];
		[update release];
	} else {
		AIMFeedbagItem * newItem = [[AIMFeedbagItem alloc] init];
		newItem.classID = FEEDBAG_BART;
		newItem.groupID = 0;
		newItem.itemID = [feedbag randomItemID];
		newItem.itemName = bartType;
		TLV * bartInfoAttr = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_BART_INFO data:bidData];
		newItem.attributes = [NSArray arrayWithObject:bartInfoAttr];
		[bartInfoAttr release];
		
		SNAC * insert = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS) flags:0 requestID:[session generateReqID] data:[newItem encodePacket]];
		snacs = [[NSArray arrayWithObject:insert] retain];
		snacIndex = -1;
		[newItem release];
		[insert release];
	}
}

- (BOOL)hasCreatedOperations {
	if (snacs) return YES;
	else return NO;
}

- (SNAC *)nextTransactionSNAC {
	if (snacIndex + 1 == [snacs count]) return nil;
	return [snacs objectAtIndex:++snacIndex];
}

- (SNAC *)currentTransactionSNAC {
	if (snacIndex < 0) return nil;
	return [snacs objectAtIndex:snacIndex];
}

- (void)dealloc {
	[bid release];
	[snacs release];
	[super dealloc];
}

@end
