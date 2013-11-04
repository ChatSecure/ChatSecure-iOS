//
//  OTRvCardCoreDataStorage.m
//  Off the Record
//
//  Created by David Chiles on 10/24/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRvCardCoreDataStorage.h"

#import "OTRvCard.h"
#import "OTRvCardAvatar.h"
#import "OTRvCardTemp.h"

#import "XMPPvCardTemp.h"

#import "XMPPJID.h"
#import "OTRManagedBuddy.h"
#import "OTRAccountsManager.h"

@implementation OTRvCardCoreDataStorage

-(OTRManagedBuddy *)fetchBuddyWithJid:(XMPPJID *)JID withStram:(XMPPStream *)stream {
    
    return [OTRManagedBuddy fetchWithName:[JID bare] account:[OTRAccountsManager accountForProtocol:@"xmpp" accountName:[stream.myJID bare]]];
}

//XMPPvCardTempModule.h

- (BOOL)configureWithParent:(XMPPvCardTempModule *)aParent queue:(dispatch_queue_t)queue {
    return YES;
}

/**
 * Returns a vCardTemp object or nil
 **/
- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
    return vCard.vCardTemp;
}

/**
 * Used to set the vCardTemp object when we get it from the XMPP server.
 **/
- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    
    [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
        OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
        vCard.vCardTemp = vCardTemp;
        
        NSData * photoData = vCardTemp.photo;
        vCard.photoData = photoData;
        
        vCard.lastUpdated = [NSDate date];
    } completion:^(BOOL success, NSError *error) {
        DDLogInfo(@"Saved vCard: %hhd",success);
    }];
    
}

/**
 * Returns My vCardTemp object or nil
 **/
- (XMPPvCardTemp *)myvCardTempForXMPPStream:(XMPPStream *)stream {
    return [self vCardTempForJID:stream.myJID xmppStream:stream];
}

/**
 * Asks the backend if we should fetch the vCardTemp from the network.
 * This is used so that we don't request the vCardTemp multiple times.
 **/
- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
    BOOL waitingForFetch = vCard.waitingForFetchValue;
    BOOL result;
    if(![stream isAuthenticated])
    {
        result = NO;
    }
    else if (!waitingForFetch)
    {
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            vCard.waitingForFetch = [NSNumber numberWithBool:YES];
            vCard.lastUpdated = [NSDate date];
        }];
        
        result = YES;
    }
    else if ([vCard.lastUpdated timeIntervalSinceNow] < -10)
    {
        // Our last request exceeded the timeout, send a new one
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            vCard.lastUpdated = [NSDate date];
        }];
        
        
        result = YES;
    }
    else
    {
        // We already have an outstanding request, no need to send another one.
        result = NO;
    }
    return result;
}
// XMPPvCardAvatarModule

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
    return vCard.photoData;
}
- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
    return vCard.photoHash;
}

/**
 * Clears the vCardTemp from the store.
 * This is used so we can clear any cached vCardTemp's for the JID.
 **/
- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare]];
        vCard.vCardTemp = nil;
        vCard.lastUpdated = [NSDate date];
    }];
    
}

@end
