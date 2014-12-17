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
#import "OTRImages.h"
#import "JSQMessagesAvatarImageFactory.h"
#import "OTRKit.h"

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

- (UIImage *)avatarImage
{
    //on setAvatar clear this buddies image cache
    //invalidate if jid or display name changes 
    UIImage *image = [OTRImages imageWithIdentifier:self.uniqueId];
    if (!image) {
        if (self.avatarData) {
            image = [UIImage imageWithData:self.avatarData];
        }
        else {
            
            JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:[self displayInitials]
                                                                                          backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                                textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                                     font:[UIFont systemFontOfSize:30.0f]
                                                                                                 diameter:60];
            image = jsqImage.avatarImage;
        }
        
        [OTRImages setImage:image forIdentifier:self.uniqueId];
    }
    
    return image;
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

- (NSString *)displayInitials
{
    NSUInteger maxInitials = 2;
    if ([self.displayName length]) {
        return [self initialsFromString:self.displayName maxCharacters:maxInitials];
    }
    else {
        NSString *username = [[self.username componentsSeparatedByString:@"@"] firstObject];
        if (![username length]) {
            username = self.username;
        }
        return [self initialsFromString:username maxCharacters:maxInitials];
    }
}

- (NSString *)initialsFromString:(NSString *)string maxCharacters:(NSUInteger)maxCharacters
{
    if (![string length]) {
        return nil;
    }
    
    if (maxCharacters == 1) {
        return [string substringToIndex:1];
    } else {
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ._-+"];
        NSArray *splitArray = [string componentsSeparatedByCharactersInSet:characterSet];
        if ([splitArray count] > maxCharacters) {
            splitArray = [splitArray subarrayWithRange:NSMakeRange(0, maxCharacters)];
        }
        
        NSMutableString *finalString = [[NSMutableString alloc] init];
        [splitArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            if ([obj length]) {
                [finalString appendString:[obj substringToIndex:1]];
            }
            
        }];
        
        return [finalString uppercaseString];
    }
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSUInteger numberOfMessages = [[transaction ext:OTRYapDatabaseRelationshipName] edgeCountWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection]];
    return (numberOfMessages > 0);
}

- (void)updateLastMessageDateWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSDate *date = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
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

- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSUInteger count = 0;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!message.isRead) {
            count += 1;
        }
    }];
    return count;
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [[OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction] copy];
        
        if (!message.isRead) {
            message.read = YES;
            [message saveWithTransaction:transaction];
        }
    }];
}
- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRMessage *finalMessage = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.buddy destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!finalMessage ||    [message.date compare:finalMessage.date] == NSOrderedDescending) {
            finalMessage = message;
        }
        
    }];
    return [finalMessage copy];
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

#pragma - mark Class Methods

+ (instancetype)fetchBuddyForUsername:(NSString *)username accountName:(NSString *)accountName transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRAccount *account = [[OTRAccount allAccountsWithUsername:accountName transaction:transaction] firstObject];
    return [self fetchBuddyWithUsername:username withAccountUniqueId:account.uniqueId transaction:transaction];
}

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
    
    return [finalBuddy copy];
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
        if(buddy.status != OTRBuddyStatusOffline)
        {
            [buddiesToChange addObject:buddy];
        }
    }];
    
    [buddiesToChange enumerateObjectsUsingBlock:^(OTRBuddy *buddy, NSUInteger idx, BOOL *stop) {
        buddy.status = OTRBuddyStatusOffline;
        [buddy saveWithTransaction:transaction];
    }];
}

@end
