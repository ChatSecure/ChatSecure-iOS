//
//  OTRBuddy.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef unsigned int OTRBuddyStatus;

enum OTRBuddyStatus {
    kOTRBuddyStatusOffline = 0,
    kOTRBuddyStatusAway = 1,
    kOTRBuddyStatusAvailable = 2
};

@interface OTRBuddy : NSObject

@property (readonly, retain) NSString* name;
@property (readonly, retain) NSString* protocol;
@property (nonatomic, retain) NSString* groupName;
@property OTRBuddyStatus status;

-(id)initWithName:(NSString*)buddyName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;
+(OTRBuddy*)buddyWithName:(NSString*)buddyName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;

@end
