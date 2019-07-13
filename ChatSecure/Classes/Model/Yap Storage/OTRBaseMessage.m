//
//  OTRMessage.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
@import MWFeedParser;
@import OTRAssets;
#import "OTRConstants.h"
#import "OTRMediaItem.h"
#import "OTRDownloadMessage.h"
@import CocoaLumberjack;
#import "OTRLog.h"
#import "OTRMessageEncryptionInfo.h"
#import "ChatSecureCoreCompat-Swift.h"

@interface OTRBaseMessage()
@property (nonatomic) BOOL transportedSecurely;
@end


@implementation OTRBaseMessage
@synthesize originId = _originId;
@synthesize stanzaId = _stanzaId;

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
        self.messageId = [[NSUUID UUID] UUIDString];
        self.transportedSecurely = NO;
    }
    return self;
}

#pragma - mark MTLModel

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
    // Going from version 0 to version 1.
    // The dateSent is assumed to be the `date` created. In model version 1 this will be properly set using the sending queue
    if (modelVersion == 0 && [key isEqualToString:@"dateSent"] ) {
        return [super decodeValueForKey:@"date" withCoder:coder modelVersion:modelVersion];
    }
    return [super decodeValueForKey:key withCoder:coder modelVersion:modelVersion];
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

/** Override normal behaviour to migrate from old way of storing encryption state */
- (OTRMessageEncryptionInfo *)messageSecurityInfo {
    if (self.transportedSecurely) {
        return [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:OTRMessageTransportSecurityOTR];
    }
    return _messageSecurityInfo;
}

#pragma mark OTRDownloadMessageProtocol

/**  If available, existing instances will be returned. */
- (NSArray<id<OTRDownloadMessage>>*) existingDownloadsWithTransaction:(YapDatabaseReadTransaction*)transaction {
    if (!self.isMessageIncoming) {
        return @[];
    }
    id<OTRMessageProtocol> message = self;
    NSMutableArray<id<OTRDownloadMessage>> *downloadMessages = [NSMutableArray array];
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
    YapDatabaseRelationshipTransaction *relationship = [transaction ext:extensionName];
    if (!relationship) {
        DDLogWarn(@"%@ not registered!", extensionName);
    }
    [relationship enumerateEdgesWithName:edgeName destinationKey:message.messageKey collection:message.messageCollection usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRDirectDownloadMessage *download = [OTRDirectDownloadMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (download) {
            [downloadMessages addObject:download];
        }
    }];
    return downloadMessages;
}

/** Returns an unsaved array of downloadable URLs. */
- (NSArray<id<OTRDownloadMessage>>*) downloads {
    if (!self.isMessageIncoming) {
        return @[];
    }
    id<OTRMessageProtocol> message = self;
    NSMutableArray<id<OTRDownloadMessage>> *downloadMessages = [NSMutableArray array];
    [self.downloadableNSURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        id<OTRDownloadMessage> download = [OTRDirectDownloadMessage downloadWithParentMessage:message url:url];
        [downloadMessages addObject:download];
    }];
    return downloadMessages;
}

- (BOOL) hasExistingDownloadsWithTransaction:(YapDatabaseReadTransaction*)transaction {
    if (!self.isMessageIncoming) {
        return NO;
    }
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
    YapDatabaseRelationshipTransaction *relationship = [transaction ext:extensionName];
    if (!relationship) {
        DDLogWarn(@"%@ not registered!", extensionName);
    }
    NSUInteger count = [relationship edgeCountWithName:edgeName destinationKey:self.messageKey collection:self.messageCollection];
    return count > 0;
}

#pragma - mark OTRMessage Protocol methods

- (NSDate*) messageDate {
    return self.date;
}

- (void) setMessageDate:(NSDate *)messageDate {
    self.date = messageDate;
}

- (BOOL) isMessageDelivered {
    return NO;
}

- (BOOL) isMessageSent {
    return NO;
}

// Override in subclass
- (BOOL)isMessageIncoming {
    return YES;
}

// Override in subclass
- (BOOL)isMessageRead {
    return YES;
}

- (OTRMessageTransportSecurity) messageSecurity {
    return self.messageSecurityInfo.messageSecurity;
}

- (void) setMessageSecurity:(OTRMessageTransportSecurity)messageSecurity {
    OTRMessageEncryptionInfo *info = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:messageSecurity];
    self.messageSecurityInfo = info;
}

- (NSString *)messageKey {
    return self.uniqueId;
}

- (NSString *)messageCollection {
    return [self.class collection];
}

- (NSString *)threadId {
    return self.buddyUniqueId;
}

- (NSString*)threadCollection {
    return [OTRBuddy collection];
}

- (NSString *)messageMediaItemKey
{
    return self.mediaItemUniqueId;
}

- (void) setMessageMediaItemKey:(NSString *)messageMediaItemKey {
    self.mediaItemUniqueId = messageMediaItemKey;
}

- (void) setMessageError:(NSError *)messageError {
    self.error = messageError;
}

- (NSError *)messageError {
    return self.error;
}

- (NSString*) messageText {
    return self.text;
}

- (void) setMessageText:(NSString *)messageText {
    self.text = messageText;
}

- (NSString *)remoteMessageId
{
    return self.messageId;
}

- (id<OTRThreadOwner>)threadOwnerWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    id object = [transaction objectForKey:self.threadId inCollection:self.threadCollection];
    if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
        return object;
    }
    return nil;
}

- (nullable OTRXMPPBuddy*) buddyWithTransaction:(nonnull YapDatabaseReadTransaction*)transaction {
    id <OTRThreadOwner> threadOwner = [self threadOwnerWithTransaction:transaction];
    if ([threadOwner isKindOfClass:[OTRXMPPBuddy class]]) {
        return (OTRXMPPBuddy*)threadOwner;
    }
    return nil;
}

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [transaction removeAllObjectsInCollection:[self collection]];
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
    buddy = [buddy copy];
    buddy.lastMessageId = nil;
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
    [transaction enumerateMessagesWithElementId:messageId originId:nil stanzaId:nil block:^(id<OTRMessageProtocol> _Nonnull message, BOOL * _Null_unspecified stop) {
        if ([message isMessageIncoming] == incoming) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            deliveredMessage = message;
            *stop = YES;
        }
    }];
    return deliveredMessage;
}
+ (nullable id<OTRMessageProtocol>)messageForMessageId:(nonnull NSString *)messageId transaction:(nonnull YapDatabaseReadTransaction *)transaction
{
    if ([self class] == [OTRIncomingMessage class]) {
        return [self messageForMessageId:messageId incoming:YES transaction:transaction];
    } else {
        return [self messageForMessageId:messageId incoming:NO transaction:transaction];
    }
}

- (id<OTRMessageProtocol>)duplicateMessage {
    OTRBaseMessage *message = self;
    OTRBaseMessage *newMessage = [[[self class] alloc] init];
    newMessage.text = message.text;
    newMessage.error = message.error;
    newMessage.mediaItemUniqueId = message.mediaItemUniqueId;
    newMessage.buddyUniqueId = message.buddyUniqueId;
    newMessage.messageSecurityInfo = message.messageSecurityInfo;
    return newMessage;
}

+ (NSUInteger)modelVersion {
    return 1;
}

+ (NSString *)collection {
    return @"OTRMessage";
}

@end
