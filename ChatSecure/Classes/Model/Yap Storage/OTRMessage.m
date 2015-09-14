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
#import "Strings.h"
#import "OTRConstants.h"
#import "OTRMediaItem.h"

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

const struct OTRMessageRelationships OTRMessageRelationships = {
	.buddyUniqueId = @"buddyUniqueId"
};

const struct OTRMessageEdges OTRMessageEdges = {
	.buddy = @"buddy",
    .media = @"media"
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

- (OTRBuddy *)buddyWithTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    return [OTRBuddy fetchObjectWithUniqueID:self.buddyUniqueId transaction:readTransaction];
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.buddyUniqueId) {
        YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRMessageEdges.buddy
                                                                            destinationKey:self.buddyUniqueId
                                                                                collection:[OTRBuddy collection]
                                                                           nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        
        edges = @[buddyEdge];
    }
    
    if (self.mediaItemUniqueId) {
        YapDatabaseRelationshipEdge *mediaEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRMessageEdges.media
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

#pragma - mark Class Methods

+ (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction*)transaction
{
    __block int count = 0;
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, OTRMessage *message, BOOL *stop) {
        if ([message isKindOfClass:[OTRMessage class]]) {
            if (!message.isRead) {
                count +=1;
            }
        }
    }];
    return count;
}

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [transaction removeAllObjectsInCollection:[OTRMessage collection]];
}

+ (void)deleteAllMessagesForBuddyId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:uniqueBuddyId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction removeObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
    //Update Last message date for sorting and grouping
    OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:uniqueBuddyId transaction:transaction];
    buddy.lastMessageDate = nil;
    [buddy saveWithTransaction:transaction];
}

+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyEdges.account destinationKey:uniqueAccountId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [self deleteAllMessagesForBuddyId:edge.sourceKey transaction:transaction];
    }];
}

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    __block OTRMessage *deliveredMessage = nil;
    [self enumerateMessagesWithMessageId:messageId transaction:transaction usingBlock:^(OTRMessage *message, BOOL *stop) {
        if (!message.isIncoming) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            if (![message.mediaItemUniqueId length]) {
                deliveredMessage = message;
                *stop = YES;
            }
            
        }
    }];
    if (deliveredMessage) {
        deliveredMessage.delivered = YES;
        [deliveredMessage saveWithTransaction:transaction];
    }
}

+ (void)showLocalNotificationForMessage:(OTRMessage *)message
{
    if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString * rawMessage = [message.text stringByConvertingHTMLToPlainText];
            // We are not active, so use a local notification instead
            __block OTRBuddy *localBuddy = nil;
            __block OTRAccount *localAccount;
            __block NSInteger unreadCount = 0;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                localBuddy = [message buddyWithTransaction:transaction];
                localAccount = [localBuddy accountWithTransaction:transaction];
                unreadCount = [self numberOfUnreadMessagesWithTransaction:transaction];
            }];
            
            NSString *name = localBuddy.username;
            if ([localBuddy.displayName length]) {
                name = localBuddy.displayName;
            }
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = REPLY_STRING;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = unreadCount;
            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",name,rawMessage];
            
            localNotification.userInfo = @{kOTRNotificationBuddyUniqueIdKey:localBuddy.uniqueId};
        
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    }
}

+ (void)enumerateMessagesWithMessageId:(NSString *)messageId transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(OTRMessage *message,BOOL *stop))block;
{
    if ([messageId length] && block) {
        NSString *queryString = [NSString stringWithFormat:@"Where %@ = ?",OTRYapDatabseMessageIdSecondaryIndex];
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:queryString,messageId];
        
        [[transaction ext:OTRYapDatabseMessageIdSecondaryIndexExtension] enumerateKeysMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:key transaction:transaction];
            if (message) {
                block(message,stop);
            }
        }];
        
    }    
}

@end
