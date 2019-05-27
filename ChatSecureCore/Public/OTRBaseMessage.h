//
//  OTRMessage.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRMessageEncryptionInfo.h"
@import YapDatabase;
@class OTRBuddy,YapDatabaseReadTransaction, OTRMediaItem, OTRXMPPBuddy;
@protocol OTRThreadOwner;

NS_ASSUME_NONNULL_BEGIN
@protocol OTRDownloadMessage;

@protocol OTRDownloadMessageProtocol <NSObject>
@required
/** Returns an unsaved array of downloadable URLs. */
- (NSArray<id<OTRDownloadMessage>>*) downloads;
/**  If available, existing instances will be returned. */
- (NSArray<id<OTRDownloadMessage>>*) existingDownloadsWithTransaction:(YapDatabaseReadTransaction*)transaction;
/** Checks if edge count > 0 */
- (BOOL) hasExistingDownloadsWithTransaction:(YapDatabaseReadTransaction*)transaction;
@end

@protocol OTRMessageProtocol <OTRYapDatabaseObjectProtocol, OTRDownloadMessageProtocol>
@required
@property (nonatomic, readonly) NSString *messageKey;
@property (nonatomic, readonly) NSString *messageCollection;
/** In reality this shouldn't be nil, but could be if something bad happens. */
@property (nonatomic, readonly, nonnull) NSString *threadId;
@property (nonatomic, readonly, nonnull) NSString *threadCollection;
@property (nonatomic, readonly) BOOL isMessageIncoming;
@property (nonatomic, readwrite, nullable) NSString *messageMediaItemKey;
@property (nonatomic, readwrite, nullable) NSError *messageError;
@property (nonatomic, readwrite) OTRMessageTransportSecurity messageSecurity;
@property (nonatomic, readwrite, nullable) OTRMessageEncryptionInfo *messageSecurityInfo;

/** Only applies to incoming messages */
@property (nonatomic, readonly) BOOL isMessageRead;
@property (nonatomic, readwrite) NSDate *messageDate;
@property (nonatomic, readwrite, nullable) NSString *messageText;
/** This should be the same as XMPPMessage.elementId */
@property (nonatomic, readonly, nullable) NSString *remoteMessageId;
/** Only applies to outgoing messages */
@property (nonatomic, readonly) BOOL isMessageSent;
/** Only applies to outgoing messages */
@property (nonatomic, readonly) BOOL isMessageDelivered;

/** XEP-0359: origin-id */
@property (nonatomic, strong, nullable) NSString *originId;
/** XEP-0359: stanza-id */
@property (nonatomic, strong, nullable) NSString *stanzaId;

/** This is an OTRXMPPRoom for a MUC message, and an OTRXMPPBuddy for direct message */
- (nullable id<OTRThreadOwner>)threadOwnerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
/** This is always an OTRXMPPBuddy associated with the message */
- (nullable OTRXMPPBuddy*)buddyWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;

/**
 This creates a duplicate message. The only properties that are coppied over are
 - text
 - error
 - mediaItemUniqueId
 - buddyUnieqId
 - messageSecurityInfo
 This new object will have a new unique id and message id
 */
- (id<OTRMessageProtocol>) duplicateMessage;
@end

@protocol OTRChildObjectProtocol
@required
@property (nonatomic, strong, nullable) NSString *parentObjectKey;
@property (nonatomic, strong, nullable) NSString *parentObjectCollection;

/** Returns parent object if it still exists */
- (nullable id) parentObjectWithTransaction:(YapDatabaseReadTransaction*)transaction;
/** Attempts to touch parent object */
- (void) touchParentObjectWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;

@end

/** This is for objects that point to a parent message, for instance OTRDownloadMessage or OTRMediaItem */
@protocol OTRMessageChildProtocol
@required
- (nullable id<OTRMessageProtocol>) parentMessageWithTransaction:(YapDatabaseReadTransaction*)transaction;
- (void) touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
@end

@interface OTRBaseMessage : OTRYapDatabaseObject <YapDatabaseRelationshipNode, OTRMessageProtocol>

/** The date the message is created for outgoing messages and the date it is received for incoming messages*/
@property (nonatomic, strong, nonnull) NSDate *date;

@property (nonatomic, strong, nullable) NSString *text;
/** XMPP element id */
@property (nonatomic, strong, nonnull) NSString *messageId;
@property (nonatomic, strong, nullable) NSError *error;

@property (nonatomic, strong, nullable) NSString *mediaItemUniqueId;
@property (nonatomic, strong, nonnull) NSString *buddyUniqueId;

/** The security method the message is intended to be sent and will be sent */
@property (nonatomic, strong, nonnull) OTRMessageEncryptionInfo *messageSecurityInfo;

+ (void)deleteAllMessagesWithTransaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForBuddyId:(nonnull NSString *)uniqueBuddyId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForAccountId:(nonnull NSString *)uniqueAccountId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId incoming:(BOOL)incoming transaction:(nonnull YapDatabaseReadTransaction *)transaction;
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId transaction:(nonnull YapDatabaseReadTransaction *)transaction;

- (nullable OTRXMPPBuddy*) buddyWithTransaction:(nonnull YapDatabaseReadTransaction*)transaction;

@end
NS_ASSUME_NONNULL_END
