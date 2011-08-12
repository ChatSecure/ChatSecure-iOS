//
//  FTRemoveGroup.m
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTRemoveGroup.h"


@implementation FTRemoveGroup

- (id)initWithGroup:(AIMBlistGroup *)aGroup {
	if ((self = [super init])) {
		group = [aGroup retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	AIMFeedbagItem * rootGroup = [feedbag findRootGroup];
	AIMFeedbagItem * groupItem = [feedbag groupWithGroupID:[group feedbagGroupID]];
	if (!rootGroup || !groupItem) {
		snacs = [[NSArray alloc] init];
		snacIndex = -1;
		return;
	}
	AIMFeedbagItem * newRoot = [rootGroup itemByRemovingOrderItem:[groupItem groupID]];
	// find items in the specified group.
	NSMutableArray * groupItems = [[NSMutableArray alloc] init];
	for (AIMFeedbagItem * item in [feedbag items]) {
		if ([item groupID] == [groupItem groupID] && [item itemID] != 0) {
			[groupItems addObject:item];
		}
	}
	[groupItems addObject:groupItem];
	NSMutableData * deleteData = [NSMutableData data];
	for (AIMFeedbagItem * item in groupItems) {
		[deleteData appendData:[item encodePacket]];
	}
	[groupItems release];
	SNAC * update = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[newRoot encodePacket]];
	SNAC * delete = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__DELETE_ITEMS) flags:0 requestID:[session generateReqID] data:deleteData];
	snacs = [[NSArray alloc] initWithObjects:update, delete, nil];
	snacIndex = -1;
	[delete release];
	[update release];
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
	[group release];
	[snacs release];
	[super dealloc];
}

@end
