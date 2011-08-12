//
//  FRRemoveBuddy.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTRemoveBuddy.h"


@implementation FTRemoveBuddy

- (id)initWithBuddy:(AIMBlistBuddy *)aBuddy {
	if ((self = [super init])) {
		buddy = [aBuddy retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	if (![feedbag itemWithItemID:[buddy feedbagItemID]]) {
		snacs = [[NSMutableArray alloc] init];
		snacIndex = -1;
		return;
	}
	
	AIMFeedbagItem * deleting = [feedbag itemWithItemID:[buddy feedbagItemID]];
	AIMFeedbagItem * group = [feedbag groupWithGroupID:[[buddy group] feedbagGroupID]];
	if (!group) {
		snacs = [[NSArray alloc] init];
		snacIndex = -1;
		return;
	}
	AIMFeedbagItem * newGroup = [group itemByRemovingOrderItem:[deleting itemID]];
	SNAC * update = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[newGroup encodePacket]];
	SNAC * delete = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__DELETE_ITEMS) flags:0 requestID:[session generateReqID] data:[deleting encodePacket]];
	
	snacs = [[NSArray alloc] initWithObjects:update, delete, nil];
	[update release];
	[delete release];
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
	[buddy release];
	[snacs release];
	[super dealloc];
}

@end
