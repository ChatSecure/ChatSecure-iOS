//
//  AIMTempBuddyHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMTempBuddyHandler.h"
#import "AIMSession.h"


@implementation AIMTempBuddyHandler

- (id)initWithSession:(AIMSession *)theSession {
	if ((self = [super init])) {
		tempBuddies = [[NSMutableArray alloc] init];
		session = [theSession retain];
	}
	return self;
}
- (void)sessionClosed {
	[session autorelease];
	session = nil;
}
- (NSArray *)temporaryBuddies {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	return (NSArray *)tempBuddies;
}
- (AIMBlistBuddy *)addTempBuddy:(NSString *)screenName {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	if ([self tempBuddyWithName:screenName]) {
		return [self tempBuddyWithName:screenName];
	}
	AIMBlistBuddy * newBuddy = [[AIMBlistBuddy alloc] initWithUsername:screenName];
	[tempBuddies addObject:newBuddy];
	
	NSData * unameStr = encodeString8(screenName);
	SNAC * addTemp = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BUDDY, BUDDY__ADD_TEMP_BUDDIES) flags:0 requestID:[session generateReqID] data:unameStr];
	[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:addTemp waitUntilDone:NO];
	[addTemp release];
	
	return [newBuddy autorelease];
}
- (AIMBlistBuddy *)tempBuddyWithName:(NSString *)screenName {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	for (AIMBlistBuddy * buddy in tempBuddies) {
		if ([buddy usernameIsEqual:screenName]) {
			return buddy;
		}
	}
	return nil;
}
- (void)deleteTempBuddy:(AIMBlistBuddy *)tempBuddy {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	AIMBlistBuddy * buddy = [self tempBuddyWithName:[tempBuddy username]];
	if (buddy) {
		NSData * unameStr = encodeString8([buddy username]);
		SNAC * delTemp = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BUDDY, BUDDY__DEL_TEMP_BUDDIES) flags:0 requestID:[session generateReqID] data:unameStr];
		[session performSelector:@selector(writeSnac:) onThread:session.backgroundThread withObject:delTemp waitUntilDone:NO];
		[delTemp release];
		[tempBuddies removeObject:buddy];
	}
}

- (void)dealloc {
	[tempBuddies release];
	[super dealloc];
}

@end
