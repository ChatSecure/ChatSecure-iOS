//
//  FTDelDeny.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbagTransaction.h"
#import "AIMFeedbag+Search.h"


@interface FTDelDeny : NSObject <FeedbagTransaction> {
    NSString * denyUsername;
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithUsername:(NSString *)username;

@end
