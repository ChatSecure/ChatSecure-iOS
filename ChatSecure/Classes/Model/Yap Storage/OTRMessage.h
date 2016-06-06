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

@property (nonatomic, strong, nonnull) NSDate *date;
@property (nonatomic, strong, nullable) NSString *text;
@property (nonatomic, strong, nonnull) NSString *messageId;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, getter = isDelivered) BOOL delivered;
@property (nonatomic, getter = isRead) BOOL read;
@property (nonatomic, getter = isIncoming) BOOL incoming;
@property (nonatomic, getter = isTransportedSecurely) BOOL transportedSecurely;

@property (nonatomic, strong, nullable) NSString *mediaItemUniqueId;
@property (nonatomic, strong, nonnull) NSString *buddyUniqueId;

+ (void)deleteAllMessagesWithTransaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForBuddyId:(nonnull NSString *)uniqueBuddyId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForAccountId:(nonnull NSString *)uniqueAccountId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (void)receivedDeliveryReceiptForMessageId:(nonnull NSString *)messageId transaction:(nonnull YapDatabaseReadWriteTransaction*)transaction;
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId incoming:(BOOL)incoming transaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end
