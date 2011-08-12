//
//  FTSetPDMode.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbagTransaction.h"
#import "AIMFeedbag+Search.h"

#define PD_MODE_PERMIT_ALL 1
#define PD_MODE_DENY_ALL 2
#define PD_MODE_PERMIT_SOME 3
#define PD_MODE_DENY_SOME 4
#define PD_MODE_PERMIT_ON_LIST 5

#define PD_FLAGS_APPLIES_IM 1
#define PD_FLAGS_HIDE_WIRELESS 2

NSString * PD_MODE_TOSTR (UInt8 pdMode);


@interface FTSetPDMode : NSObject <FeedbagTransaction> {
    NSArray * snacs;
	NSInteger snacIndex;
	
	UInt8 pdMode;
	UInt32 pdFlags;
}

- (id)initWithPDMode:(UInt8)_pdMode pdFlags:(UInt32)_pdFlags; 

@end
