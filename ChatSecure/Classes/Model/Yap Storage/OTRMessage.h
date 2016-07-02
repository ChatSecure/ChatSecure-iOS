//
//  OTRMessage.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
@import JSQMessagesViewController;
@import YapDatabase.YapDatabaseRelationship;
@class OTRBuddy,YapDatabaseReadTransaction, OTRMediaItem;
@protocol OTRThreadOwner;

extern const struct OTRMessageAttributes {
	__unsafe_unretained NSString * _Nonnull date;
	__unsafe_unretained NSString * _Nonnull text;
	__unsafe_unretained NSString * _Nonnull delivered;
	__unsafe_unretained NSString * _Nonnull read;
	__unsafe_unretained NSString * _Nonnull incoming;
    __unsafe_unretained NSString * _Nonnull messageId;
    __unsafe_unretained NSString * _Nonnull transportedSecurely;
    __unsafe_unretained NSString * _Nonnull mediaItem;
} OTRMessageAttributes;

@protocol OTRMessageProtocol <NSObject>
@required

- (nonnull NSString *)messageKey;

- (nonnull NSString *)messageCollection;

- (nullable NSString *)threadId;

- (BOOL)messageIncoming;

- (nullable NSString *)messageMediaItemKey;

- (nullable NSError *)messageError;

- (BOOL)transportedSecurely;

- (BOOL)messageRead;

- (nonnull NSDate *)date;

- (nullable NSString *)text;

- (nullable NSString *)remoteMessageId;

- (nullable id<OTRThreadOwner>)threadOwnerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end

@interface OTRMessage : OTRYapDatabaseObject <YapDatabaseRelationshipNode, OTRMessageProtocol>

/** The date the message is created for outgoing messages and the date it is received for incoming messages*/
@property (nonatomic, strong, nonnull) NSDate *date;

/** OUTGOING ONLY. The date that the message left the device and went on the wire.*/
@property (nonatomic, strong, nullable) NSDate *dateSent;

/** OUTGOING ONLY. The date that the message is acknowledged by the server. Only relevant if the stream supporrts XEP-0198 at the time of sending*/
@property (nonatomic, strong, nullable) NSDate *dateAcked;

/** OUTGOING ONLY. The date the message is deliverd to the other client. Only relevant if the other client supports XEP-0184. There is no way to query support */
@property (nonatomic, strong, nullable) NSDate *dateDelivered;

/** Mark message as deliverd via XEP-0184.*/
@property (nonatomic, getter = isDelivered) BOOL delivered;


@property (nonatomic, strong, nullable) NSString *text;
@property (nonatomic, strong, nonnull) NSString *messageId;
@property (nonatomic, strong, nullable) NSError *error;

@property (nonatomic, getter = isRead) BOOL read;
@property (nonatomic, getter = isIncoming) BOOL incoming;

/** If the message was sent encrypted*/
@property (nonatomic, getter = isTransportedSecurely) BOOL transportedSecurely;

/** If the message is intended to be sent encrypted */
@property (nonatomic) BOOL sendEncrypted;

@property (nonatomic, strong, nullable) NSString *mediaItemUniqueId;
@property (nonatomic, strong, nonnull) NSString *buddyUniqueId;

+ (void)deleteAllMessagesWithTransaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForBuddyId:(nonnull NSString *)uniqueBuddyId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForAccountId:(nonnull NSString *)uniqueAccountId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)receivedDeliveryReceiptForMessageId:(nonnull NSString *)messageId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId incoming:(BOOL)incoming transaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end
