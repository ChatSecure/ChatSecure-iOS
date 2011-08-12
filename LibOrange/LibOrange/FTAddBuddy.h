//
//  FTAddBuddy.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBlistGroup.h"
#import "FeedbagTransaction.h"

@interface FTAddBuddy : NSObject <FeedbagTransaction> {
    NSString * username;
	AIMBlistGroup * group;
	
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithUsername:(NSString *)nick group:(AIMBlistGroup *)theGroup;

@end
