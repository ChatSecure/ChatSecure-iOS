//
//  OTRYapDatabaseRosterStorage.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseRosterStorage.h"

#import "OTRDatabaseManager.h"
#import "OTRLog.h"
#import "OTRXMPPBuddy.h"
#import "OTRXMPPAccount.h"

#import "OTRBuddyCache.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@import OTRAssets;

@implementation OTRYapDatabaseRosterStorage

-(instancetype)init
{
    if (self = [super init]) {
        _connection = OTRDatabaseManager.shared.readWriteDatabaseConnection;
    }
    return self;
}

#pragma - mark Helper Methods

/** Turns out buddies are created during account creation before the account object is saved to the database. oh brother */
- (nonnull NSString*)accountUniqueIdForStream:(XMPPStream*)stream {
    NSParameterAssert(stream.tag);
    return stream.tag;
}

- (nullable OTRXMPPBuddy *)fetchBuddyWithJID:(XMPPJID *)jid stream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    NSString *accountUniqueId = [self accountUniqueIdForStream:stream];
    OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyWithJid:jid accountUniqueId:accountUniqueId transaction:transaction];
    return buddy;
}

- (BOOL)existsBuddyWithJID:(XMPPJID *)jid xmppStram:(XMPPStream *)stream
{
    __block BOOL result = NO;
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [self fetchBuddyWithJID:jid stream:stream transaction:transaction];
        if (buddy) {
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                OTRXMPPBuddy *xmppBuddy = (OTRXMPPBuddy*)buddy;
                result = (xmppBuddy.trustLevel == BuddyTrustLevelRoster);
            } else {
                result = YES;
            }
        }
    }];
    return result;
}

#pragma - mark XMPPRosterStorage Methods

- (BOOL)configureWithParent:(XMPPRoster *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream withVersion:(NSString *)version
{
    //DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}
- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    //DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}

- (void)handleRosterItem:(NSXMLElement *)item xmppStream:(XMPPStream *)stream {
}

- (void)handlePresence:(XMPPPresence *)presence xmppStream:(XMPPStream *)stream
{
    __block OTRXMPPBuddy *buddy = nil;
    [self.connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddy = [self fetchBuddyWithJID:[presence from] stream:stream transaction:transaction];
    }];
    if (!buddy) {
        return;
    }
    OTRXMPPBuddy *newBuddy = [buddy copy];
    
    NSString *resource = [presence from].resource;
    OTRThreadStatus newStatus = OTRThreadStatusOffline;
    NSString *newStatusMessage = OFFLINE_STRING();
    if (buddy && !([[presence type] isEqualToString:@"unavailable"] || [presence isErrorPresence])) {
        NSString *defaultMessage = OFFLINE_STRING();
        switch (presence.showValue)
        {
            case XMPPPresenceShowDND  :
                newStatus = OTRThreadStatusDoNotDisturb;
                newStatusMessage = DO_NOT_DISTURB_STRING();
                break;
            case XMPPPresenceShowXA  :
                newStatus = OTRThreadStatusExtendedAway;
                newStatusMessage = EXTENDED_AWAY_STRING();
                break;
            case XMPPPresenceShowAway  :
                newStatus = OTRThreadStatusAway;
                newStatusMessage = AWAY_STRING();
                break;
            case XMPPPresenceShowOther  :
            case XMPPPresenceShowChat  :
                newStatus = OTRThreadStatusAvailable;
                newStatusMessage = AVAILABLE_STRING();
                break;
            default :
                break;
        }
        if ([[presence status] length]) {
            [OTRBuddyCache.shared setStatusMessage:[presence status] forBuddy:newBuddy];
        }
        else {
            [OTRBuddyCache.shared setStatusMessage:defaultMessage forBuddy:newBuddy];
        }
    }
    [OTRBuddyCache.shared setThreadStatus:newStatus forBuddy:newBuddy resource:resource];
    
    if ([presence.type isEqualToString:@"subscribed"]) {

        [newBuddy setPendingApproval:NO];
        [self.connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [newBuddy saveWithTransaction:transaction];
        }];
        
        // Send acknowledgement
        XMPPJID *jid = newBuddy.bareJID;
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"subscribe" to:jid];
        [stream sendElement:presence];
        [stream resendMyPresence];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:OTRBuddyPendingApprovalDidChangeNotification object:self userInfo:@{@"buddy": newBuddy}];
        });
    } else if ([presence.type isEqualToString:@"unsubscribed"]) {
        [newBuddy setPendingApproval:NO];
        [self.connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [newBuddy saveWithTransaction:transaction];
        }];
        
        // Send acknowledgement
        XMPPJID *jid = newBuddy.bareJID;
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unsubscribe" to:jid];
        [stream sendElement:presence];
    }
    
    // Update Last Seen
    NSDate *lastSeen = nil;
    NSDate *idleDate = nil;
    NSDate *delayedDeliveryDate = [presence delayedDeliveryDate];
    NSXMLElement *idleElement = [presence elementForName:@"idle" xmlns:@"urn:xmpp:idle:1"];
    NSString *idleDateString = [idleElement attributeStringValueForName:@"since"];
    if (idleDateString) {
        idleDate = [NSDate dateWithXmppDateTimeString:idleDateString];
    }
    if (newStatus == OTRThreadStatusAvailable) {
        lastSeen = [NSDate date];
    } else if (idleDate) {
        lastSeen = idleDate;
    } else if (delayedDeliveryDate) {
        lastSeen = delayedDeliveryDate;
    }
    if (lastSeen) {
        [OTRBuddyCache.shared setLastSeenDate:lastSeen forBuddy:newBuddy];
    }
}

- (BOOL)userExistsWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    if ([self existsBuddyWithJID:jid xmppStram:stream]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
    //DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}
- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
    //DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}

- (NSArray *)jidsForXMPPStream:(XMPPStream *)stream
{
    __block NSMutableArray *jidArray = [NSMutableArray array];
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[OTRXMPPBuddy collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
            if ([object isKindOfClass:[OTRXMPPBuddy class]]) {
                OTRXMPPBuddy *buddy = (OTRXMPPBuddy *)object;
                if ([buddy.username length]) {
                    [jidArray addObject:buddy.username];
                }
            }
        }];
    }];
    return jidArray;
}

- (void)getSubscription:(NSString * _Nullable * _Nullable)subscription
                    ask:(NSString * _Nullable * _Nullable)ask
               nickname:(NSString * _Nullable * _Nullable)nickname
                 groups:(NSArray<NSString*> * _Nullable * _Nullable)groups
                 forJID:(XMPPJID *)jid
             xmppStream:(XMPPStream *)stream
{
    //Can't tell if this is ever called so just a stub for now
    //OTRXMPPBuddy *buddy = [self buddyWithJID:jid xmppStream:stream];
    //*nickname = buddy.displayName;
}

@end
