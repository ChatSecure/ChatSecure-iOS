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
#import "XMPPJID.h"
#import "XMPPvCardTemp.h"

@interface OTRvCardYapDatabaseStorage ()

@property (nonatomic, strong) dispatch_queue_t storageQueue;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;


@end

@implementation OTRvCardYapDatabaseStorage

- (id)init
{
    if (self = [super init]) {
        self.storageQueue = dispatch_queue_create("OTR.OTRvCardYapDatabaseStorage", NULL);
        self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
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

- (OTRXMPPAccount *)accountWithxmppStream:(XMPPStream *)stream
{
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
    }];
    return account;
}

#pragma - mark XMPPvCardAvatarStorage Methods

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    return [self buddyWithJID:jid xmppStream:stream].avatarData;
    
}

- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    return [self buddyWithJID:jid xmppStream:stream].photoHash;
}

/**
 * Clears the vCardTemp from the store.
 * This is used so we can clear any cached vCardTemp's for the JID.
 **/
- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPBuddy *buddy = [[self buddyWithJID:jid xmppStream:stream transaction:transaction] copy];
        buddy.vCardTemp = nil;
        
        [transaction setObject:buddy forKey:buddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
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
    OTRXMPPBuddy *buddy = [self buddyWithJID:jid xmppStream:stream];
    return buddy.vCardTemp;
}

/**
 * Used to set the vCardTemp object when we get it from the XMPP server.
 **/
- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPBuddy *buddy = [[self buddyWithJID:jid xmppStream:stream transaction:transaction] copy];
        
        buddy.vCardTemp = vCardTemp;
        buddy.waitingForvCardTempFetch = NO;
        buddy.lastUpdatedvCardTemp = [NSDate date];
        
        [buddy saveWithTransaction:transaction];
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
    
    return [self buddyWithJID:stream.myJID xmppStream:stream].vCardTemp;
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
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPBuddy * buddy = [[self buddyWithJID:jid xmppStream:stream transaction:transaction] copy];
        if (!buddy.isWaitingForvCardTempFetch) {
            
            buddy.waitingForvCardTempFetch = YES;
            buddy.lastUpdatedvCardTemp = [NSDate date];
            
            result = YES;
        }
        else if ([buddy.lastUpdatedvCardTemp timeIntervalSinceNow] <= -10) {
            
            buddy.lastUpdatedvCardTemp = [NSDate date];
            
            result = YES;
        }
        
        
        if (result) {
            [buddy saveWithTransaction:transaction];
        }
    }];
    
    return result;
}

@end
