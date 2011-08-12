//
//  FTSetPDMode.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTSetPDMode.h"

NSString * PD_MODE_TOSTR (UInt8 pdMode) {
	switch (pdMode) {
		case PD_MODE_DENY_ALL:
			return @"Deny all";
			break;
		case PD_MODE_DENY_SOME:
			return @"Deny some";
			break;
		case PD_MODE_PERMIT_ALL:
			return @"Permit all";
			break;
		case PD_MODE_PERMIT_ON_LIST:
			return @"Permit on list";
			break;
		case PD_MODE_PERMIT_SOME:
			return @"Permit some";
			break;
		default:
			break;
	}
	return @"Unknow PD_MODE";
}

@implementation FTSetPDMode

- (id)initWithPDMode:(UInt8)_pdMode pdFlags:(UInt32)_pdFlags; {
	if ((self = [super init])) {
		pdMode = _pdMode;
		pdFlags = _pdFlags;
	}
	return self;
}

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	AIMFeedbagItem * existingPDInfo = [feedbag findPDMode];
	AIMFeedbagItem * newItem = nil;
	if (!existingPDInfo) {
		newItem = [[AIMFeedbagItem alloc] init];
		newItem.classID = FEEDBAG_PDINFO;
		newItem.itemID = [feedbag randomItemID];
		newItem.groupID = 0;
		newItem.itemName = @"";
	} else {
		newItem = [existingPDInfo copy];
	}
	[newItem.attributes removeAllObjects];
	UInt32 pdFlagsFlip = flipUInt32(pdFlags);
	UInt32 pdMask = 0xffffffff;
	TLV * pdModeT = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_PD_MODE data:[NSData dataWithBytes:&pdMode length:1]];
	TLV * pdMaskT = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_PD_MASK data:[NSData dataWithBytes:&pdMask length:4]];
	TLV * pdFlagsT = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_PD_FLAGS data:[NSData dataWithBytes:&pdFlagsFlip length:4]];
	[newItem.attributes addObject:pdModeT];
	[newItem.attributes addObject:pdMaskT];
	[newItem.attributes addObject:pdFlagsT];
	[pdModeT release];
	[pdMaskT release];
	[pdFlagsT release];
	SNAC * transactionSnac;
	if (!existingPDInfo) {
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS) flags:0 requestID:[session generateReqID] data:[newItem encodePacket]];
	} else {
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS) flags:0 requestID:[session generateReqID] data:[newItem encodePacket]];
	}
	snacs = [[NSArray arrayWithObject:transactionSnac] retain];
	[transactionSnac release];
	[newItem release];
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
	[snacs release];
	[super dealloc];
}

@end
