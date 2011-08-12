//
//  FTAddBuddy.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTAddBuddy.h"


@implementation FTAddBuddy

- (id)initWithUsername:(NSString *)nick group:(AIMBlistGroup *)theGroup {
	if ((self = [super init])) {
		username = [nick retain];
		group = [theGroup retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	// check if stuff is valid.
	if (![feedbag groupWithGroupID:[group feedbagGroupID]]) {
		snacs = [[NSArray alloc] init];
		snacIndex = -1;
		return;
	} else if ([group buddyWithUsername:username]) {
		snacs = [[NSArray alloc] init];
		snacIndex = -1;
		return;
	}
	AIMFeedbagItem * groupItem = [feedbag groupWithGroupID:[group feedbagGroupID]];
	AIMFeedbagItem * newItem = [[AIMFeedbagItem alloc] init];
	newItem.groupID = [groupItem groupID];
	newItem.classID = FEEDBAG_BUDDY;
	newItem.itemID = [feedbag randomItemID];
	newItem.itemName = username;
	newItem.attributes = [NSArray array];
	AIMFeedbagItem * groupUpdate = [groupItem itemByAddingOrderItem:newItem.itemID];
	
	// create SNACs
	SNAC * insert = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS) flags:0 requestID:[session generateReqID] data:[newItem encodePacket]];
	SNAC * update = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[groupUpdate encodePacket]];
	[newItem release];
	snacs = [[NSArray alloc] initWithObjects:insert, update, nil];
	[insert release];
	[update release];
	snacIndex = -1;
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
	[username release];
	[group release];
	[snacs release];
	[super dealloc];
}

@end
