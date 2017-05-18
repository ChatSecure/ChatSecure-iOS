//
//  OTRMessage.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRMessageEncryptionInfo.h"
@import JSQMessagesViewController;
@import YapDatabase;
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

- (OTRMessageTransportSecurity)messageSecurity;

- (BOOL)messageRead;

- (nonnull NSDate *)date;

- (nullable NSString *)text;

- (nullable NSString *)remoteMessageId;

- (nullable id<OTRThreadOwner>)threadOwnerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;

@end

@interface OTRBaseMessage : OTRYapDatabaseObject <YapDatabaseRelationshipNode, OTRMessageProtocol>

/** The date the message is created for outgoing messages and the date it is received for incoming messages*/
@property (nonatomic, strong, nonnull) NSDate *date;

@property (nonatomic, strong, nullable) NSString *text;
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

- (nullable OTRBuddy*) buddyWithTransaction:(nonnull YapDatabaseReadTransaction*)transaction;

/** 
 This creates a duplicate message. The only properties that are coppied over are 
    - text
    - error
    - mediaItemUniqueId 
    - buddyUnieqId 
    - messageSecurityInfo
 This new object will have a new unique id and message id
 */
+ (instancetype _Nullable)duplicateMessage:(nonnull OTRBaseMessage *)message;
@end
