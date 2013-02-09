//
//  OTRManagedBuddy.h
//  Off the Record
//
//  Created by Christopher Ballinger on 1/10/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OTRKit.h"

@class OTRManagedAccount;

typedef int16_t OTRBuddyStatus;
typedef int16_t OTRChatState;

#define MESSAGE_PROCESSED_NOTIFICATION @"MessageProcessedNotification"
#define kOTREncryptionStateNotification @"kOTREncryptionStateNotification"


enum OTRBuddyStatus {
    kOTRBuddyStatusOffline = 0,
    kOTRBuddyStatusAway = 1,
    kOTRBuddyStatusAvailable = 2
};

enum OTRChatState {
    kOTRChatStateUnknown =0,
    kOTRChatStateActive = 1,
    kOTRChatStateComposing = 2,
    kOTRChatStatePaused = 3,
    kOTRChatStateInactive = 4,
    kOTRChatStateGone =5
};


@interface OTRManagedBuddy : NSManagedObject

@property (nonatomic, retain) NSString * accountName;
@property (nonatomic) OTRChatState chatState;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, readonly) OTRKitMessageState encryptionStatus;
@property (nonatomic) OTRChatState lastSentChatState;
@property (nonatomic, readonly) OTRBuddyStatus status;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSString * composingMessageString;
@property (nonatomic) BOOL lastMessageDisconnected;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) OTRManagedAccount *account;

-(void)receiveMessage:(NSString *)message;
-(void)receiveChatStateMessage:(OTRChatState) chatState;
-(void)receiveReceiptResonse:(NSString *)responseID;
-(void)sendMessage:(NSString *)message secure:(BOOL)secure;

-(NSArray *)fetchChatHistory:(int)numberOfMessages;

-(BOOL)protocolIsXMPP;

-(void)sendActiveChatState;
-(void)sendInactiveChatState;
-(void)sendComposingChatState;
-(void)invalidatePausedChatStateTimer;
-(void)invalidateInactiveChatStateTimer;

- (void) setNewStatus:(OTRBuddyStatus)newStatus;
- (void) setNewEncryptionStatus:(OTRKitMessageState)newEncryptionStatus;

@end

@interface OTRManagedBuddy (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(NSManagedObject *)value;
- (void)removeMessagesObject:(NSManagedObject *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
