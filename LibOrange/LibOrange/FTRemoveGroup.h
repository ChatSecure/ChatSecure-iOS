//
//  FTRemoveGroup.h
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbagTransaction.h"
#import "AIMFeedbag+Search.h"
#import "AIMBlistGroup.h"

@interface FTRemoveGroup : NSObject <FeedbagTransaction> {
    AIMBlistGroup * group;
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithGroup:(AIMBlistGroup *)aGroup;

@end
