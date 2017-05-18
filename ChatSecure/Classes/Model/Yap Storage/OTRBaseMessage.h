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

NS_ASSUME_NONNULL_BEGIN
@protocol OTRMessageProtocol <NSObject>
@required
@property (nonatomic, readonly) NSString *messageKey;
@property (nonatomic, readonly) NSString *messageCollection;
@property (nonatomic, readonly, nullable) NSString *threadId;
@property (nonatomic, readonly) BOOL isMessageIncoming;
@property (nonatomic, readonly, nullable) NSString *messageMediaItemKey;
@property (nonatomic, readonly, nullable) NSError *messageError;
@property (nonatomic, readonly) OTRMessageTransportSecurity messageSecurity;
@property (nonatomic, readonly) BOOL isMessageRead;
@property (nonatomic, readonly) NSDate *messageDate;
@property (nonatomic, readonly, nullable) NSString *messageText;
@property (nonatomic, readonly, nullable) NSString *remoteMessageId;

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
NS_ASSUME_NONNULL_END
