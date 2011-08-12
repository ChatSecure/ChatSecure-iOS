//
//  AIMStatusHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMStatusHandler.h"

@interface AIMStatusHandler (Private)

- (void)handleBuddyArrived:(AIMNickWInfo *)nickInfo;
- (void)handleBuddyDeparted:(AIMNickWInfo *)nickInfo;
- (void)handleBuddyRejected:(NSString *)rejected;
- (AIMBuddyStatus *)statusFromNickInfo:(AIMNickWInfo *)info fetchAwayData:(BOOL *)fetchAway;

#pragma mark User Status

- (void)setStatusText:(NSString *)statText;
- (void)setUnavailableText:(NSString *)statText;
- (void)setCapabilities:(NSArray *)caps;
- (void)sendIdleNote:(UInt32)idleSeconds;

- (void)handleUserInfoUpdate:(AIMNickWInfo *)newInfo;
- (void)_delegateInformNewStatus;
- (void)_delegateInformBuddyIconChange:(AIMBlistBuddy *)theBuddy;
- (void)_delegateInformBArtConnected;
- (void)_fetchNickInfoIcon:(AIMNickWInfo *)nickWIcon;

@end

@implementation AIMStatusHandler

@synthesize delegate;
@synthesize userStatus;
@synthesize bartHandler;
@synthesize feedbagHandler;

- (id)initWithSession:(AIMSession *)theSession initialInfo:(AIMNickWInfo *)initInfo {
	if ((self = [super init])) {
		session = [theSession retain];
		[theSession addHandler:self];
		userStatus = [[AIMBuddyStatus offlineStatus] retain];
		[self performSelector:@selector(handleUserInfoUpdate:) onThread:session.mainThread withObject:initInfo waitUntilDone:NO];
	}
	return self;
}

- (void)configureBart {
	NSAssert([NSThread currentThread] == [session backgroundThread], @"Running on incorrect thread");
	[bartHandler setDelegate:self];
	[bartHandler startupBArt];
}

- (void)aimBArtHandlerConnectedToBArt:(AIMBArtHandler *)handler {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	[self _delegateInformBArtConnected];
}

- (void)aimBArtHandlerConnectFailed:(AIMBArtHandler *)handler {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
}

- (void)aimBArtHandlerDisconnected:(AIMBArtHandler *)handler {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	[handler performSelector:@selector(startupBArt) onThread:[session backgroundThread] withObject:nil waitUntilDone:NO];
}

- (void)aimBArtHandler:(AIMBArtHandler *)handler gotBuddyIcon:(AIMBuddyIcon *)icns forUser:(NSString *)loginID {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	AIMBlistBuddy * buddy = [[session buddyList] buddyWithUsername:loginID];
	NSArray * buddies = [[session buddyList] buddiesWithUsername:loginID];
	if (buddy && [buddies count] < 2) {
		[buddy setBuddyIcon:icns];
		[self _delegateInformBuddyIconChange:buddy];
	} else if ([buddies count] > 1) {
		for (AIMBlistBuddy * theBuddy in buddies) {
			[theBuddy setBuddyIcon:icns];
			[self _delegateInformBuddyIconChange:theBuddy];
		}
	}
}

- (void)aimBArtHandler:(AIMBArtHandler *)handler uploadedBArtID:(AIMBArtID *)newBartID {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	FTSetBArtItem * setBid = [[FTSetBArtItem alloc] initWithBArtID:newBartID];
	[feedbagHandler pushTransaction:setBid];
	[setBid release];
}

- (void)aimBArtHandler:(AIMBArtHandler *)handler uploadFailed:(UInt16)statusCode {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	AIMIconUploadErrorType errorType = AIMIconUploadErrorTypeOther;
	switch (statusCode) {
		case BART_STATUS_CODE_TOBIG:
			errorType = AIMIconUploadErrorTypeTooBig;
			break;
		case BART_STATUS_CODE_TOSMALL:
			errorType = AIMIconUploadErrorTypeTooSmall;
			break;
		case BART_STATUS_CODE_INVALID:
			errorType = AIMIconUploadErrorTypeInvalid;
			break;
		case BART_STATUS_CODE_BANNED:
			errorType = AIMIconUploadErrorTypeBanned;
			break;
		default:
			break;
	}
	if ([delegate respondsToSelector:@selector(aimStatusHandler:setIconFailed:)]) {
		[delegate aimStatusHandler:self setIconFailed:errorType];
	}
}

#pragma mark Network Handlers

- (void)handleIncomingSnac:(SNAC *)aSnac {
	NSAssert([NSThread currentThread] == session.backgroundThread, @"Running on incorrect thread");
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__ARRIVED), [aSnac snac_id])) {
		NSArray * arrivedPeople = [AIMNickWInfo decodeArray:[aSnac innerContents]];
		for (AIMNickWInfo * nickInf in arrivedPeople) {
			[self performSelector:@selector(handleBuddyArrived:) onThread:session.mainThread withObject:nickInf waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__DEPARTED), [aSnac snac_id])) {
		NSArray * departedPeople = [AIMNickWInfo decodeArray:[aSnac innerContents]];
		for (AIMNickWInfo * nickInf in departedPeople) {
			[self performSelector:@selector(handleBuddyDeparted:) onThread:session.mainThread withObject:nickInf waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__REJECT_NOTIFICATION), [aSnac snac_id])) {
		NSArray * rejectedPeople = decodeString8Array([aSnac innerContents]);
		for (NSString * uname in rejectedPeople) {
			[self performSelector:@selector(handleBuddyRejected:) onThread:session.mainThread withObject:uname waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_UPDATE), [aSnac snac_id])) {
		AIMNickWInfo * updateInf = [[AIMNickWInfo alloc] initWithData:[aSnac innerContents]];
		if (updateInf) 
			[self performSelector:@selector(handleUserInfoUpdate:) onThread:session.mainThread withObject:updateInf waitUntilDone:NO];
		else {
			NSLog(@"Unfatal ERROR: Got invalid NickWInfo from OSERVICE");
			NSLog(@"Nick info dump: %@", [aSnac innerContents]);
		}
		[updateInf release];
	}
}

- (void)sessionClosed {
	[session removeHandler:self];
	[session autorelease];
	[bartHandler setDelegate:nil];
	self.bartHandler = nil;
	self.feedbagHandler = nil;
}

- (AIMBuddyStatus *)statusFromNickInfo:(AIMNickWInfo *)info fetchAwayData:(BOOL *)fetchAway {
	UInt16 unavailable = [info nickFlags] & NICKFLAGS_UNAVAILABLE;
	if (unavailable != 0) {
		if (fetchAway) *fetchAway = NO;
	} else if (fetchAway) *fetchAway = YES;
	
	AIMBuddyStatusType type = AIMBuddyStatusAvailable;
	if (unavailable != 0) type = AIMBuddyStatusAway;
	else if ([info nickFlags] == 0) type = AIMBuddyStatusOffline;
	
	UInt16 idleTime = 0;
	for (TLV * t in [info userAttributes]) {
		if ([t type] == TLV_IDLE_TIME && [[t tlvData] length] == 2) {
			idleTime = flipUInt16(*(const UInt16 *)[[t tlvData] bytes]);
		}
	}
	
	NSString * statusMessage = @"";
	NSArray * bartIds = [info bartIDs];
	if (bartIds) {
		for (AIMBArtID * bid in bartIds) {
			if ([bid type] == BART_TYPE_STATUS_STR) {
				statusMessage = decodeString16([bid opaqueData]);
				if (!statusMessage) statusMessage = @"";
			}
		}
	}
	
	NSArray * caps = [info buddyCapabilities];
	
	return [[[AIMBuddyStatus alloc] initWithMessage:statusMessage type:type timeIdle:idleTime caps:caps] autorelease];
}

#pragma mark Arrived & Departed

- (void)handleBuddyArrived:(AIMNickWInfo *)nickInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([nickInfo nickFlags] == 0) {
		[self handleBuddyDeparted:nickInfo];
	} else {
		AIMBArtID * bid = [nickInfo bartBuddyIcon];
		// buddy is online, extract their status and set their stuff.
		BOOL wantsAwayData = NO;
		AIMBuddyStatus * status = [self statusFromNickInfo:nickInfo fetchAwayData:&wantsAwayData];
		NSArray * allBuddies = [[session buddyList] buddiesWithUsername:[nickInfo username]];
		BOOL hasFetchedIcon = NO;
		for (AIMBlistBuddy * buddy in allBuddies) {
			if (bid) {
				AIMBArtID * oldBuddyIcon = [[buddy buddyIcon] bartItem];
				if ((![buddy buddyIcon] || ![bid isEqualToBartID:oldBuddyIcon]) && !hasFetchedIcon) {
					hasFetchedIcon = YES;
					[self performSelector:@selector(_fetchNickInfoIcon:) onThread:[session backgroundThread] withObject:nickInfo waitUntilDone:NO];
				}
			}
			// non-present CAPS => use previous ones.
			if (![status capabilities]) {
				if ([[buddy status] capabilities]) {
					[status setCapabilities:[[buddy status] capabilities]];
				}
			}
			if (![[buddy status] isEqualToStatus:status]) {
				if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
					[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
				}
				[buddy setStatus:status];
			}
		}
		if ([allBuddies count] == 0) {
			AIMBlistBuddy * tempBuddy = [[session buddyList] buddyWithUsername:[nickInfo username]];
			if (bid) {
				AIMBArtID * oldBuddyIcon = [[tempBuddy buddyIcon] bartItem];
				if ((![tempBuddy buddyIcon] || ![bid isEqualToBartID:oldBuddyIcon])) {
					[self performSelector:@selector(_fetchNickInfoIcon:) onThread:[session backgroundThread] withObject:nickInfo waitUntilDone:NO];
				}
			}
			// non-present CAPS => use previous ones.
			if ([[tempBuddy status] capabilities] && ![status capabilities]) {
				[status setCapabilities:[[tempBuddy status] capabilities]];
			}
			if (![[tempBuddy status] isEqualToStatus:status]) {
				if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
					[delegate aimStatusHandler:self buddy:tempBuddy statusChanged:status];
				}
				[tempBuddy setStatus:status];
			}
		}
	}
}
- (void)handleBuddyDeparted:(AIMNickWInfo *)nickInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	AIMBuddyStatus * status = [AIMBuddyStatus offlineStatus];
	NSArray * allBuddies = [[session buddyList] buddiesWithUsername:[nickInfo username]];
	for (AIMBlistBuddy * buddy in allBuddies) {
		if (![[buddy status] isEqualToStatus:status]) {
			if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
				[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
			}
			[buddy setStatus:status];
		}
	}
	if ([allBuddies count] == 0) {
		AIMBlistBuddy * tempBuddy = [[session buddyList] buddyWithUsername:[nickInfo username]];
		if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
			[delegate aimStatusHandler:self buddy:tempBuddy statusChanged:status];
		}
		[tempBuddy setStatus:status];
	}
}

- (void)handleBuddyRejected:(NSString *)rejected {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimStatusHandler:buddyRejected:)]) {
		[delegate aimStatusHandler:self buddyRejected:rejected];
	}
	AIMBuddyStatus * status = [AIMBuddyStatus rejectedStatus];
	NSArray * allBuddies = [[session buddyList] buddiesWithUsername:rejected];
	for (AIMBlistBuddy * buddy in allBuddies) {
		if (![[buddy status] isEqualToStatus:status]) {
			if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
				[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
			}
			[buddy setStatus:status];
		}
	}
}

#pragma mark User Status (Setting)

- (void)updateStatus:(AIMBuddyStatus *)newStatus {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	BOOL isCorrectType = [newStatus statusType] == AIMBuddyStatusAvailable || [newStatus statusType] == AIMBuddyStatusAway;
	NSAssert(isCorrectType, @"Cannot use this status type for a status update.");
	NSAssert([newStatus statusMessage], @"Status message should be empty string instead of nil.");
	if ([newStatus isEqualToStatus:userStatus]) {
		return;
	}
	switch ([newStatus statusType]) {
		case AIMBuddyStatusAvailable:
			[self setUnavailableText:nil];
			[self setStatusText:[newStatus statusMessage]];
			break;
		case AIMBuddyStatusAway:
			[self setUnavailableText:[newStatus statusMessage]];
			[self setStatusText:[newStatus statusMessage]];
			break;
		default:
			break;
	}
	
	if ([newStatus idleTime] > 0) {
		UInt32 idleSecs = [newStatus idleTime] * 60;
		[self sendIdleNote:idleSecs];
	} else if ([userStatus idleTime] != 0) {
		[self sendIdleNote:0];
	}
	
	if ([newStatus capabilities]) {
		[self setCapabilities:[newStatus capabilities]];
	}
}

- (void)updateUserIcon:(NSData *)newIcon {
	if ([NSThread currentThread] != [session backgroundThread]) {
		[self performSelector:@selector(updateUserIcon:) onThread:[session backgroundThread] withObject:newIcon waitUntilDone:NO];
		return;
	}
	[bartHandler uploadBArtData:newIcon forType:BART_TYPE_BUDDY_ICON];
}

- (void)setStatusText:(NSString *)statText {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([statText length] > 253) {
		[self setStatusText:[[statText substringWithRange:NSMakeRange(0, 250)] stringByAppendingFormat:@"..."]];
		return;
	}
	NSData * statusData = encodeString16(statText);
	AIMBArtID * statusStr = [[AIMBArtID alloc] initWithType:BART_TYPE_STATUS_STR flags:BART_FLAG_DATA opaqueData:statusData];
	TLV * statusObj = [[TLV alloc] initWithType:TLV_BART_INFO data:[statusStr encodePacket]];
	
	SNAC * uInfoUpdate = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__SET_NICKINFO_FIELDS) flags:0 requestID:[session generateReqID] data:[statusObj encodePacket]];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:uInfoUpdate waitUntilDone:NO];
	[uInfoUpdate release];
	
	[statusObj release];
	[statusStr release];
}
- (void)setUnavailableText:(NSString *)statText {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	NSData * awayData = [statText dataUsingEncoding:NSUTF8StringEncoding];
	TLV * unavail = [[TLV alloc] initWithType:TLV_UNAVAILABLE_DATA data:awayData];
	SNAC * locateUpdate = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__SET_INFO) flags:0 requestID:[session generateReqID] data:[unavail encodePacket]];
	[unavail release];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:locateUpdate waitUntilDone:NO];
	[locateUpdate release];
}
- (void)setCapabilities:(NSArray *)caps {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	NSMutableData * capsData = [NSMutableData data];
	for (AIMCapability * cap in caps) {
		[capsData appendData:[cap uuid]];
	}
	TLV * unavail = [[TLV alloc] initWithType:TLV_CAPABILITIES data:capsData];
	SNAC * locateUpdate = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__SET_INFO) flags:0 requestID:[session generateReqID] data:[unavail encodePacket]];
	[unavail release];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:locateUpdate waitUntilDone:NO];
	[locateUpdate release];
}

- (void)sendIdleNote:(UInt32)idleSeconds {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	UInt32 idleSecondsFlip = flipUInt32(idleSeconds);
	SNAC * idleNote = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__IDLE_NOTIFICATION) flags:0 requestID:[session generateReqID] data:[NSData dataWithBytes:&idleSecondsFlip length:4]];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:idleNote waitUntilDone:NO];
	[idleNote release];
}

#pragma mark User Status (Reading)

- (void)queryUserInfo {
	NSAssert([NSThread currentThread] == session.backgroundThread, @"Running on incorrect thread");
	SNAC_ID snacID = SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_QUERY);
	SNAC * query = [[SNAC alloc] initWithID:snacID flags:0 requestID:[session generateReqID] data:nil];
	[session writeSnac:query];
	[query release];
}

- (void)handleUserInfoUpdate:(AIMNickWInfo *)newInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	AIMNickWInfo * updated = (lastInfo == nil ? newInfo : [lastInfo nickInfoByApplyingUpdate:newInfo]);
	[lastInfo release];
	lastInfo = [updated retain];
	AIMBuddyStatus * ourStatus = [self statusFromNickInfo:updated fetchAwayData:NULL];
	if ([userStatus isEqualToStatus:ourStatus]) {
		return;
	}
	[userStatus release];
	userStatus = [ourStatus retain];
	[self _delegateInformNewStatus];
}

- (void)_delegateInformNewStatus {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimStatusHandlerUserStatusUpdated:)]) {
		[delegate aimStatusHandlerUserStatusUpdated:self];
	}
}

- (void)_delegateInformBuddyIconChange:(AIMBlistBuddy *)theBuddy {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimStatusHandler:buddyIconChanged:)]) {
		[delegate aimStatusHandler:self buddyIconChanged:theBuddy];
	}
}

- (void)_delegateInformBArtConnected {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimStatusHandlerBArtConnected:)]) {
		[delegate aimStatusHandlerBArtConnected:self];
	}
}

- (void)_fetchNickInfoIcon:(AIMNickWInfo *)nickWIcon {
	// NSLog(@"Fetch buddy icon: %@", [nickWIcon username]);
	NSAssert([NSThread currentThread] == session.backgroundThread, @"Running on incorrect thread");
	if (bartHandler) [bartHandler fetchBArtIcon:[nickWIcon bartBuddyIcon] forUser:[nickWIcon username]];
}

- (void)dealloc {
	self.bartHandler = nil;
	self.feedbagHandler = nil;
	[userStatus release];
	[lastInfo release];
	[super dealloc];
}

@end
