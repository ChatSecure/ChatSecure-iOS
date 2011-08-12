//
//  AIMBuddyStatus.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyStatus.h"


@implementation AIMBuddyStatus

@synthesize statusMessage;
@synthesize statusType;
@synthesize idleTime;
@synthesize capabilities;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle {
	if ((self = [self initWithMessage:message type:type timeIdle:timeIdle caps:nil])) {
		
	}
	return self;
}

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle caps:(NSArray *)caps {
	if ((self = [super init])) {
		statusMessage = [message retain];
		statusType = type;
		idleTime = timeIdle;
		self.capabilities = caps;
	}
	return self;
}

+ (AIMBuddyStatus *)offlineStatus {
	AIMBuddyStatus * stat = [[AIMBuddyStatus alloc] initWithMessage:@"" type:AIMBuddyStatusOffline timeIdle:0];
	return [stat autorelease];
}

+ (AIMBuddyStatus *)rejectedStatus {
	AIMBuddyStatus * stat = [[AIMBuddyStatus alloc] initWithMessage:@"" type:AIMBuddyStatusRejected timeIdle:0];
	return [stat autorelease];
}

- (BOOL)isEqualToStatus:(AIMBuddyStatus *)status {
	if ([status statusType] == [self statusType] && [[status statusMessage] isEqual:[self statusMessage]] && [status idleTime] == [self idleTime]) {
		if ([AIMCapability compareCapArray:self.capabilities toArray:status.capabilities]) {
			return YES;
		} else return NO;
	}
	return NO;
}

- (NSString *)description {
	NSString * statusTypeStr = @"Offline";
	if (statusType == AIMBuddyStatusAway) statusTypeStr = @"Away";
	else if (statusType == AIMBuddyStatusAvailable) statusTypeStr = @"Available";
	return [NSString stringWithFormat:@"<%@ msg=\"%@\" idle=%d>", 
			statusTypeStr, statusMessage, idleTime];
}

- (void)dealloc {
	self.capabilities = nil;
	[statusMessage release];
	[super dealloc];
}

@end
