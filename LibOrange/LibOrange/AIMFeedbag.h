//
//  AIMFeedbag.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbagItem.h"
#import "SNAC.h"
#import "TLV.h"

@interface AIMFeedbag : NSObject <NSCoding> {
	UInt8 numClasses;
	NSMutableArray * items;
	UInt32 updateTime;
}

@property (readonly) NSMutableArray * items;
@property (readwrite) UInt32 updateTime;
@property (readonly) UInt8 numClasses;

- (id)initWithSnac:(SNAC *)feedbagReply;
- (id)initWithData:(NSData *)data;

- (NSData *)encodePacket;

- (AIMFeedbagItem *)itemWithItemID:(UInt16)itemID;
- (AIMFeedbagItem *)groupWithGroupID:(UInt16)groupID;

- (UInt16)randomItemID;
- (UInt16)randomGroupID;

- (void)appendFeedbagItems:(AIMFeedbag *)anotherFeedbag;

@end
