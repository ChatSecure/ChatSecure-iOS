//
//  FTSetBArtItem.h
//  LibOrange
//
//  Created by Alex Nichol on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBArtID.h"
#import "FeedbagTransaction.h"

@interface FTSetBArtItem : NSObject <FeedbagTransaction> {
    AIMBArtID * bid;
	NSArray * snacs;
	NSInteger snacIndex;
}

- (id)initWithBArtID:(AIMBArtID *)bartID;

@end
