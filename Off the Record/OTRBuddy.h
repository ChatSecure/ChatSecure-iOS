//
//  OTRBuddy.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRProtocol.h"

typedef unsigned int OTRBuddyStatus;
typedef unsigned int OTRBuddyEncryptionStatus;

#define MESSAGE_PROCESSED_NOTIFICATION @"MessageProcessedNotification"
#define kOTREncryptionStateNotification @"kOTREncryptionStateNotification"


enum OTRBuddyStatus {
    kOTRBuddyStatusOffline = 0,
    kOTRBuddyStatusAway = 1,
    kOTRBuddyStatusAvailable = 2
};

enum OTRBuddyEncryptionStatus {
    kOTRBuddyEncryptionStatusUnencrypted = 0,
    kOTRBuddyEncryptionStatusEncrypted = 1,
    kOTRBuddyEncryptionStatusEncryptedAndVerified = 2
};

@interface OTRBuddy : NSObject


@property (nonatomic, retain) NSString* displayName;
@property (nonatomic, retain) NSString* accountName;
@property (nonatomic, retain) NSString* groupName;
@property (nonatomic, retain) NSMutableString* chatHistory;
@property (nonatomic, retain) NSString *lastMessage;
@property (nonatomic, retain) id<OTRProtocol> protocol;
@property (nonatomic) BOOL lastMessageDisconnected;

@property (nonatomic) OTRBuddyStatus status;
@property (nonatomic) OTRBuddyEncryptionStatus encryptionStatus;

-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;
+(OTRBuddy*)buddyWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;

-(void)receiveMessage:(NSString *)message;
-(void)sendMessage:(NSString *)message secure:(BOOL)secure;

@end
