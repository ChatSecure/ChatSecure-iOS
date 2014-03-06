
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

@interface OTRvCardCoreDataStorage ()

@property (nonatomic, strong) dispatch_queue_t storageQueue;

@end

@implementation OTRvCardCoreDataStorage

- (id)init
{
    if (self = [super init]) {
        self.storageQueue = dispatch_queue_create("OTR.vCardCoreDataStorage", NULL);
    }
    return self;
}

//XMPPvCardTempModule.h

#pragma - mark XMPPvCardTempModule Protocol Methods

- (BOOL)configureWithParent:(XMPPvCardTempModule *)aParent queue:(dispatch_queue_t)queue {
    
    return YES;
}

/**
 * Returns a vCardTemp object or nil
 **/
- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    return vCard.vCardTemp;
}

/**
 * Used to set the vCardTemp object when we get it from the XMPP server.
 **/
- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
    vCard.vCardTemp = vCardTemp ;
    
    NSData * photoData = vCardTemp.photo;
    vCard.photoData = photoData;
    
    vCard.lastUpdated = [NSDate date];
    
    [context MR_saveToPersistentStoreAndWait];
}

/**
 * Returns My vCardTemp object or nil
 **/
- (XMPPvCardTemp *)myvCardTempForXMPPStream:(XMPPStream *)stream {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    XMPPvCardTemp * vCardTemp = [self vCardTempForJID:stream.myJID xmppStream:stream];
    [context MR_saveToPersistentStoreAndWait];
    return vCardTemp;
}



/**
 * Asks the backend if we should fetch the vCardTemp from the network.
 * This is used so that we don't request the vCardTemp multiple times.
 **/
- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
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
    [context MR_saveToPersistentStoreAndWait];
    return result;
}
// XMPPvCardAvatarModule
#pragma - mark XMPPvCardAvatarStorage Protocol Methods

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    return vCard.photoData;
}
- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    return vCard.photoHash;
}

/**
 * Clears the vCardTemp from the store.
 * This is used so we can clear any cached vCardTemp's for the JID.
 **/
- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_context];
    OTRvCard * vCard = [OTRvCard fetchOrCreateWithJidString:[jid bare] inContext:context];
    vCard.vCardTemp = nil;
    vCard.lastUpdated = [NSDate date];
    [context MR_saveToPersistentStoreAndWait];
}

@end
