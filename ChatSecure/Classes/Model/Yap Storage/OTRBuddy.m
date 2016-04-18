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
@import YapDatabase;
#import "OTRImages.h"
#import "JSQMessagesAvatarImageFactory.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import OTRKit;

const struct OTRBuddyAttributes OTRBuddyAttributes = {
	.username = @"username",
	.displayName = @"displayName",
	.composingMessageString = @"composingMessageString",
	.statusMessage = @"statusMessage",
	.chatState = @"chatState",
	.lastSentChatState = @"lastSentChatState",
	.status = @"status",
    .lastMessageDate = @"lastMessageDate",
    .avatarData = @"avatarData",
    .encryptionStatus = @"encryptionStatus"
};

@implementation OTRBuddy

- (id)init
{
    if (self = [super init]) {
        self.status = OTRThreadStatusOffline;
        self.chatState = kOTRChatStateUnknown;
        self.lastSentChatState = kOTRChatStateUnknown;
    }
    return self;
}

/**
 The current or generated avatar image either from avatarData or the initials from displayName or username
 
 @return An UIImage from the OTRImages NSCache
 */
- (UIImage *)avatarImage
{
    //on setAvatar clear this buddies image cache
    //invalidate if jid or display name changes 
    return [OTRImages avatarImageWithUniqueIdentifier:self.uniqueId avatarData:self.avatarData displayName:self.displayName username:self.username];
}

- (void)setAvatarData:(NSData *)avatarData
{
    if (![_avatarData isEqualToData: avatarData]) {
        _avatarData = avatarData;
        [OTRImages removeImageWithIdentifier:self.uniqueId];
    }
}

- (void)setDisplayName:(NSString *)displayName
{
    if (![_displayName isEqualToString:displayName]) {
        _displayName = displayName;
        if (!self.avatarData) {
            [OTRImages removeImageWithIdentifier:self.uniqueId];
        }
    }
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSUInteger numberOfMessages = [[transaction ext:extensionName] edgeCountWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection]];
    return (numberOfMessages > 0);
}

- (void)updateLastMessageDateWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSDate *date = nil;
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    [[transaction ext:extensionName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (message) {
            if (!date) {
                date = message.date;
            }
            else {
                date = [date laterDate:message.date];
            }
        }
    }];
    self.lastMessageDate = date;
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (void)setAllMessagesAsReadInTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    [[transaction ext:extensionName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        id databseObject = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        if ([databseObject isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message = (OTRMessage *)databseObject;
            if (!message.isRead) {
                message.read = YES;
                [message saveWithTransaction:transaction];
            }
        }        
    }];
}
- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRMessage *finalMessage = nil;
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    [[transaction ext:extensionName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!finalMessage ||    [message.date compare:finalMessage.date] == NSOrderedDescending) {
            finalMessage = message;
        }
        
    }];
    return [finalMessage copy];
}

#pragma - makr OTRThreadOwner Methods

- (NSString *)threadName
{
    NSString *threadName = [self.displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(![threadName length]) {
        threadName = self.username;
    }
    return threadName;
}

- (NSString *)threadIdentifier {
    return self.uniqueId;
}

- (NSString *)threadAccountIdentifier {
    return self.accountUniqueId;
}

- (NSString *)threadCollection {
    return [OTRBuddy collection];
}

- (void)setCurrentMessageText:(NSString *)text
{
    self.composingMessageString = text;
}

- (NSString *)currentMessageText {
    return self.composingMessageString;
}

- (OTRThreadStatus)currentStatus {
    return self.status;
}

- (BOOL)isGroupThread {
    return NO;
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameBuddyAccountEdgeName];
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}

#pragma - mark Class Methods

+ (instancetype)fetchBuddyForUsername:(NSString *)username accountName:(NSString *)accountName transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRAccount *account = [[OTRAccount allAccountsWithUsername:accountName transaction:transaction] firstObject];
    return [self fetchBuddyWithUsername:username withAccountUniqueId:account.uniqueId transaction:transaction];
}

+ (instancetype)fetchBuddyWithUsername:(NSString *)username withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRBuddy *finalBuddy = nil;
    
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameBuddyAccountEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        //Some how we're getting OTRXMPPPresensceSubscritionreuest
        OTRBuddy * buddy = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        if ([buddy.username isEqualToString:username]) {
            *stop = YES;
            finalBuddy = buddy;
        }
    }];

    if (finalBuddy) {
        finalBuddy = [finalBuddy copy];
    }
    
    return finalBuddy;
}

+ (void)resetAllChatStatesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSMutableArray *buddiesToChange = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, OTRBuddy *buddy, BOOL *stop) {
        if(buddy.chatState != kOTRChatStateUnknown)
        {
            [buddiesToChange addObject:buddy];
        }
    }];
    
    [buddiesToChange enumerateObjectsUsingBlock:^(OTRBuddy *buddy, NSUInteger idx, BOOL *stop) {
        buddy.chatState = kOTRChatStateUnknown;
        [buddy saveWithTransaction:transaction];
    }];
}

+ (void)resetAllBuddyStatusesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSMutableArray *buddiesToChange = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, OTRBuddy *buddy, BOOL *stop) {
        if(buddy.status != OTRThreadStatusOffline)
        {
            [buddiesToChange addObject:buddy];
        }
    }];
    
    [buddiesToChange enumerateObjectsUsingBlock:^(OTRBuddy *buddy, NSUInteger idx, BOOL *stop) {
        buddy.status = OTRThreadStatusOffline;
        [buddy saveWithTransaction:transaction];
    }];
}

@end
