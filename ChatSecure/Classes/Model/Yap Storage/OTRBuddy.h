//
//  OTRBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRThreadOwner.h"
#import "OTRUserInfoProfile.h"
@import UIKit;

typedef NS_ENUM(int, OTRChatState) {
    kOTRChatStateUnknown   = 0,
    kOTRChatStateActive    = 1,
    kOTRChatStateComposing = 2,
    kOTRChatStatePaused    = 3,
    kOTRChatStateInactive  = 4,
    kOTRChatStateGone      = 5
};

/** These are the preferences for a buddy on how to send a message. Related OTRMessageTransportSecurity*/
typedef NS_ENUM(NSUInteger, OTRSessionSecurity) {
    OTRSessionSecurityDefault,
    OTRSessionSecurityPlaintext,
    OTRSessionSecurityOTR,
    OTRSessionSecurityOMEMO,
};


@class OTRAccount, OTRMessage;

extern const struct OTRBuddyAttributes {
	__unsafe_unretained NSString * _Nonnull username;
	__unsafe_unretained NSString * _Nonnull displayName;
	__unsafe_unretained NSString * _Nonnull composingMessageString;
	__unsafe_unretained NSString * _Nonnull statusMessage;
	__unsafe_unretained NSString * _Nonnull chatState;
    __unsafe_unretained NSString * _Nonnull lastSentChatState;
    __unsafe_unretained NSString * _Nonnull status;
    __unsafe_unretained NSString * _Nonnull lastMessageDate;
    __unsafe_unretained NSString * _Nonnull avatarData;
    __unsafe_unretained NSString * _Nonnull encryptionStatus;
} OTRBuddyAttributes;

@interface OTRBuddy : OTRYapDatabaseObject <YapDatabaseRelationshipNode, OTRThreadOwner, OTRUserInfoProfile>

@property (nonatomic, strong, nonnull) NSString *username;
@property (nonatomic, strong, readwrite, nonnull) NSString *displayName;
@property (nonatomic, strong, nullable) NSString *composingMessageString;
@property (nonatomic, strong, nullable) NSString *statusMessage;
@property (nonatomic) OTRChatState chatState;
@property (nonatomic) OTRChatState lastSentChatState;
@property (nonatomic) OTRThreadStatus status;

/** the date last message was received for buddy. also used by incoming/outgoing subscription requests to force buddy to appear in conversation view */
@property (nonatomic, strong, nullable) NSDate *lastMessageDate;

/** User can choose a preferred security method e.g. plaintext, OTR, OMEMO. If undefined, best available option should be chosen elsewhere. OMEMO > OTR > Plaintext */
@property (nonatomic, readwrite) OTRSessionSecurity preferredSecurity;

/**
 * Setting this value does a comparison of against the previously value
 * to invalidate the OTRImages cache.
 */
@property (nonatomic, strong, nullable) NSData *avatarData;

@property (nonatomic, strong, nonnull) NSString *accountUniqueId;

- (nullable OTRMessage *)lastMessageWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRAccount*)accountWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (void)updateLastMessageDateWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;

- (void)bestTransportSecurityWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction
                             completionBlock:(void (^_Nonnull)(OTRMessageTransportSecurity))block
                             completionQueue:(nonnull dispatch_queue_t)queue;


+ (nullable instancetype)fetchBuddyForUsername:(nonnull NSString *)username
                          accountName:(nonnull NSString *)accountName
                          transaction:(nonnull YapDatabaseReadTransaction *)transaction;

+ (nullable instancetype)fetchBuddyWithUsername:(nonnull NSString *)username
                   withAccountUniqueId:(nonnull NSString *)accountUniqueId
                           transaction:(nonnull YapDatabaseReadTransaction *)transaction;


+ (void)resetAllChatStatesWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;
+ (void)resetAllBuddyStatusesWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;




@end
