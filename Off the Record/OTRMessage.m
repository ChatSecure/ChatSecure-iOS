//
//  OTRMessage.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"
#import "OTRBuddy.h"
#import "YapDatabaseTransaction.h"

const struct OTRMessageAttributes OTRMessageAttributes = {
	.date = @"date",
	.text = @"text",
	.delivered = @"delivered",
	.read = @"read",
	.incoming = @"incoming",
    .messageId = @"messageId"
};

const struct OTRMessageRelationships OTRMessageRelationships = {
	.buddyUniqueId = @"buddyUniqueId",
};

const struct OTRMessageEdges OTRMessageEdges = {
	.buddy = @"buddy",
};


@implementation OTRMessage

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
        self.delivered = NO;
        self.read = NO;
    }
    
}

- (OTRBuddy *)buddyWithTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    return [OTRBuddy fetchObjectWithUniqueID:self.buddyUniqueId transaction:readTransaction];
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRMessageEdges.buddy
                                                                        destinationKey:OTRYapDatabaseObjectAttributes.uniqueId
                                                                            collection:[OTRBuddy collection]
                                                                       nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
    
    return @[buddyEdge];
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.date = [decoder decodeObjectForKey:OTRMessageAttributes.date];
        self.text = [decoder decodeObjectForKey:OTRMessageAttributes.text];
        self.delivered = [decoder decodeBoolForKey:OTRMessageAttributes.delivered];
        self.read = [decoder decodeBoolForKey:OTRMessageAttributes.read];
        self.incoming = [decoder decodeBoolForKey:OTRMessageAttributes.incoming];
        self.messageId = [decoder decodeObjectForKey:OTRMessageAttributes.messageId];
        
        self.buddyUniqueId = [decoder decodeObjectForKey:OTRMessageRelationships.buddyUniqueId];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.date forKey:OTRMessageAttributes.date];
    [encoder encodeObject:self.text forKey:OTRMessageAttributes.text];
    [encoder encodeBool:self.delivered forKey:OTRMessageAttributes.delivered];
    [encoder encodeBool:self.read forKey:OTRMessageAttributes.read];
    [encoder encodeBool:self.incoming forKey:OTRMessageAttributes.incoming];
    [encoder encodeObject:self.messageId forKey:OTRMessageAttributes.messageId];
    
    [encoder encodeObject:self.buddyUniqueId forKey:OTRMessageRelationships.buddyUniqueId];
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
    NSMutableArray *messageKeysToDelete = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, OTRMessage *message, BOOL *stop) {
        
        if ([message isKindOfClass:[OTRMessage class]]) {
            
            if ([message.buddyUniqueId isEqualToString:uniqueBuddyId])
            {
                [messageKeysToDelete addObject:message.uniqueId];
                
            }
        }
        
    }];
    
    if ([messageKeysToDelete count]) {
        [transaction removeObjectsForKeys:messageKeysToDelete inCollection:[OTRMessage collection]];
    }
}

+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    NSMutableSet *accountBuddyIdSet = [NSMutableSet set];
    [transaction enumerateKeysAndObjectsInCollection:[OTRBuddy collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
        if ([object isKindOfClass:[OTRBuddy class]]) {
            OTRBuddy *buddy = (OTRBuddy *)object;
            if ([buddy.accountUniqueId isEqualToString:uniqueAccountId]) {
                [accountBuddyIdSet addObject:buddy.uniqueId];
            }
        }
    }];
    NSMutableArray *deleteMessageKeys = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
        if ([object isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message = (OTRMessage *)object;
            
            if ([accountBuddyIdSet containsObject:message.buddyUniqueId]) {
                [deleteMessageKeys addObject:message.uniqueId];
            }
        }
    }];
    
    [transaction removeObjectsForKeys:deleteMessageKeys inCollection:[OTRMessage collection]];
}

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
        if ([object isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message = (OTRMessage *)object;
            if ([message.messageId isEqualToString:messageId]) {
                message.delivered = YES;
                [transaction setObject:message forKey:message.uniqueId inCollection:[OTRMessage collection]];
                
                *stop = YES;
            }
        }
    }];
}

@end
