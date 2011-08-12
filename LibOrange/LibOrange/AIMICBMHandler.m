//
//  AIMICBMHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMHandler.h"

@interface AIMICBMHandler (Private)

- (void)_delegateInformMessage:(AIMICBMMessageToClient *)message;
- (void)_delegateInformMissedCall:(AIMICBMMissedCall *)call;

@end

@implementation AIMICBMHandler

@synthesize delegate;

- (id)initWithSession:(AIMSession *)theSession {
	if ((self = [super init])) {
		session = [theSession retain];
		[theSession addHandler:self];
	}
	return self;
}

- (void)sendMessage:(AIMMessage *)message {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	AIMICBMMessageToServer * servMsg = [[AIMICBMMessageToServer alloc] initWithMessage:[message message] toUser:[message buddy].username isAutoreply:[message isAutoresponse]];
	SNAC * theSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__CHANNEL_MSG_TOHOST) flags:0 requestID:[session generateReqID] data:[servMsg encodePacket]];
	[servMsg release];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:theSnac waitUntilDone:NO];
	[theSnac release];
}

- (void)handleIncomingSnac:(SNAC *)aSnac {
	NSAssert([NSThread currentThread] == [session backgroundThread], @"Running on incorrect thread");
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_ICBM, ICBM__CHANNEL_MSG_TOCLIENT), [aSnac snac_id])) {
		NSData * theData = [aSnac innerContents];
		AIMICBMMessageToClient * servMsg = [[AIMICBMMessageToClient alloc] initWithData:theData];
		[self performSelector:@selector(_delegateInformMessage:) onThread:session.mainThread withObject:servMsg waitUntilDone:NO];
		[servMsg release];
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_ICBM, ICBM__MISSED_CALLS), [aSnac snac_id])) {
		NSArray * missedCalls = [AIMICBMMissedCall decodeArray:[aSnac innerContents]];
		for (AIMICBMMissedCall * missedCall in missedCalls) {
			[self performSelector:@selector(_delegateInformMissedCall:) onThread:session.mainThread withObject:missedCall waitUntilDone:NO];
		}
	}
}

- (void)sessionClosed {
	[session removeHandler:self];
	[session autorelease];
	session = nil;
}

#pragma mark Private

- (void)_delegateInformMessage:(AIMICBMMessageToClient *)icbmMessage {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	if ([icbmMessage channel] != 1) return;
	if ([delegate respondsToSelector:@selector(aimICBMHandler:gotMessage:)]) {
		AIMMessage * message = [[AIMMessage alloc] initWithICBMMessage:icbmMessage fromBlist:[session buddyList]];
		[delegate aimICBMHandler:self gotMessage:message];
		[message release];
	}
}

- (void)_delegateInformMissedCall:(AIMICBMMissedCall *)theCall {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimICBMHandler:gotMissedCall:)]) {
		AIMMissedCall * call = [[AIMMissedCall alloc] initWithMissedCall:theCall blist:[session buddyList]];
		[delegate aimICBMHandler:self gotMissedCall:call];
		[call release];
	}
}

@end
