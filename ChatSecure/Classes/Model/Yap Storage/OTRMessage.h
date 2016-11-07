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
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *text;
	__unsafe_unretained NSString *delivered;
	__unsafe_unretained NSString *read;
	__unsafe_unretained NSString *incoming;
    __unsafe_unretained NSString *messageId;
    __unsafe_unretained NSString *transportedSecurely;
    __unsafe_unretained NSString *mediaItem;
} OTRMessageAttributes;

@protocol OTRMessageProtocol <NSObject>
@required

- (NSString *)messageKey;

- (NSString *)messageCollection;

- (NSString *)threadId;

- (BOOL)messageIncoming;

- (NSString *)messageMediaItemKey;

- (NSError *)messageError;

- (BOOL)transportedSecurely;

- (BOOL)messageRead;

- (NSDate *)date;

- (NSString *)text;

- (NSString *)remoteMessageId;

- (id<OTRThreadOwner>)threadOwnerWithTransaction:(YapDatabaseReadTransaction *)transaction;

@end

@interface OTRMessage : OTRYapDatabaseObject <YapDatabaseRelationshipNode, OTRMessageProtocol>

@property (nonatomic, strong) NSDate *date;
/** OUTGOING ONLY. The date that the message is acknowledged by the server. Only relevant if the stream supporrts XEP-0198 at the time of sending*/
@property (nonatomic, strong, nullable) NSDate *dateAcked;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, getter = isDelivered) BOOL delivered;
@property (nonatomic, getter = isRead) BOOL read;
@property (nonatomic, getter = isIncoming) BOOL incoming;
@property (nonatomic, getter = isTransportedSecurely) BOOL transportedSecurely;

@property (nonatomic, strong) NSString *mediaItemUniqueId;
@property (nonatomic, strong) NSString *buddyUniqueId;

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForBuddyId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId incoming:(BOOL)incoming transaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end
