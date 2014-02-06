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
#import "_OTRManagedBuddy.h"
#import "OTRConstants.h"
#import "OTRManagedStatus.h"

@class OTRManagedAccount;

@interface OTRManagedBuddy : _OTRManagedBuddy

-(void)receiveChatStateMessage:(OTRChatState) chatState;

-(BOOL)protocolIsXMPP;

-(void)sendActiveChatState;
-(void)sendInactiveChatState;
-(void)sendComposingChatState;
-(void)invalidatePausedChatStateTimer;
-(void)invalidateInactiveChatStateTimer;

- (void)newStatusMessage:(NSString *)newStatusMessage status:(OTRBuddyStatus)newStatus incoming:(BOOL)isIncoming inContext:(NSManagedObjectContext *)context;
- (void)setNewEncryptionStatus:(OTRKitMessageState)newEncryptionStatus inContext:(NSManagedObjectContext *)context;
- (OTRManagedStatus *)currentStatusMessage;
- (OTRManagedEncryptionStatusMessage *)currentEncryptionStatusInContext:(NSManagedObjectContext *)context;
- (OTRKitMessageState)currentEncryptionStatus;

- (void)addToGroup:(NSString *)groupName inContext:(NSManagedObjectContext *)context;
- (NSArray *)groupNames;

- (NSInteger) numberOfUnreadMessages;
- (void) allMessagesRead;

- (void) deleteAllMessagesInContext:(NSManagedObjectContext *)context;

+ (instancetype)fetchOrCreateWithName:(NSString *)name account:(OTRManagedAccount *)account inContext:(NSManagedObjectContext *)context;
+ (instancetype)fetchWithName:(NSString *)name account:(OTRManagedAccount *)account inContext:(NSManagedObjectContext *)context;

@end

@interface OTRManagedBuddy (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(NSManagedObject *)value;
- (void)removeMessagesObject:(NSManagedObject *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
