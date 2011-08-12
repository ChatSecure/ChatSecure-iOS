//
//  AIMNickWInfo+BArt.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMNickWInfo+BArt.h"


@implementation AIMNickWInfo (BArt)

- (NSArray *)bartIDs {
	for (TLV * t in [self userAttributes]) {
		if ([t type] == TLV_BART_INFO) {
			NSArray * bids = [AIMBArtID decodeArray:[t tlvData]];
			return bids;
		}
	}
	return nil;
}
- (NSArray *)bartIDUpdateToList:(NSArray *)newIDs {
	NSArray * oldIDs = [self bartIDs];
	NSMutableArray * idList = [[NSMutableArray alloc] init];
	if (oldIDs) {
		for (AIMBArtID * bid in oldIDs) {
			BOOL updated = NO;
			for (AIMBArtID * newBid in newIDs) {
				if ([newBid type] == [bid type]) {
					[idList addObject:newBid];
					updated = YES;
				}
			}
			if (!updated) {
				[idList addObject:bid];
			}
		}
		for (AIMBArtID * bid in newIDs) {
			BOOL exists = NO;
			for (AIMBArtID * newBid in oldIDs) {
				if ([newBid type] == [bid type]) exists = YES;
			}
			if (!exists) [idList addObject:bid];
		}
	}
		 
	NSArray * immutable = [NSArray arrayWithArray:idList];
	[idList release];
	return immutable;
}
- (AIMBArtID *)bartBuddyIcon {
	NSArray * bartIds = [self bartIDs];
	for (AIMBArtID * bid in bartIds) {
		if ([bid type] == BART_TYPE_BUDDY_ICON) {
			return bid;
		}
	}
	return nil;
}

@end
