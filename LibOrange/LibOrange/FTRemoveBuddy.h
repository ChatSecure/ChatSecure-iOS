//
//  FRRemoveBuddy.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbagTransaction.h"

@interface FTRemoveBuddy : NSObject <FeedbagTransaction> {
    AIMBlistBuddy * buddy;
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithBuddy:(AIMBlistBuddy *)aBuddy;

@end
