//
//  OTRBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRConstants.h"

@class OTRAccount, OTRMessage;

extern const struct OTRBuddyAttributes {
	__unsafe_unretained NSString *username;
	__unsafe_unretained NSString *displayName;
	__unsafe_unretained NSString *composingMessageString;
	__unsafe_unretained NSString *statusMessage;
	__unsafe_unretained NSString *chatState;
    __unsafe_unretained NSString *lastSentChatState;
    __unsafe_unretained NSString *status;
    __unsafe_unretained NSString *lastMessageDate;
    __unsafe_unretained NSString *avatarData;
    __unsafe_unretained NSString *encryptionStatus;
} OTRBuddyAttributes;

extern const struct OTRBuddyRelationships {
	__unsafe_unretained NSString *accountUniqueId;
} OTRBuddyRelationships;

extern const struct OTRBuddyEdges {
	__unsafe_unretained NSString *account;
} OTRBuddyEdges;

@interface OTRBuddy : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *composingMessageString;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, strong) NSDate *lastMessageDate;
@property (nonatomic) OTRChatState chatState;
@property (nonatomic) OTRChatState lastSentChatState;
@property (nonatomic) OTRBuddyStatus status;
@property (nonatomic, strong) NSData *avatarData;

@property (nonatomic, strong) NSString *accountUniqueId;


- (UIImage *)avatarImage;

- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction;

+ (OTRBuddy *)fetchBuddyForUsername:(NSString *)username accountName:(NSString *)accountName protocolType:(OTRProtocolType)protocolType transaction:(YapDatabaseReadTransaction *)transaction;
+ (instancetype)fetchBuddyWithUsername:(NSString *)username withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction;


+ (void)resetAllChatStatesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
+ (void)resetAllBuddyStatusesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;


@end
