//
//  AIMNickWInfo+Update.m
//  LibOrange
//
//  Created by Alex Nichol on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMNickWInfo+Update.h"


@implementation AIMNickWInfo (Update)

- (AIMNickWInfo *)nickInfoByApplyingUpdate:(AIMNickWInfo *)newInfo {
	NSMutableArray * newAttributes = [NSMutableArray array];
	// attributes that were changed (not BART IDs).
	for (TLV * attribute in [self userAttributes]) {
		BOOL updated = NO;
		for (TLV * newAttribute in [newInfo userAttributes]) {
			if ([attribute type] == [newAttribute type]) {
				if ([attribute type] != TLV_BART_INFO) {
					updated = YES;
					[newAttributes addObject:newAttribute];
					break;
				}
			}
		}
		if (!updated && [attribute type] != TLV_BART_INFO) [newAttributes addObject:attribute];
	}
	// attributes that were added.
	for (TLV * attribute in [newInfo userAttributes]) {
		BOOL exists = NO;
		for (TLV * newAttribute in [self userAttributes]) {
			if ([newAttribute type] == [attribute type]) {
				exists = YES;
				break;
			}
		}
		if (!exists && [attribute type] != TLV_BART_INFO) {
			[newAttributes addObject:attribute];
		}
	}
	// update BART_IDs
	NSArray * newBids = [newInfo bartIDs];
	NSArray * finalBids = nil;
	if (newBids) {
		// finalBids = [self bartIDUpdateToList:newBids];
		finalBids = newBids;
	} else if ([self bartIDs]) {
		finalBids = [self bartIDs];
	}
	if (finalBids) {
		TLV * bartInfo = [[TLV alloc] initWithType:TLV_BART_INFO data:[AIMBArtID encodeArray:finalBids]];
		[newAttributes addObject:bartInfo];
		[bartInfo release];
	}
	AIMNickWInfo * nickInfo = [[AIMNickWInfo alloc] init];
	nickInfo.evil = newInfo.evil;
	nickInfo.userAttributes = newAttributes;
	nickInfo.username = newInfo.username;
	return [nickInfo autorelease];
}

@end

