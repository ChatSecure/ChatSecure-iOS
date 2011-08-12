//
//  AIMRateParamsChange.h
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMRateParams.h"
#import "SNAC.h"

#define RATE_CODE_CHANGE 1
#define RATE_CODE_WARNING 2
#define RATE_CODE_LIMIT 3
#define RATE_CODE_CLEAR 4

@interface AIMRateParamsChange : NSObject {
    NSArray * rateParams;
	UInt16 rateCode;
}

@property (readonly) NSArray * rateParams;
@property (readonly) UInt16 rateCode;

- (id)initWithSnac:(SNAC *)aSnac;

@end
