//
//  AIMFeedbagRights.h
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLV.h"
#import "flipbit.h"


@interface AIMFeedbagRights : NSObject {
    UInt16 maxItemAttributes;
	UInt16 maxClientItems;
	UInt16 maxItemNameLength;
	UInt16 maxRecentBuddies;
	UInt16 maxBuddiesPerGroup;
}

@property (readonly) UInt16 maxItemAttributes;
@property (readonly) UInt16 maxClientItems;
@property (readonly) UInt16 maxItemNameLength;
@property (readonly) UInt16 maxRecentBuddies;
@property (readonly) UInt16 maxBuddiesPerGroup;

- (id)initWithRightsArray:(NSData *)feedbagRightsReply;

@end
