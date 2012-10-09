//
//  MyTest.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyTest.h"

#define kSignoffTime 500

static void stripNL (char * buff) {
	if (strlen(buff) == 0) return;
	if (buff[strlen(buff) - 1] == '\n') {
		buff[strlen(buff) - 1] = 0;
	}
}

@implementation MyTest

- (void)beginTest {
	// uncomment to see a LOT of console output
	// [Debug setDebuggingEnabled:YES];
	printf("LibOrange (v: %s): -beginTest\n", lib_orange_version_string);
	mainThread = [NSThread currentThread];
	char buffer[512];
	printf("Enter username: ");
	fgets(buffer, 512, stdin);
	stripNL(buffer);
	NSString * username = [NSString stringWithUTF8String:buffer];
	
	printf("Enter password: ");
	fgets(buffer, 512, stdin);
	stripNL(buffer);
	NSString * password = [NSString stringWithUTF8String:buffer];
	
	login = [[AIMLogin alloc] initWithUsername:username password:password];
	[login setDelegate:self];
	if (![login beginAuthorization]) {
		NSLog(@"Failed to start authenticating.");
		abort();
	}
	[self blockingCheck];
}

- (void)blockingCheck {
	static NSDate * lastTime = nil;
	if (!lastTime) {
		lastTime = [[NSDate date] retain];
	} else {
		NSDate * newTime = [NSDate date];
		NSTimeInterval ti = [newTime timeIntervalSinceDate:lastTime];
		if (ti > 0.2) {
			NSLog(@"Main thread blocked for %d milliseconds.", (int)round(ti * 1000.0));
		}
		[lastTime release];
		lastTime = [newTime retain];
	}
	[self performSelector:@selector(blockingCheck) withObject:nil afterDelay:0.05];
}

- (void)checkThreading {
	if ([NSThread currentThread] != mainThread) {
		NSLog(@"warning: NOT RUNNING ON MAIN THREAD!");
	}
}

- (void)sendBogus {
	AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:@"alexqnichol"] message:@"Yo!"];
	[theSession.messageHandler sendMessage:msg];
	[self performSelector:@selector(sendBogus) withObject:nil afterDelay:1];
}

#pragma mark Login Delegate

- (void)aimLogin:(AIMLogin *)theLogin failedWithError:(NSError *)error {
	[self checkThreading];
	NSLog(@"AIM login failed: %@", error);
	[login release];
	exit(-1);
}

- (void)aimLogin:(AIMLogin *)theLogin openedSession:(AIMSessionManager *)session {
	[self checkThreading];
	[session setDelegate:self];
	[login release];
	login = nil;
	theSession = [session retain];
	
	/* Set handler delegates */
	session.feedbagHandler.delegate = self;
	session.messageHandler.delegate = self;
	session.statusHandler.delegate = self;
	session.rateHandler.delegate = self;
	session.rendezvousHandler.delegate = self;
	
	[session configureBuddyArt];
	AIMCapability * fileTransfers = [[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer];
	AIMCapability * getFiles = [[AIMCapability alloc] initWithType:AIMCapabilityGetFiles];
	NSArray * caps = [NSArray arrayWithObjects:[fileTransfers autorelease], [getFiles autorelease], nil];
	AIMBuddyStatus * newStatus = [[AIMBuddyStatus alloc] initWithMessage:@"Using LibOrange on Mac!" type:AIMBuddyStatusAvailable timeIdle:0 caps:caps];
	[session.statusHandler updateStatus:newStatus];
	[newStatus release];
	
	NSLog(@"Got session: %@", session);
	NSLog(@"Our status: %@", session.statusHandler.userStatus);
	// NSLog(@"Disconnecting in %d seconds ...", kSignoffTime);
	// [[session session] performSelector:@selector(closeConnection) withObject:nil afterDelay:kSignoffTime];
	
	// uncomment to test rate limit detection.
	// [self sendBogus];
}

#pragma mark Session Delegate

- (void)aimSessionManagerSignedOff:(AIMSessionManager *)sender {
	[self checkThreading];
	[theSession autorelease];
	theSession = nil;
	NSLog(@"Session signed off");
}

#pragma mark Buddy List Methods

- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler {
	[self checkThreading];
	NSLog(@"%@ got the buddy list.", feedbagHandler);
	NSLog(@"Blist: %@", [theSession.session buddyList]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy {
	[self checkThreading];
	NSLog(@"Buddy added: %@", newBuddy);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy {
	[self checkThreading];
	NSLog(@"Buddy removed: %@", oldBuddy);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup {
	[self checkThreading];
	NSLog(@"Group added: %@", [newGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup {
	[self checkThreading];
	NSLog(@"Group removed: %@", [oldGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup {
	[self checkThreading];
	NSLog(@"Group renamed: %@", [theGroup name]);
	NSLog(@"Blist: %@", theSession.session.buddyList);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDenied:(NSString *)username {
	NSLog(@"User blocked: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyPermitted:(NSString *)username {
	NSLog(@"User permitted: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUndenied:(NSString *)username {
	NSLog(@"User un-blocked: %@", username);
}
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUnpermitted:(NSString *)username {
	NSLog(@"User un-permitted: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender transactionFailed:(id<FeedbagTransaction>)transaction {
	[self checkThreading];
	NSLog(@"Transaction failed: %@", transaction);
}

#pragma mark Message Handler

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMessage:(AIMMessage *)message {
	[self checkThreading];
	
	NSString * msgTxt = [message plainTextMessage];
	
	NSString * autoresp = [message isAutoresponse] ? @" (Auto-Response)" : @"";
	NSLog(@"(%@) %@%@: %@", [NSDate date], [[message buddy] username], autoresp, [message message]);
		
	NSArray * tokens = [CommandTokenizer tokensOfCommand:msgTxt];
	if ([tokens count] == 1) {
		if ([[tokens objectAtIndex:0] isEqual:@"blist"]) {
			NSString * desc = [[theSession.session buddyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"takeicon"]) {
			NSData * iconData = [[[message buddy] buddyIcon] iconData];
			if (iconData) {
				[theSession.statusHandler updateUserIcon:iconData];
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Icon set requested."]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Couldn't get your icon!"]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"bye"]) {
			[[theSession session] closeConnection];
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * desc = [[[theSession.session buddyList] denyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"permit"]) {
			NSString * desc = [[[theSession.session buddyList] permitList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"pdmode"]) {
			NSString * desc = PD_MODE_TOSTR([theSession.feedbagHandler currentPDMode:NULL]);
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"caps"]) {
			NSString * desc = [[[[message buddy] status] capabilities] description];
			if (desc) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Capabilities unavailable."]];
			}
		}
	} else if ([tokens count] == 2) {
		if ([[tokens objectAtIndex:0] isEqual:@"delbuddy"]) {
			NSString * msg = [self removeBuddy:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"addgroup"]) {
			NSString * msg = [self addGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"delgroup"]) {
			NSString * msg = [self deleteGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"echo"]) {
			NSString * msg = [tokens objectAtIndex:1];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:msg]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"sendfile"]) {
			NSString * messagestr = [tokens objectAtIndex:1];
			BOOL canTransfer = NO;
			for (AIMCapability * cap in message.buddy.status.capabilities) {
				if ([cap capabilityType] == AIMCapabilityFileTransfer) {
					canTransfer = YES;
				}
			}
			if (canTransfer) {
				NSString * tempPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/%d%lu.txt", arc4random(), time(NULL)];
				[messagestr writeToFile:tempPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
				if (![theSession.rendezvousHandler sendFile:tempPath toUser:message.buddy]) {
					[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: sendfile failed." stringByAddingAOLRTFTags]]];
				} else {
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Sendfile started." stringByAddingAOLRTFTags]]];
				}
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: you can't receive files." stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * msg = [self denyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"undeny"]) {
			NSString * msg = [self undenyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	} else if ([tokens count] == 3) {
		if ([[tokens objectAtIndex:0] isEqual:@"addbuddy"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * buddy = [tokens objectAtIndex:2];
			NSString * msg = [self addBuddy:buddy toGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	} else if ([msgTxt hasPrefix:@"echo "]) {
        NSString * part = [msgTxt substringFromIndex:5];
        [sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:part]];
    }
}

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMissedCall:(AIMMissedCall *)missedCall {
	[self checkThreading];
	NSLog(@"Missed call from %@", [missedCall buddy]);
}

#pragma mark Status Handler

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status {
	[self checkThreading];
	NSLog(@"\"%@\"%s%@", theBuddy, ".status = ", status);
}

- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler {
	[self checkThreading];
	NSLog(@"user.status = %@", [handler userStatus]);
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy {
	[self checkThreading];
	NSString * dirPath = [NSString stringWithFormat:@"%@/Desktop/buddyicons/", NSHomeDirectory()];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		NSString * path = nil;
		AIMBuddyIconFormat fmt = [[theBuddy buddyIcon] iconDataFormat];
		switch (fmt) {
			case AIMBuddyIconBMPFormat:
				path = [dirPath stringByAppendingFormat:@"%@.bmp", [theBuddy username]];
				break;
			case AIMBuddyIconGIFFormat:
				path = [dirPath stringByAppendingFormat:@"%@.gif", [theBuddy username]];
				break;
			case AIMBuddyIconJPEGFormat:
				path = [dirPath stringByAppendingFormat:@"%@.jpg", [theBuddy username]];
				break;
			default:
				break;
		}
		if (path) {
			[[[theBuddy buddyIcon] iconData] writeToFile:path atomically:YES];
		}
	}
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler setIconFailed:(AIMIconUploadErrorType)reason {
	NSLog(@"Failed to set our buddy icon.");
}

#pragma mark Rate Handlers

- (void)aimRateLimitHandler:(AIMRateLimitHandler *)handler gotRateAlert:(AIMRateNotificationInfo *)info {
	// use this to show the user that they should stop sending messages.
	NSLog(@"Rate alert");
}

#pragma mark File Transfers

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferRequested:(AIMReceivingFileTransfer *)ft {
	NSLog(@"Auto-accepting transfer: %@", ft);
	NSString * path = [NSString stringWithFormat:@"/var/tmp/%@", [ft remoteFileName]];
	[rvHandler acceptFileTransfer:ft saveToPath:path];
	NSLog(@"Save to path: %@", path);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferCancelled:(AIMFileTransfer *)ft reason:(UInt16)reason {
	NSLog(@"File transfer cancelled: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferFailed:(AIMFileTransfer *)ft {
	NSLog(@"File transfer failed: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferStarted:(AIMFileTransfer *)ft {
	NSLog(@"File transfer started: %@", ft);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferProgressChanged:(AIMFileTransfer *)ft {
	// cancel it a bit of the way through to test that cancelling works.
	// if ([ft progress] > 0.1) [rvHandler cancelFileTransfer:ft];
	// NSLog(@"%@ progress = %f", ft, [ft progress]);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferDone:(AIMFileTransfer *)ft {
	NSLog(@"File transfer done: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

#pragma mark Commands

- (NSString *)removeBuddy:(NSString *)username {
	AIMBlistBuddy * buddy = [theSession.session.buddyList buddyWithUsername:username];
	if (buddy && [buddy group]) {
		FTRemoveBuddy * remove = [[FTRemoveBuddy alloc] initWithBuddy:buddy];
		[theSession.feedbagHandler pushTransaction:remove];
		[remove release];
		return @"Remove (buddy) request sent.";
	} else {
		return @"Err: buddy not found.";
	}
}
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	AIMBlistBuddy * buddy = [group buddyWithUsername:username];
	if (buddy) {
		return @"Err: buddy exists.";
	}
	FTAddBuddy * addBudd = [[FTAddBuddy alloc] initWithUsername:username group:group];
	[theSession.feedbagHandler pushTransaction:addBudd];
	[addBudd release];
	return @"Add (buddy) request sent.";
}
- (NSString *)deleteGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	FTRemoveGroup * delGrp = [[FTRemoveGroup alloc] initWithGroup:group];
	[theSession.feedbagHandler pushTransaction:delGrp];
	[delGrp release];
	return @"Delete (group) request sent.";
}
- (NSString *)addGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (group) {
		return @"Err: group exists.";
	}
	FTAddGroup * addGrp = [[FTAddGroup alloc] initWithName:groupName];
	[theSession.feedbagHandler pushTransaction:addGrp];
	[addGrp release];
	return @"Add (group) request sent.";
}
- (NSString *)denyUser:(NSString *)username {
	NSString * msg = @"Deny add sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		FTSetPDMode * pdMode = [[FTSetPDMode alloc] initWithPDMode:PD_MODE_DENY_SOME pdFlags:PD_FLAGS_APPLIES_IM];
		[theSession.feedbagHandler pushTransaction:pdMode];
		[pdMode release];
		msg = @"Set PD_MODE and sent add deny";
	}
	FTAddDeny * deny = [[FTAddDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:deny];
	[deny release];
	return msg;
}
- (NSString *)undenyUser:(NSString *)username {
	NSString * msg = @"Deny delete sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		msg = @"Warning: Deny delete sent but PD_MODE isn't DENY_SOME";
	}
	FTDelDeny * delDeny = [[FTDelDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:delDeny];
	[delDeny release];
	return msg;
}

@end
