//
//  AIMFeedbagRights.m
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagRights.h"


@implementation AIMFeedbagRights

@synthesize maxItemAttributes;
@synthesize maxClientItems;
@synthesize maxItemNameLength;
@synthesize maxRecentBuddies;
@synthesize maxBuddiesPerGroup;

- (id)initWithRightsArray:(NSData *)feedbagRightsReply {
	if ((self = [super init])) {
		maxItemAttributes = UINT16_MAX;
		maxClientItems = UINT16_MAX;
		maxItemNameLength = 97;
		maxRecentBuddies = UINT16_MAX;
		maxBuddiesPerGroup = UINT16_MAX;
		NSArray * tlvs = [TLV decodeTLVArray:feedbagRightsReply];
		for (TLV * attr in tlvs) {
			if ([[attr tlvData] length] >= 2) {
				if ([attr type] == TLV_FEEDBAG_RIGHTS_MAX_CLIENT_ITEMS) {
					maxClientItems = flipUInt16(*(const UInt16 *)([[attr tlvData] bytes]));
				} else if ([attr type] == TLV_FEEDBAG_RIGHTS_MAX_ITEM_ATTRS) {
					maxItemAttributes = flipUInt16(*(const UInt16 *)([[attr tlvData] bytes]));
				} else if ([attr type] == TLV_FEEDBAG_RIGHTS_MAX_ITEM_NAME_LEN) {
					maxItemNameLength = flipUInt16(*(const UInt16 *)([[attr tlvData] bytes]));
				} else if ([attr type] == TLV_FEEDBAG_RIGHTS_MAX_BUDDIES_PER_GROUP) {
					maxBuddiesPerGroup = flipUInt16(*(const UInt16 *)([[attr tlvData] bytes]));
				} else if ([attr type] == TLV_FEEDBAG_RIGHTS_MAX_RECENT_BUDDIES) {
					maxRecentBuddies = flipUInt16(*(const UInt16 *)([[attr tlvData] bytes]));
				}
			}
		}
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Max item attribute bytes: %d\n"
			@"Max client items: %d\n"
			@"Max item name length: %d\n"
			@"Max recent buddies: %d\n"
			@"Max buddies per group: %d\n", maxItemAttributes, maxClientItems, maxItemNameLength,
			maxRecentBuddies, maxBuddiesPerGroup];
}

@end
