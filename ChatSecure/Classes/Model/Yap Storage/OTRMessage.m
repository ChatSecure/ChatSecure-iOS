//
//  OTRMessage.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "NSString+HTML.h"
@import OTRAssets;
#import "OTRConstants.h"
#import "OTRMediaItem.h"
#import "OTRLanguageManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

const struct OTRMessageAttributes OTRMessageAttributes = {
	.date = @"date",
	.text = @"text",
	.delivered = @"delivered",
	.read = @"read",
	.incoming = @"incoming",
    .messageId = @"messageId",
    .transportedSecurely = @"transportedSecurely",
    .mediaItem = @"mediaItem"
};


@implementation OTRMessage

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
        self.messageId = [[NSUUID UUID] UUIDString];
        self.delivered = NO;
        self.read = NO;
    }
    return self;
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.buddyUniqueId) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageBuddyEdgeName];
        YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                            destinationKey:self.buddyUniqueId
                                                                                collection:[OTRBuddy collection]
                                                                           nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        
        edges = @[buddyEdge];
    }
    
    if (self.mediaItemUniqueId) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
        YapDatabaseRelationshipEdge *mediaEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                            destinationKey:self.mediaItemUniqueId
                                                                                collection:[OTRMediaItem collection]
                                                                           nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted | YDB_NotifyIfSourceDeleted];
        
        if ([edges count]) {
            edges = [edges arrayByAddingObject:mediaEdge];
        }
        else {
            edges = @[mediaEdge];
        }
    }
    
    return edges;
}

#pragma - mark OTRMessage Protocol methods

- (NSString *)messageKey {
    return self.uniqueId;
}

- (NSString *)messageCollection {
    return [self.class collection];
}

- (NSDate *)messageDate {
    return  self.date;
}

- (NSString *)threadId {
    return self.buddyUniqueId;
}

- (BOOL)messageIncoming
{
    return self.incoming;
}

- (NSString *)messageMediaItemKey
{
    return self.mediaItemUniqueId;
}

- (NSError *)messageError {
    return self.error;
}

- (BOOL)transportedSecurely {
    return self.transportedSecurely;
}

- (BOOL)messageRead {
    return self.isRead;
}

- (NSString *)remoteMessageId
{
    return self.messageId;
}

- (id<OTRThreadOwner>)threadOwnerWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRBuddy fetchObjectWithUniqueID:self.buddyUniqueId transaction:transaction];
}

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [transaction removeAllObjectsInCollection:[OTRMessage collection]];
}

+ (void)deleteAllMessagesForBuddyId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageBuddyEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:uniqueBuddyId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction removeObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
    //Update Last message date for sorting and grouping
    OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:uniqueBuddyId transaction:transaction];
    buddy.lastMessageDate = nil;
    [buddy saveWithTransaction:transaction];
}

+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameBuddyAccountEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:uniqueAccountId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [self deleteAllMessagesForBuddyId:edge.sourceKey transaction:transaction];
    }];
}

+ (id<OTRMessageProtocol>)messageForMessageId:(NSString *)messageId incoming:(BOOL)incoming transaction:(YapDatabaseReadTransaction *)transaction {
    __block id<OTRMessageProtocol> deliveredMessage = nil;
    [transaction enumerateMessagesWithId:messageId block:^(id<OTRMessageProtocol> _Nonnull message, BOOL * _Null_unspecified stop) {
        if ([message messageIncoming] == incoming) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            deliveredMessage = message;
            *stop = YES;
        }
    }];
    return deliveredMessage;
}

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    __block OTRMessage *deliveredMessage = nil;
    [transaction enumerateMessagesWithId:messageId block:^(id<OTRMessageProtocol> _Nonnull message, BOOL * _Null_unspecified stop) {
        if (![message messageIncoming] && [message isKindOfClass:[OTRMessage class]]) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            OTRMessage *msg = (OTRMessage *)message;
            if (![msg.mediaItemUniqueId length]) {
                deliveredMessage = msg;
                *stop = YES;
            }
        }
    }];

    if (deliveredMessage) {
        deliveredMessage.delivered = YES;
        [deliveredMessage saveWithTransaction:transaction];
    }
}

@end
