//
//  AIMFeedbag+Search.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbag+Search.h"


@implementation AIMFeedbag (Search)

- (AIMFeedbagItem *)findRootGroup {
	for (AIMFeedbagItem * item in self.items) {
		if ([item classID] == FEEDBAG_GROUP) {
			if ([item itemID] == 0 && [item groupID] == 0) {
				return item;
			}
		}
	}
	return nil;
}

- (AIMFeedbagItem *)findPDMode {
	for (AIMFeedbagItem * item in self.items) {
		if ([item classID] == FEEDBAG_PDINFO) {
			if ([item groupID] == 0) {
				return item;
			}
		}
	}
	return nil;
}

- (AIMFeedbagItem *)denyWithUsername:(NSString *)username {
	NSString * compressed = [[username stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
	for (AIMFeedbagItem * item in self.items) {
		if ([item classID] == FEEDBAG_DENY) {
			NSString * nameCompressed = [[[item itemName] stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
			if ([nameCompressed isEqual:compressed]) {
				return item;
			}
		}
	}
	return nil;
}
- (AIMFeedbagItem *)permitWithUsername:(NSString *)username {
	NSString * compressed = [[username stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
	for (AIMFeedbagItem * item in self.items) {
		if ([item classID] == FEEDBAG_PERMIT) {
			NSString * nameCompressed = [[[item itemName] stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
			if ([nameCompressed isEqual:compressed]) {
				return item;
			}
		}
	}
	return nil;
}

@end
