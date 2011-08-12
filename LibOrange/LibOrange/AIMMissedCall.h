//
//  AIMMissedCall.h
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMICBMMissedCall.h"
#import "AIMBlist.h"

typedef enum {
	AIMMissedCallReasonTooLarge,
	AIMMissedCallReasonRateExceeded,
	AIMMissedCallReasonEvilSender,
	AIMMissedCallReasonEvilReceiver
} AIMMissedCallReason;

@interface AIMMissedCall : NSObject {
    AIMBlistBuddy * buddy;
	AIMMissedCallReason reason;
	int totalCallsMissed;
}

@property (nonatomic, retain) AIMBlistBuddy * buddy;
@property (readwrite) AIMMissedCallReason reason;
@property (readwrite) int totalCallsMissed;

- (id)initWithMissedCall:(AIMICBMMissedCall *)missedCall blist:(AIMBlist *)buddyList;

@end
