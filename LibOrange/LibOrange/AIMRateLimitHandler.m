//
//  AIMRateLimitHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateLimitHandler.h"

@interface AIMRateLimitHandler (Private)

- (void)_delegateInformRateAlert:(AIMRateNotificationInfo *)noteInfo;

@end

@implementation AIMRateLimitHandler

@synthesize delegate;
@synthesize initialParams;

- (id)initWithSession:(AIMSession *)theSession {
	if ((self = [super init])) {
		session = [theSession retain];
		[theSession addHandler:self];
	}
	return self;
}

- (void)handleIncomingSnac:(SNAC *)aSnac {
	NSAssert([NSThread currentThread] == session.backgroundThread, @"Running on incorrect thread");
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_PARAM_CHANGE), [aSnac snac_id])) {
		// TODO: handle this by parsing and such.
		AIMRateParamsChange * change = [[AIMRateParamsChange alloc] initWithSnac:aSnac];
		if (change) {
			if ([change rateCode] != RATE_CODE_CHANGE) {
				// warning!
				AIMRateClassType type = AIMRateClassTypeSnacs;
				AIMRateAlertType alert = AIMRateAlertTypeOther;
				if ([change rateCode] == RATE_CODE_CLEAR) alert = AIMRateAlertTypeClear;
				if ([change rateCode] == RATE_CODE_LIMIT) alert = AIMRateAlertTypeLimit;
				if ([change rateCode] == RATE_CODE_WARNING) alert = AIMRateAlertTypeWarning;
				AIMRateNotificationInfo * info = [AIMRateNotificationInfo notificationInfoWithClass:type reason:alert];
				[self performSelector:@selector(_delegateInformRateAlert:) onThread:session.mainThread withObject:info waitUntilDone:NO];
			}
			[change release];
		}
	}
}

- (void)sessionClosed {
	[session removeHandler:self];
	[session autorelease];
	session = nil;
}

- (void)_delegateInformRateAlert:(AIMRateNotificationInfo *)noteInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimRateLimitHandler:gotRateAlert:)]) {
		[delegate aimRateLimitHandler:self gotRateAlert:noteInfo];
	}
}

- (void)dealloc {
	self.initialParams = nil;
	[super dealloc];
}

@end
