//
//  OTRvCardYapDatabaseStorage.m
//  Off the Record
//
//  Created by David Chiles on 4/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRvCardYapDatabaseStorage.h"
#import "OTRDatabaseManager.h"
#import "OTRXMPPBuddy.h"
#import "OTRXMPPAccount.h"
@import XMPPFramework;

@interface OTRvCardYapDatabaseStorage ()

@property (nonatomic, strong) dispatch_queue_t storageQueue;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;


@end

@implementation OTRvCardYapDatabaseStorage

- (id)init
{
    if (self = [super init]) {
        self.storageQueue = dispatch_queue_create("OTR.OTRvCardYapDatabaseStorage", NULL);
        self.databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return self;
}

- (OTRXMPPBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
    return [OTRXMPPBuddy fetchBuddyWithUsername:[jid bare] withAccountUniqueId:account.uniqueId transaction:transaction];
}

- (OTRXMPPBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream;
{
    __block OTRXMPPBuddy *buddy = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [self buddyWithJID:jid xmppStream:stream transaction:transaction];
    }];
    return buddy;
}


- (OTRXMPPAccount*)accountWithStream:(XMPPStream*)stream {
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
    }];
    return account;
}

#pragma - mark XMPPvCardAvatarStorage Methods

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    NSData *photoData = nil;
    if ([jid isEqualToJID:stream.myJID options:XMPPJIDCompareBare]) {
        photoData = [self accountWithStream:stream].avatarData;
    } else {
        photoData = [self buddyWithJID:jid xmppStream:stream].avatarData;
    }
    return photoData;
    
}

- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    NSString *photoHash = nil;
    if ([jid isEqualToJID:stream.myJID options:XMPPJIDCompareBare]) {
        photoHash = [self accountWithStream:stream].photoHash;
    } else {
        photoHash = [self buddyWithJID:jid xmppStream:stream].photoHash;
    }
    return photoHash;
}

/**
 * Clears the vCardTemp from the store.
 * This is used so we can clear any cached vCardTemp's for the JID.
 **/
- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        id<OTRvCard> vCard = nil;
        if ([jid isEqualToJID:stream.myJID options:XMPPJIDCompareBare]) {
            vCard = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        } else {
            vCard = [[self buddyWithJID:jid xmppStream:stream transaction:transaction] copy];
        }
        vCard.vCardTemp = nil;
        [vCard saveWithTransaction:transaction];
    }];
}

#pragma - mark XMPPvCardTempModuleStorage Methods

/**
 * Configures the storage class, passing its parent and parent's dispatch queue.
 *
 * This method is called by the init methods of the XMPPvCardTempModule class.
 * This method is designed to inform the storage class of its parent
 * and of the dispatch queue the parent will be operating on.
 *
 * The storage class may choose to operate on the same queue as its parent,
 * or it may operate on its own internal dispatch queue.
 *
 * This method should return YES if it was configured properly.
 * The parent class is configured to ignore the passed
 * storage class in its init method if this method returns NO.
 **/
- (BOOL)configureWithParent:(XMPPvCardTempModule *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

/**
 * Returns a vCardTemp object or nil
 **/
- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    XMPPvCardTemp *vCardTemp = nil;
    if ([jid isEqualToJID:stream.myJID options:XMPPJIDCompareBare]) {
        vCardTemp = [self accountWithStream:stream].vCardTemp;
    } else {
        vCardTemp = [self buddyWithJID:jid xmppStream:stream].vCardTemp;
    }
    return vCardTemp;
}

/**
 * Used to set the vCardTemp object when we get it from the XMPP server.
 **/
- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        id<OTRvCard> vCard = nil;
        if ([stream.myJID isEqualToJID:jid options:XMPPJIDCompareBare]) {
            vCard = [[OTRXMPPAccount accountForStream:stream transaction:transaction] copy];
        } else {
            vCard = [[self buddyWithJID:jid xmppStream:stream transaction:transaction] copy];
        }
        vCard.vCardTemp = vCardTemp;
        vCard.waitingForvCardTempFetch = NO;
        vCard.lastUpdatedvCardTemp = [NSDate date];
        [vCard saveWithTransaction:transaction];
    }];
    
}

/**
 * Returns My vCardTemp object or nil
 **/
- (XMPPvCardTemp *)myvCardTempForXMPPStream:(XMPPStream *)stream
{
    if (!stream) {
        return nil;
    }
    
    return [self accountWithStream:stream].vCardTemp;
}

/**
 * Asks the backend if we should fetch the vCardTemp from the network.
 * This is used so that we don't request the vCardTemp multiple times.
 **/
- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    
    if (![stream isAuthenticated]) {
        return NO;
    }
    
    __block BOOL result = NO;
    
    // Saving is not required due to internal use of in-memory OTRBuddyCache
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        id<OTRvCard> vCard = nil;
        if ([jid isEqualToJID:stream.myJID options:XMPPJIDCompareBare]) {
            vCard = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        } else {
            vCard = [self buddyWithJID:jid xmppStream:stream transaction:transaction];
        }
        
        if (vCard.waitingForvCardTempFetch) {
            result = NO;
        } else if ([vCard.lastUpdatedvCardTemp timeIntervalSinceNow] <= -24*60*60 ||
                   !vCard.vCardTemp) {
            //This goes to the cache and does not change the database object.
            vCard.waitingForvCardTempFetch = YES;
            result = YES;
        }
    }];
    
    
    return result;
}

@end
