//
//  FTAddGroup.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbagTransaction.h"
#import "SNAC.h"
#import "AIMFeedbag+Search.h"


@interface FTAddGroup : NSObject <FeedbagTransaction> {
    NSString * groupName;
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithName:(NSString *)group;

@end
