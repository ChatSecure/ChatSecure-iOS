//
//  OTRBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddyCache.h"
@import YapDatabase;
#import "OTRImages.h"
@import JSQMessagesViewController;
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import OTRKit;
#import "OTRLog.h"
#import "OTRColors.h"
#import "NSString+ChatSecure.h"

@implementation OTRBuddy
@synthesize displayName = _displayName;
@dynamic statusMessage, chatState, lastSentChatState, status;

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
    // Never set displayName the same as the username
    if ([displayName isEqualToString:self.username]) {
        return;
    }
    if (![_displayName isEqualToString:displayName]) {
        _displayName = displayName;
        if (!self.avatarData) {
            [OTRImages removeImageWithIdentifier:self.uniqueId];
        }
    }
}

- (NSString*) displayName {
    // If user has set a displayName that isn't the JID, use that immediately
    if (_displayName.length > 0 && ![_displayName isEqualToString:self.username]) {
        return _displayName;
    }
    NSString *user = [self.username otr_displayName];
    if (!user.length) {
        return _displayName;
    }
    return user;
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageBuddyEdgeName];
    NSUInteger numberOfMessages = [[transaction ext:extensionName] edgeCountWithName:edgeName destinationKey:self.uniqueId collection:[OTRBuddy collection]];
    return (numberOfMessages > 0);
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (NSUInteger)numberOfUnreadMessagesWithTransaction:(nonnull YapDatabaseReadTransaction*)transaction {
    YapDatabaseSecondaryIndexTransaction *indexTransaction = [transaction ext:OTRMessagesSecondaryIndex];
    if (!indexTransaction) {
        return 0;
    }
    NSString *queryString = [NSString stringWithFormat:@"WHERE %@ == %@ AND %@ == ?", OTRYapDatabaseUnreadMessageSecondaryIndexColumnName, @(NO), OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName];
    YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:queryString, self.uniqueId];
    NSUInteger numRows = 0;
    BOOL success = [indexTransaction getNumberOfRows:&numRows matchingQuery:query];
    if (!success) {
        DDLogError(@"Query error for OTRBuddy numberOfUnreadMessagesWithTransaction");
    }
    return numRows;
}

- (id <OTRMessageProtocol>)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block id <OTRMessageProtocol> finalMessage = nil;
    
    if (self.lastMessageId.length) {
        finalMessage = [OTRBaseMessage fetchObjectWithUniqueID:self.lastMessageId transaction:transaction];
    }
    if (finalMessage) {
        return finalMessage;
    }
    
    // Use slow lookup for legacy db migration
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageBuddyEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBaseMessage *message = [OTRBaseMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!finalMessage ||    [message.date compare:finalMessage.date] == NSOrderedDescending) {
            finalMessage = (id <OTRMessageProtocol>)message;
        }
        
    }];
    return finalMessage;
}

- (void)bestTransportSecurityWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction completionBlock:(void (^_Nonnull)(OTRMessageTransportSecurity))block completionQueue:(nonnull dispatch_queue_t)queue
{
    NSParameterAssert(transaction);
    NSParameterAssert(block);
    NSParameterAssert(queue);
    if (!block || !queue || !transaction) { return; }
    NSArray <OTROMEMODevice *>*devices = [OTROMEMODevice allDevicesForParentKey:self.uniqueId
                                                                     collection:[[self class] collection]
                                                                        transaction:transaction];
    // If we have some omemo devices then that's the best we have.
    if ([devices count] > 0) {
        dispatch_async(queue, ^{
            block(OTRMessageTransportSecurityOMEMO);
        });
        return;
    }
    
    OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
    
    // Check if we have fingerprints for this buddy. This is the best proxy we have for detecting if we have had an otr session in the past.
    // If we had a session in the past then we should use that otherwise.
    NSArray<OTRFingerprint *> *allFingerprints = [[OTRProtocolManager sharedInstance].encryptionManager.otrKit fingerprintsForUsername:self.username accountName:account.username protocol:account.protocolTypeString];
    if ([allFingerprints count]) {
        dispatch_async(queue, ^{
            block(OTRMessageTransportSecurityOTR);
        });
    } else {
        dispatch_async(queue, ^{
            block(OTRMessageTransportSecurityPlaintext);
        });
    }
}

#pragma - mark OTRUserInfoProfile Protocol

- (UIColor *)avatarBorderColor
{
    OTRThreadStatus threadStatus = [self currentStatus];
    if (threadStatus == OTRThreadStatusOffline) {
        return nil;
    }
    return [OTRColors colorWithStatus:[self currentStatus]];
}

#pragma - mark OTRThreadOwner Methods

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
    return [[OTRBuddyCache sharedInstance] threadStatusForBuddy:self];
}

- (BOOL)isGroupThread {
    return NO;
}

#pragma mark Dynamic Properties

- (NSString*) statusMessage {
    return [[OTRBuddyCache sharedInstance] statusMessageForBuddy:self];
}

- (OTRChatState) chatState {
    return [[OTRBuddyCache sharedInstance] chatStateForBuddy:self];
}

- (OTRChatState) lastSentChatState {
    return [[OTRBuddyCache sharedInstance] lastSentChatStateForBuddy:self];
}

- (OTRThreadStatus) status {
    return [[OTRBuddyCache sharedInstance] threadStatusForBuddy:self];
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
        // Checking buddy class is a hotfix for issue #472
        if (buddy &&
            [buddy isKindOfClass:[OTRBuddy class]] &&
            [buddy.username.lowercaseString isEqualToString:username.lowercaseString]) {
            *stop = YES;
            finalBuddy = buddy;
        }
    }];

    return finalBuddy;
}

#pragma mark Disable Mantle Storage of Dynamic Properties

+ (NSSet<NSString*>*) excludedProperties {
    static NSSet<NSString*>* excludedProperties = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludedProperties = [NSSet setWithArray:@[NSStringFromSelector(@selector(statusMessage)),
                               NSStringFromSelector(@selector(chatState)),
                               NSStringFromSelector(@selector(lastSentChatState)),
                               NSStringFromSelector(@selector(status))]];
    });
    return excludedProperties;
}

// See MTLModel+NSCoding.h
// This helps enforce that only the properties keys that we
// desire will be encoded. Be careful to ensure that values
// that should be stored in the keychain don't accidentally
// get serialized!
+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *behaviors = [NSMutableDictionary dictionaryWithDictionary:[super encodingBehaviorsByPropertyKey]];
    NSSet<NSString*> *excludedProperties = [self excludedProperties];
    [excludedProperties enumerateObjectsUsingBlock:^(NSString * _Nonnull selector, BOOL * _Nonnull stop) {
        [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:selector];
    }];
    return behaviors;
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    NSSet<NSString*> *excludedProperties = [self excludedProperties];
    if ([excludedProperties containsObject:propertyKey]) {
        return MTLPropertyStorageNone;
    }
    return [super storageBehaviorForPropertyWithKey:propertyKey];
}

@end
