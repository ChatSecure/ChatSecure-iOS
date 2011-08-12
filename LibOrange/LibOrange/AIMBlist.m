//
//  AIMBlist.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBlist.h"

@interface AIMBlist (Private)

- (AIMBlistGroup *)loadGroup:(AIMFeedbagItem *)group inFeedbag:(AIMFeedbag *)feedbag;

@end

@implementation AIMBlist

@synthesize tempBuddyHandler;

- (NSArray *)groups {
	return groups;
}

- (NSMutableArray *)permitList {
	return permit;
}

- (NSMutableArray *)denyList {
	return deny;
}

- (id)initWithFeedbag:(AIMFeedbag *)feedbag tempBuddyHandler:(AIMTempBuddyHandler *)tmpBuddy {
	if ((self = [super init])) {
		tempBuddyHandler = [tmpBuddy retain];
		groups = [[NSMutableArray alloc] init];
		permit = [[NSMutableArray alloc] init];
		deny = [[NSMutableArray alloc] init];
		for (AIMFeedbagItem * item in [feedbag items]) {
			if ([item itemID] == 0 && [item groupID] == 0 && [item classID] == FEEDBAG_GROUP) {
				// reached the group ID.
				NSArray * orderAttr = [item groupOrder];
				if (!orderAttr) {
					NSLog(@"Root group has no order attribute.");
					[groups release];
					[super dealloc];
					return nil;
				}
				for (NSNumber * n in orderAttr) {
					UInt16 number = (UInt16)[n unsignedShortValue];
					AIMFeedbagItem * theGroup = [feedbag groupWithGroupID:number];
					AIMBlistGroup * group = [self loadGroup:theGroup inFeedbag:feedbag];
					if (group) [groups addObject:group];
				}
			} else if ([item classID] == FEEDBAG_PERMIT) {
				[permit addObject:[item itemName]];
			} else if ([item classID] == FEEDBAG_DENY) {
				[deny addObject:[item itemName]];
			}
		}
	}
	return self;
}

#pragma mark Searches

- (AIMBlistBuddy *)buddyWithUsername:(NSString *)username {
	for (AIMBlistGroup * group in groups) {
		AIMBlistBuddy * buddy = [group buddyWithUsername:username];
		if (buddy) return buddy;
	}
	if ([tempBuddyHandler tempBuddyWithName:username]) {
		return [tempBuddyHandler tempBuddyWithName:username];
	} else {
		return [tempBuddyHandler addTempBuddy:username];
	}
}

- (NSArray *)buddiesWithUsername:(NSString *)username {
	NSMutableArray * array = [NSMutableArray array];
	for (AIMBlistGroup * group in groups) {
		AIMBlistBuddy * buddy = [group buddyWithUsername:username];
		if (buddy) [array addObject:buddy];
	}
	if ([tempBuddyHandler tempBuddyWithName:username]) {
		[array addObject:[tempBuddyHandler tempBuddyWithName:username]];
	}
	return array;
}

- (AIMBlistBuddy *)buddyWithFeedbagID:(UInt16)feedbagID {
	for (AIMBlistGroup * group in groups) {
		for (AIMBlistBuddy * buddy in [group buddies]) {
			if ([buddy feedbagItemID] == feedbagID) return buddy;
		}
	}
	return nil;
}

- (AIMBlistGroup *)groupWithFeedbagID:(UInt16)feedbagID {
	for (AIMBlistGroup * group in groups) {
		if ([group feedbagGroupID] == feedbagID) return group;
	}
	return nil;
}	

- (AIMBlistGroup *)groupWithName:(NSString *)name {
	for (AIMBlistGroup * group in groups) {
		if ([[[group name] lowercaseString] isEqual:[name lowercaseString]]) {
			return group;
		}
	}
	return nil;
}

#pragma mark Private

- (AIMBlistGroup *)loadGroup:(AIMFeedbagItem *)group inFeedbag:(AIMFeedbag *)feedbag {
	NSArray * orderAttr = [group groupOrder];
	if (!orderAttr) orderAttr = [NSArray array];
	NSMutableArray * buddies = [[NSMutableArray alloc] init];
	for (NSNumber * itemIDN in orderAttr) {
		UInt16 itemID = [itemIDN unsignedShortValue];
		AIMFeedbagItem * item = [feedbag itemWithItemID:itemID];
		if (item && [item classID] == FEEDBAG_BUDDY) {
			AIMBlistBuddy * buddy = [[AIMBlistBuddy alloc] initWithUsername:[item itemName]];
			buddy.feedbagItemID = [item itemID];
			[buddies addObject:buddy];
			[buddy release];
		}
	}
	AIMBlistGroup * blistgroup = [[AIMBlistGroup alloc] initWithBuddies:buddies name:[group itemName]];
	for (int i = 0; i < [buddies count]; i++) {
		AIMBlistBuddy * buddy = [buddies objectAtIndex:i];
		buddy.group = blistgroup;
	}
	[buddies release];
	[blistgroup setFeedbagGroupID:[group groupID]];
	return [blistgroup autorelease];
}

- (NSString *)description {
	NSMutableString * str = [NSMutableString string];
	for (AIMBlistGroup * g in groups) {
		[str appendFormat:@"%@\n", g];
	}
	return str;
}

- (void)dealloc {
	[tempBuddyHandler release];
	[groups release];
	[permit release];
	[deny release];
	[super dealloc];
}

@end
