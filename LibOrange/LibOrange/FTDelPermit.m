//
//  FTDelPermit.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTDelPermit.h"


@implementation FTDelPermit

- (id)initWithUsername:(NSString *)username {
	if ((self = [super init])) {
		permitUsername = [username retain];
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	// check if the feedbag already has the denied user.
	AIMFeedbagItem * existing = [feedbag permitWithUsername:permitUsername];
	if (existing) {
		SNAC * delete = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__DELETE_ITEMS) flags:0 requestID:[session generateReqID] data:[existing encodePacket]];
		snacs = [[NSArray alloc] initWithObjects:delete, nil];
		[delete release];
		snacIndex = -1;
	} else {
		snacs = [[NSArray alloc] init];
		snacIndex = -1;
		return;
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
	[snacs release];
	[permitUsername release];
	[super dealloc];
}

@end
