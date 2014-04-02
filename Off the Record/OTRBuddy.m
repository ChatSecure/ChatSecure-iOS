//
//  OTRBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"

const struct OTRBuddyAttributes OTRBuddyAttributes = {
	.username = @"username",
	.displayName = @"displayName",
	.composingMessageString = @"composingMessageString",
	.statusMessage = @"statusMessage",
	.chatState = @"chatState",
	.lastSentChatState = @"lastSentChatState",
	.status = @"status",
    .lastMessageDate = @"lastMessageDate"
};

const struct OTRBuddyRelationships OTRBuddyRelationships = {
	.accountUniqueId = @"accountUniqueId",
};

const struct OTRBuddyEdges OTRBuddyEdges = {
	.account = @"account",
};

@implementation OTRBuddy

- (id)init
{
    if (self = [super init]) {
        self.status = OTRBuddyStatusOffline;
        self.chatState = kOTRChatStateUnknown;
        self.lastSentChatState = kOTRChatStateUnknown;
    }
    return self;
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block BOOL result = NO;
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, OTRMessage *message, BOOL *stop) {
        if ([message isKindOfClass:[OTRMessage class]]) {
            if ([message.buddyUniqueId isEqualToString:self.uniqueId]) {
                result = YES;
                *stop = YES;
            }
        }
    }];
    return result;
}

- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSUInteger count = 0;
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, OTRMessage *message, BOOL *stop) {
        if ([message isKindOfClass:[OTRMessage class]]) {
            if (!message.isRead && [message.buddyUniqueId isEqualToString:self.uniqueId]) {
                count +=1;
            }
        }
    }];
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
        if ([object isKindOfClass:[OTRMessage class]]) {

            OTRMessage *message = (OTRMessage *)object;
            if ([message.buddyUniqueId isEqualToString:self.uniqueId]) {
                message.read = YES;
                [transaction setObject:message forKey:message.uniqueId inCollection:[OTRMessage collection]];
            }
            
        }
    }];
}

#pragma - mark Class Methods

+ (instancetype)fetchBuddyWithUsername:(NSString *)username withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRBuddy *finalBuddy = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddy * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddy collection]];
        if ([buddy.username isEqualToString:username]) {
            *stop = YES;
            finalBuddy = buddy;
        }
    }];
    
    return finalBuddy;
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBuddyEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.username = [decoder decodeObjectForKey:OTRBuddyAttributes.username];
        self.displayName = [decoder decodeObjectForKey:OTRBuddyAttributes.displayName];
        self.composingMessageString = [decoder decodeObjectForKey:OTRBuddyAttributes.composingMessageString];
        self.statusMessage = [decoder decodeObjectForKey:OTRBuddyAttributes.statusMessage];
        self.status = [decoder decodeIntForKey:OTRBuddyAttributes.status];
        self.chatState = [decoder decodeIntForKey:OTRBuddyAttributes.chatState];
        self.lastSentChatState = [decoder decodeIntForKey:OTRBuddyAttributes.lastSentChatState];
        self.lastMessageDate = [decoder decodeObjectForKey:OTRBuddyAttributes.lastMessageDate];
        
        self.accountUniqueId = [decoder decodeObjectForKey:OTRBuddyRelationships.accountUniqueId];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.username forKey:OTRBuddyAttributes.username];
    [encoder encodeObject:self.displayName forKey:OTRBuddyAttributes.displayName];
    [encoder encodeObject:self.composingMessageString forKey:OTRBuddyAttributes.composingMessageString];
    [encoder encodeObject:self.statusMessage forKey:OTRBuddyAttributes.statusMessage];
    [encoder encodeInt:self.status forKey:OTRBuddyAttributes.status];
    [encoder encodeInt:self.chatState forKey:OTRBuddyAttributes.chatState];
    [encoder encodeInt:self.lastSentChatState forKey:OTRBuddyAttributes.lastSentChatState];
    [encoder encodeObject:self.lastMessageDate forKey:OTRBuddyAttributes.lastMessageDate];
    
    
    [encoder encodeObject:self.accountUniqueId forKey:OTRBuddyRelationships.accountUniqueId];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OTRBuddy *copy = [super copyWithZone:zone];
    copy.username = [self.username copyWithZone:zone];
    copy.displayName = [self.displayName copyWithZone:zone];
    copy.composingMessageString = [self.composingMessageString copyWithZone:zone];
    copy.statusMessage = [self.statusMessage copyWithZone:zone];
    copy.status = self.status;
    copy.chatState = self.chatState;
    copy.lastSentChatState = self.lastSentChatState;
    copy.lastMessageDate = [self.lastMessageDate copyWithZone:zone];
    
    copy.accountUniqueId = [self.accountUniqueId copyWithZone:zone];
    
    return copy;
}

@end
