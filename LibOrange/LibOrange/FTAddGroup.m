//
//  FTAddGroup.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTAddGroup.h"


@implementation FTAddGroup

- (id)initWithName:(NSString *)group {
	if ((self = [super init])) {
		groupName = [group retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	AIMFeedbagItem * rootGroup = [feedbag findRootGroup];
	AIMFeedbagItem * newGroup = [[AIMFeedbagItem alloc] init];
	newGroup.classID = FEEDBAG_GROUP;
	newGroup.itemID = 0;
	newGroup.groupID = [feedbag randomGroupID];
	newGroup.attributes = [NSArray arrayWithObject:[[[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[NSData data]] autorelease]];
	newGroup.itemName = groupName;
	AIMFeedbagItem * newRoot = [rootGroup itemByAddingOrderItem:newGroup.groupID];
	
	SNAC * insert = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS) flags:0 requestID:[session generateReqID] data:[newGroup encodePacket]];
	SNAC * update = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[newRoot encodePacket]];
	snacs = [[NSArray alloc] initWithObjects:insert, update, nil];
	[insert release];
	[update release];
	[newGroup release];
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
	[groupName release];
	[snacs release];
	[super dealloc];
}

@end
