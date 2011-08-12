//
//  AIMFeedbagStatus.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "flipbit.h"

typedef enum {
	FBS_SUCCESS = 0,
	FBS_DB_ERROR = 1,
	FBS_NOT_FOUND = 2,
	FBS_ALREADY_EXISTS = 3,
	FBS_UNAVAILABLE = 5,
	FBS_BAD_REQUEST = 10,
	FBS_DB_TIME_OUT = 11,
	FBS_OVER_ROW_LIMIT = 12,
	FBS_NOT_EXECUTED = 13,
	FBS_AUTH_REQUIRED = 14,
	FBS_BAD_LOGINID = 16,
	FBS_OVER_BUDDY_LIMIT = 17,
	FBS_INSERT_SMART_GROUP = 20,
	FBS_TIMEOUT = 26
} AIMFeedbagStatusType;

@interface AIMFeedbagStatus : NSObject {
    NSArray * statTypeVals;
}

- (id)initWithCodeData:(NSData *)statusCodes;
- (NSUInteger)statusCodeCount;
- (AIMFeedbagStatusType)statusAtIndex:(NSUInteger)index;

@end
