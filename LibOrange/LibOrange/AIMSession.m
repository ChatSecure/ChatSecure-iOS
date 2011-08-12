//
//  AIMSession.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSession.h"


@implementation AIMSession

@synthesize connection;
@synthesize mainThread;
@synthesize backgroundThread;
@synthesize username;
@synthesize sessionDelegate;
@synthesize buddyList;

- (id)initWithConnection:(OSCARConnection *)theConnection {
	if ((self = [super init])) {
		handlers = [[NSMutableArray alloc] init];
		connection = [theConnection retain];
		[connection setDelegate:self];
		reqIDLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)addHandler:(id<AIMSessionHandler>)aHandler {
	[handlers addObject:aHandler];
}
- (void)removeHandler:(id<AIMSessionHandler>)theHandler {
	[handlers removeObject:theHandler];
}
- (void)closeConnection {
	if (![connection isOpen]) return;
	[Debug log:@"Sending disconnect"];
	FLAPFrame * flapDisconnect = [connection createFlapChannel:4 data:[NSData data]];
	[connection writeFlap:flapDisconnect];
	[connection disconnect];
}

- (UInt32)generateReqID {
	[reqIDLock lock];
	if (!reqID) {
		reqID = arc4random();
	}
	reqID += 1;
	if (!reqID) reqID = 1;
	if (reqID >= 2147483648) reqID = 2;
	UInt32 reqIDTep = reqID;
	[reqIDLock unlock];
	[Debug log:[NSString stringWithFormat:@"-generateReqID: %d", reqIDTep]];
	return reqIDTep;
}
- (BOOL)writeSnac:(SNAC *)aSnac {
	NSData * packetData = [aSnac encodePacket];
	FLAPFrame * flap = [connection createFlapChannel:2
											  data:packetData];
	return [connection writeFlap:flap];
}

#pragma mark OSCAR Connection

- (void)oscarConnectionClosed:(OSCARConnection *)theConnection {
	[Debug log:@"-oscarConnectionClosed:"];
	[backgroundThread cancel];
	self.backgroundThread = nil;
	if ([sessionDelegate respondsToSelector:@selector(aimSessionClosed:)]) {
		[sessionDelegate performSelector:@selector(aimSessionClosed:) onThread:mainThread withObject:nil waitUntilDone:NO];
	}
	[connection autorelease];
	connection = nil;
}

- (void)oscarConnectionPacketWaiting:(OSCARConnection *)theConnection {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	FLAPFrame * packet = [theConnection readFlap];
	if (packet) {
		[Debug log:[NSString stringWithFormat:@"Got packet of channel: %d", [packet channel]]];
		if ([packet channel] == 4) {
			[Debug log:@"Got disconnect packet"];
			[connection disconnect];
			return;
		}
		SNAC * theSnac = [[SNAC alloc] initWithData:[packet frameData]];
		if (theSnac) {
			[Debug log:[NSString stringWithFormat:@"Got SNAC packet {%d,%d}", theSnac.snac_id.foodgroup, theSnac.snac_id.type]];
			for (id<AIMSessionHandler> handler in handlers) {
				[handler handleIncomingSnac:theSnac];
			}
		} else {
			[Debug log:[NSString stringWithFormat:@"Failed to load SNAC from FLAP: %@", [packet encodePacket]]];
		}
		[theSnac release];
	}
	[pool drain];
}

- (void)dealloc {
	[Debug log:@"-dealloc: AIMSession"];
	self.username = nil;
	[reqIDLock release];
	self.backgroundThread = nil;
	self.buddyList = nil;
	[handlers release];
	[connection release];
	[super dealloc];
}

@end
