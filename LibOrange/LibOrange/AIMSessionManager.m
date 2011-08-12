//
//  AIMSessionManager.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionManager.h"

@interface AIMSessionManager (private)

- (void)backgroundThreadMethod:(AIMLoginHostInfo *)hostInf;
- (void)threadComplete;
- (void)informSignonFailed;
- (void)informSignedOn;

- (OSCARConnection *)beginOscarConnection:(AIMLoginHostInfo *)hostInf;
- (BOOL)bossAuthenticate:(OSCARConnection *)connection host:(AIMLoginHostInfo *)hostInf;
- (void)configureHandlers;

@end

@interface AIMSessionManager (IOOperations)

- (UInt32)generateSNACRequestID;
- (BOOL)waitForHostReady;
- (SNAC *)waitOnConnectionForSnacID:(SNAC_ID)snacID;
- (BOOL)sendCookie:(NSData *)cookieData;
- (BOOL)sendSnac:(SNAC *)aSnac;

/* Signon methods */

- (BOOL)signonInitializeRateLimits;
- (BOOL)signonInitialQueries;
- (BOOL)signonAwaitQueriesResponses;
- (BOOL)signonRequestServices;
- (BOOL)signonConfigureICBM;

@end

@implementation AIMSessionManager

@synthesize backgroundThread;
@synthesize mainThread;
@synthesize session;
@synthesize delegate;
/* Handlers */
@synthesize feedbagHandler;
@synthesize messageHandler;
@synthesize tempBuddyHandler;
@synthesize statusHandler;
@synthesize bartHandler;
@synthesize rateHandler;
@synthesize rendezvousHandler;

- (id)initWithLoginHostInfo:(AIMLoginHostInfo *)hostInf delegate:(id<AIMSessionManagerDelegate>)_delegate {
	if ((self = [super init])) {
		self.delegate = _delegate;
		self.mainThread = [NSThread currentThread];
		NSThread * bgThread = [[NSThread alloc] initWithTarget:self selector:@selector(backgroundThreadMethod:) object:hostInf];
		self.backgroundThread = bgThread;
		[bgThread start];
		[bgThread release];
	}
	return self;
}

- (void)configureBuddyArt {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	NSAssert(bartHandler == nil, @"-configureBuddyArt called too many times.");
	bartHandler = [[AIMBArtHandler alloc] initWithSession:session];
	[statusHandler setBartHandler:bartHandler];
	[statusHandler performSelector:@selector(configureBart) onThread:[session backgroundThread] withObject:nil waitUntilDone:NO];
}

+ (BOOL)signonClientOnline:(OSCARConnection *)connection {
	[Debug log:@"+signonClientOnline: AIMSessionManager"];
	// Create a mutable data for our flags.
	NSMutableData * groupVersions = [NSMutableData data];
	
	// OSERVICE foodgroup
	UInt16 oservice = flipUInt16(1);
	UInt16 oservice_version = flipUInt16(4);
	UInt16 oservice_tool_id = flipUInt16(41);
	UInt16 oservice_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&oservice length:2];
	[groupVersions appendBytes:&oservice_version length:2];
	[groupVersions appendBytes:&oservice_tool_id length:2];
	[groupVersions appendBytes:&oservice_tool_version length:2];
	
	// FEEDBAG foodgroup
	UInt16 _feedbag = flipUInt16(19);
	UInt16 feedbag_version = flipUInt16(4);
	UInt16 feedbag_tool_id = flipUInt16(41);
	UInt16 feedbag_tool_version = flipUInt16(4);
	[groupVersions appendBytes:&_feedbag length:2];
	[groupVersions appendBytes:&feedbag_version length:2];
	[groupVersions appendBytes:&feedbag_tool_id length:2];
	[groupVersions appendBytes:&feedbag_tool_version length:2];
	
	// BUDDY foodgroup
	UInt16 buddy = flipUInt16(3);
	UInt16 buddy_version = flipUInt16(1);
	UInt16 buddy_tool_id = flipUInt16(41);
	UInt16 buddy_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&buddy length:2];
	[groupVersions appendBytes:&buddy_version length:2];
	[groupVersions appendBytes:&buddy_tool_id length:2];
	[groupVersions appendBytes:&buddy_tool_version length:2];
	
	// LOCATE foodgroup
	UInt16 locate = flipUInt16(2);
	UInt16 locate_version = flipUInt16(1);
	UInt16 locate_tool_id = flipUInt16(41);
	UInt16 locate_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&locate length:2];
	[groupVersions appendBytes:&locate_version length:2];
	[groupVersions appendBytes:&locate_tool_id length:2];
	[groupVersions appendBytes:&locate_tool_version length:2];
	
	// INVITE foodgroup
	UInt16 invite = flipUInt16(6);
	UInt16 invite_version = flipUInt16(1);
	UInt16 invite_tool_id = flipUInt16(41);
	UInt16 invite_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&invite length:2];
	[groupVersions appendBytes:&invite_version length:2];
	[groupVersions appendBytes:&invite_tool_id length:2];
	[groupVersions appendBytes:&invite_tool_version length:2];
	
	// ICBM foodgroup
	UInt16 icbm = flipUInt16(4);
	UInt16 icbm_version = flipUInt16(1);
	UInt16 icbm_tool_id = flipUInt16(41);
	UInt16 icbm_tool_version = flipUInt16(0xFF);
	[groupVersions appendBytes:&icbm length:2];
	[groupVersions appendBytes:&icbm_version length:2];
	[groupVersions appendBytes:&icbm_tool_id length:2];
	[groupVersions appendBytes:&icbm_tool_version length:2];
	
	// Now we create a SNAC for the OSERVICE.
	SNAC * oservice_s = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__CLIENT_ONLINE)
										   flags:0 requestID:1024 data:groupVersions];
	FLAPFrame * flap = [connection createFlapChannel:2 data:[oservice_s encodePacket]];
	[oservice_s release];
	return [connection writeFlap:flap];
}

#pragma mark OSCARConnection Delegate

- (void)oscarConnectionClosed:(OSCARConnection *)connection {
	
}

- (void)oscarConnectionPacketWaiting:(OSCARConnection *)connection {
	
}

#pragma mark Private

- (void)backgroundThreadMethod:(AIMLoginHostInfo *)hostInf {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	OSCARConnection * connection = [self beginOscarConnection:hostInf];
	if (!connection) {
		[self performSelector:@selector(informSignonFailed) onThread:mainThread withObject:nil waitUntilDone:NO];
		[self performSelector:@selector(threadComplete) onThread:mainThread withObject:nil waitUntilDone:NO];
		[pool drain];
		return;
	}
	
	if (![self bossAuthenticate:connection host:hostInf]) {
		[self performSelector:@selector(informSignonFailed) onThread:mainThread withObject:nil waitUntilDone:NO];
		[self performSelector:@selector(threadComplete) onThread:mainThread withObject:nil waitUntilDone:NO];
		[pool drain];
		return;
	}
	
	[self performSelector:@selector(informSignedOn) onThread:mainThread withObject:nil waitUntilDone:NO];
	
	while (true) {
		/* Run the loop for 10 seconds at a time. */
		NSDate * nextDate = [[NSDate alloc] initWithTimeIntervalSinceNow:1];
		[[NSRunLoop currentRunLoop] runUntilDate:nextDate];
		[nextDate release];
		if ([[NSThread currentThread] isCancelled]) break;
	}
	
	[self performSelector:@selector(threadComplete) onThread:mainThread withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (void)threadComplete {
	self.backgroundThread = nil;
}

- (void)informSignonFailed {
	if ([delegate respondsToSelector:@selector(aimSessionManagerSignonFailed:)]) {
		[delegate aimSessionManagerSignonFailed:self];
	}
}

- (void)informSignedOn {
	if ([delegate respondsToSelector:@selector(aimSessionManagerSignedOn:)]) {
		[delegate aimSessionManagerSignedOn:self];
	}
}

- (UInt32)generateSNACRequestID {
	if (!reqID) {
		reqID = arc4random();
	}
	reqID += 1;
	if (!reqID) reqID = 1;
	if (reqID >= 2147483648) reqID ^= 2147483648;
	return reqID;
}

#pragma mark Server Login

- (OSCARConnection *)beginOscarConnection:(AIMLoginHostInfo *)hostInf {
	OSCARConnection * connection = [(OSCARConnection *)[OSCARConnection alloc] initWithHost:[hostInf hostName] port:[hostInf port]];
	if (!connection) {
		return nil;
	}
	if (![connection connectToHost:nil]) {
		[connection release];
		return nil;
	}
	return [connection autorelease];
}

- (BOOL)bossAuthenticate:(OSCARConnection *)connection host:(AIMLoginHostInfo *)hostInf {
	initConn = connection;
	[connection setDelegate:self];
	if (![self waitForHostReady]) return NO;
	if (![self sendCookie:[hostInf cookie]]) return NO;
	
	// we are going to wait until we get a certain SNAC back.
	if (![self waitOnConnectionForSnacID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__HOST_ONLINE)])
		return NO;
	
	[connection setIsNonBlocking:YES];
	
	if (![self signonInitializeRateLimits]) return NO;
	if (![self signonInitialQueries]) return NO;
	if (![self signonAwaitQueriesResponses]) return NO;
	if (![self signonRequestServices]) return NO;
	if (![AIMSessionManager signonClientOnline:connection]) return NO;
	if (![self signonConfigureICBM]) return NO;
	
	session = [[AIMSession alloc] initWithConnection:connection];
	[session setMainThread:mainThread];
	[session setBackgroundThread:backgroundThread];
	[session setSessionDelegate:self];
	initConn = nil;
	
	[self configureHandlers];
	
	return YES;
}

- (void)configureHandlers {
	feedbagHandler = [[AIMFeedbagHandler alloc] initWithSession:session];
	messageHandler = [[AIMICBMHandler alloc] initWithSession:session];
	tempBuddyHandler = [[AIMTempBuddyHandler alloc] initWithSession:session];
	statusHandler = [[AIMStatusHandler alloc] initWithSession:session initialInfo:initialInfo];
	rateHandler = [[AIMRateLimitHandler alloc] initWithSession:session];
	rendezvousHandler = [[AIMRendezvousHandler alloc] initWithSession:session];
	
	[initialInfo release];
	initialInfo = nil;
	
	// query our online user info.
	[statusHandler queryUserInfo];
	statusHandler.feedbagHandler = feedbagHandler;
	
	[feedbagHandler setTempBuddyHandler:tempBuddyHandler];
	[feedbagHandler setFeedbagRights:feedbagRights];
	[feedbagHandler sendFeedbagRequest];
	[feedbagRights release];
	feedbagRights = nil;
}

#pragma mark IO Operations

- (BOOL)waitForHostReady {
	FLAPFrame * frame = [initConn readFlap];
	if (!frame) return NO;
	else return YES;
}
- (SNAC *)waitOnConnectionForSnacID:(SNAC_ID)snacID {
	while (YES) {
		FLAPFrame * flap = [initConn readFlap];
		if (![initConn isOpen]) return nil;
		SNAC * snac = [[SNAC alloc] initWithData:[flap frameData]];
		if (SNAC_ID_IS_EQUAL([snac snac_id], snacID)) return [snac autorelease];
		[snac release];
	}
}
- (BOOL)sendCookie:(NSData *)cookieData {
	[Debug log:@"-sendCookie: AIMSessionManager"];
	UInt32 version = flipUInt32(1);
	UInt8 multiconFlag = 1;
	
	TLV * cookie = [[TLV alloc] initWithType:TLV_LOGIN_COOKIE
										data:cookieData];
	
	TLV * multicon = [[TLV alloc] initWithType:TLV_MULTICONN_FLAGS
										  data:[NSData dataWithBytes:&multiconFlag length:1]];
	
	// the data that contains the cookie and other
	// data the OSCAR requires.
	NSMutableData * packetData = [NSMutableData data];
	[packetData appendBytes:&version length:4];
	[packetData appendData:[cookie encodePacket]];
	[packetData appendData:[multicon encodePacket]];
	
	// free the cookie packet
	[cookie release];
	[multicon release];
	
	FLAPFrame * flap = [initConn createFlapChannel:1
											  data:packetData];
	
	return [initConn writeFlap:flap];
}

- (BOOL)sendSnac:(SNAC *)aSnac {
	NSData * packetData = [aSnac encodePacket];
	FLAPFrame * flap = [initConn createFlapChannel:2
											  data:packetData];
	return [initConn writeFlap:flap];
}

#pragma mark Signon

- (BOOL)signonInitializeRateLimits {
	[Debug log:@"-signonInitializeRateLimits: AIMSessionManager"];
	SNAC * rateQuery = [[[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_PARAMS_QUERY)
										  flags:0
									  requestID:[self generateSNACRequestID] data:nil] autorelease];
	if (![self sendSnac:rateQuery]) {
		return NO;
	}
	
	SNAC * rateInfo = [self waitOnConnectionForSnacID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_PARAMS_REPLY)];
	if (!rateInfo) {
		return NO;
	}
	
	AIMRateParamsReply * reply = [[AIMRateParamsReply alloc] initWithData:[rateInfo innerContents]];
	
	if (!reply) {
		return NO;
	}
	
	NSMutableData * ackData = [[NSMutableData alloc] init];
	for (AIMRateParams * params in [reply rateParameters]) {
		UInt16 rateClass = flipUInt16([params classId]);
		[ackData appendBytes:&rateClass length:2];
	}
	
	// TODO: store reply as a global variable and use it for a future
	// rate handler.
	[reply release];
	
	SNAC * ratesAccept = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_ADD_PARAM_SUB)
											flags:0 requestID:[self generateSNACRequestID]
											 data:ackData];
	[ackData release];
	FLAPFrame * flap = [initConn createFlapChannel:2 data:[ratesAccept encodePacket]];
	[ratesAccept release];
	return [initConn writeFlap:flap];
}
- (BOOL)signonInitialQueries {
	// buddy rights query
	[Debug log:@"-signonInitialQueries: AIMSessionManager"];
	UInt16 qFlags = flipUInt16(15);
	NSData * flags = [NSData dataWithBytes:&qFlags length:2];
	TLV * buddyQueryInf = [[TLV alloc] initWithType:TLV_BUDDY__RIGHTS_QUERY_TAGS_FLAGS data:flags];
	SNAC * buddyQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BUDDY, BUDDY__RIGHTS_QUERY)
										   flags:0 requestID:[self generateSNACRequestID] data:[buddyQueryInf encodePacket]];
	[buddyQueryInf release];
	
	if (![self sendSnac:buddyQuery]) {
		[buddyQuery release];
		return NO;
	}
	[buddyQuery release];
	
	// permit/deny rights
	SNAC * pdQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_PD, PD__RIGHTS_QUERY) 
										flags:0 requestID:[self generateSNACRequestID] data:nil];
	if (![self sendSnac:pdQuery]) {
		[pdQuery release];
		return NO;
	}
	[pdQuery release];
	
	// query the LOCATE foodgroup rights.
	SNAC * locateQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__RIGHTS_QUERY) 
											flags:0 requestID:[self generateSNACRequestID] data:nil];
	if (![self sendSnac:locateQuery]) {
		[locateQuery release];
		return NO;
	}
	[locateQuery release];
	
	// get the feedbag rights, giving it our rules
	UInt16 feedbagRules = flipUInt16(0x7f);
	NSData * rulesData = [NSData dataWithBytes:&feedbagRules length:2];
	TLV * tagsFlags = [[TLV alloc] initWithType:TLV_FEEDBAG_RIGHTS_QUERY_TAGS_FLAGS data:rulesData];
	SNAC * feedbagRightsQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__RIGHTS_QUERY) 
												   flags:0 requestID:[self generateSNACRequestID] data:[tagsFlags encodePacket]];
	[tagsFlags release];
	if (![self sendSnac:feedbagRightsQuery]) {
		[feedbagRightsQuery release];
		return NO;
	}
	[feedbagRightsQuery release];
	
	return YES;
}
- (BOOL)signonAwaitQueriesResponses {
	BOOL gotFeedbagRights = NO;
	BOOL gotLocateRights = NO;
	BOOL gotPermitDenyRights = NO;
	BOOL gotBuddyRights = NO;
	while (!gotFeedbagRights || !gotLocateRights || !gotPermitDenyRights || !gotBuddyRights) {
		FLAPFrame * nextPacket = [initConn readFlap];
		if (![initConn isOpen]) return NO;
		if (nextPacket) {
			SNAC * snac = [[SNAC alloc] initWithData:[nextPacket frameData]];
			if (snac && [snac isLastResponse]) {
				/* TODO: handle the feedbag_rights_reply. */
				if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_BUDDY, BUDDY__RIGHTS_REPLY))) gotBuddyRights = YES;
				else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_PD, PD__RIGHTS_REPLY))) gotPermitDenyRights = YES;
				else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_LOCATE, LOCATE__RIGHTS_REPLY))) gotLocateRights = YES;
				else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__RIGHTS_REPLY))) {
					gotFeedbagRights = YES;
					feedbagRights = [[AIMFeedbagRights alloc] initWithRightsArray:[snac innerContents]];
				}
			}
			[snac release];
		}
	}
	[Debug log:@"-signonAwaitQueriesResponses: got responses."];
	return YES;
}
- (BOOL)signonRequestServices {
	SNAC * infoRequest = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_QUERY)
											flags:0 requestID:[self generateSNACRequestID] data:nil];
	if (![self sendSnac:infoRequest]) {
		[infoRequest release];
		return NO;
	}
	[infoRequest release];
	
	SNAC * infoResponse = [self waitOnConnectionForSnacID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_UPDATE)];
	if (!infoResponse) return NO;
	initialInfo = [[AIMNickWInfo alloc] initWithData:[infoResponse innerContents]];
	
	SNAC * paramQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__PARAMETER_QUERY) 
										   flags:0 requestID:[self generateSNACRequestID] data:nil];
	if (![self sendSnac:paramQuery]) {
		[paramQuery release];
		return NO;
	}
	[paramQuery release];
	
	return YES;
}
- (BOOL)signonConfigureICBM {
	NSMutableData * addParameters = [NSMutableData data];
	UInt16 channel = flipUInt16(0);
	UInt32 flags = flipUInt32(8 | 1 | 2 | 0x10 | 0x100); // EVENTS_ALLOWED
	UInt16 maxLen = flipUInt16(8000);
	UInt16 maxSourceEvil = flipUInt16(500);
	UInt16 maxDestEvil = flipUInt16(500);
	UInt32 minInterval = flipUInt32(kMinICBMInterval); // max miliseconds between IM events.
	[addParameters appendBytes:&channel length:2];
	[addParameters appendBytes:&flags length:4];
	[addParameters appendBytes:&maxLen length:2];
	[addParameters appendBytes:&maxSourceEvil length:2];
	[addParameters appendBytes:&maxDestEvil length:2];
	[addParameters appendBytes:&minInterval length:4];
	SNAC * parametersAdd = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__ADD_PARAMETERS)
											  flags:0 requestID:[self generateSNACRequestID] data:addParameters];
	if (![self sendSnac:parametersAdd]) {
		[parametersAdd release];
		return NO;
	}
	[parametersAdd release];
	
	return YES;
}

#pragma mark Session

- (void)aimSessionClosed:(AIMSession *)session {
	// if something is going to release us, we do not want it to
	// affect us until after we finish closing session handlers.
	[self retain];
	if ([delegate respondsToSelector:@selector(aimSessionManagerSignedOff:)]) {
		[delegate aimSessionManagerSignedOff:self];
	}
	[feedbagHandler sessionClosed];
	[messageHandler sessionClosed];
	[tempBuddyHandler sessionClosed];
	[statusHandler sessionClosed];
	[bartHandler sessionClosed];
	[bartHandler closeBArtConnection];
	[rateHandler sessionClosed];
	[rendezvousHandler sessionClosed];
	self.backgroundThread = nil;
	[self release];
}

#pragma mark Memory Management

- (void)dealloc {
	if (initConn) {
		if ([initConn isOpen]) [initConn disconnect];
		[initConn release];
	}
	[feedbagRights release];
	[initialInfo release];
	self.mainThread = nil;
	
	[feedbagHandler release];
	[messageHandler release];
	[tempBuddyHandler release];
	[statusHandler release];
	[bartHandler release];
	[rateHandler release];
	[rendezvousHandler release];
	
	[session setSessionDelegate:nil];
	[session release];
	[super dealloc];
}

@end
