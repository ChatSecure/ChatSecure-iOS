//
//  AIMBuddyStatus.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMCapability.h"

typedef enum {
	AIMBuddyStatusAway,
	AIMBuddyStatusAvailable,
	AIMBuddyStatusOffline,
	AIMBuddyStatusRejected
} AIMBuddyStatusType;

@interface AIMBuddyStatus : NSObject {
    NSString * statusMessage;
	AIMBuddyStatusType statusType;
	UInt32 idleTime; // in minutes
	NSArray * capabilities;
}

@property (readonly) NSString * statusMessage;
@property (readonly) AIMBuddyStatusType statusType;
@property (readonly) UInt32 idleTime;
@property (nonatomic, retain) NSArray * capabilities;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle;
- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle caps:(NSArray *)caps;
+ (AIMBuddyStatus *)offlineStatus;
+ (AIMBuddyStatus *)rejectedStatus;
- (BOOL)isEqualToStatus:(AIMBuddyStatus *)status;

@end
