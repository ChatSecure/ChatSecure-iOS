//
//  AIMMissedCall.m
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMMissedCall.h"


@implementation AIMMissedCall

@synthesize buddy;
@synthesize reason;
@synthesize totalCallsMissed;

- (id)initWithMissedCall:(AIMICBMMissedCall *)missedCall blist:(AIMBlist *)buddyList {
	if ((self = [super init])) {
		self.buddy = [buddyList buddyWithUsername:[[missedCall senderInfo] username]];
		self.totalCallsMissed = [missedCall numMissed];
		self.reason = AIMMissedCallReasonRateExceeded;
		switch ([missedCall reason]) {
			case MISSED_CALL_REASON_TOO_LARGE:
				self.reason = AIMMissedCallReasonTooLarge;
				break;
			case MISSED_CALL_REASON_RATE_EXCEEDED:
				self.reason = AIMMissedCallReasonRateExceeded;
				break;
			case MISSED_CALL_REASON_EVIL_SENDER:
				self.reason = AIMMissedCallReasonEvilSender;
				break;
			case MISSED_CALL_REASON_EVIL_RECEIVER:
				self.reason = AIMMissedCallReasonEvilReceiver;
				break;
		}
	}
	return self;
}

- (void)dealloc {
	self.buddy = nil;
	[super dealloc];
}


@end
