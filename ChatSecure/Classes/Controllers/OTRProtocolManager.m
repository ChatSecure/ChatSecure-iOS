//
//  OTRProtocolManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRProtocolManager.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRConstants.h"
#import "OTROAuthRefresher.h"
#import "OTROAuthXMPPAccount.h"
#import "OTRDatabaseManager.h"
#import "OTRPushTLVHandler.h"
#import <BBlock/NSObject+BBlock.h>
@import YapDatabase;

@import KVOController;
@import OTRAssets;
#import "OTRLog.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRXMPPPresenceSubscriptionRequest.h"

@interface _OTRProtocolManager ()
//@property (atomic, strong, readonly, nonnull) NSMutableDictionary<NSString*,id<OTRProtocol>> *protocolManagers;
@end

@implementation _OTRProtocolManager

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        _protocolManagers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSArray<id<OTRProtocol>> *)allProtocols {
    return self.protocolManagers.allValues;
}

- (void)removeProtocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account);
    if (!account) { return; }
    id<OTRProtocol> protocol = nil;
    protocol =  [self.protocolManagers objectForKey:account.uniqueId];
    if (protocol && [protocol respondsToSelector:@selector(disconnect)]) {
        [protocol disconnect];
    }
    [self.protocolManagers removeObjectForKey:account.uniqueId];
}

- (void)addProtocol:(id<OTRProtocol>)protocol forAccount:(OTRAccount *)account
{
    [self.protocolManagers setObject:protocol forKey:account.uniqueId];
}

- (BOOL)existsProtocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account.uniqueId);
    if (!account.uniqueId) { return NO; }
    return [self.protocolManagers objectForKey:account.uniqueId] != nil;
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account);
    if (!account.uniqueId) { return nil; }
    id <OTRProtocol> protocol = nil;
    protocol = [self.protocolManagers objectForKey:account.uniqueId];
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] initWithAccount:account];
        if (protocol && account.uniqueId) {
            [self addProtocol:protocol forAccount:account];
        }
    }
    return protocol;
}

- (nullable OTRXMPPManager*)xmppManagerForAccount:(OTRAccount *)account {
    OTRXMPPManager *xmpp = (OTRXMPPManager*)[self protocolForAccount:account];
    NSParameterAssert([xmpp isKindOfClass:OTRXMPPManager.class]);
    if (![xmpp isKindOfClass:OTRXMPPManager.class]) {
        DDLogError(@"Wrong protocol class for account %@", account);
        return nil;
    }
    return xmpp;
}

- (void)loginAccount:(OTRAccount *)account userInitiated:(BOOL)userInitiated
{
    NSParameterAssert(account);
    if (!account) { return; }
    id <OTRProtocol> protocol = [self protocolForAccount:account];

    if([account isKindOfClass:[OTROAuthXMPPAccount class]])
    {
        [OTROAuthRefresher refreshAccount:(OTROAuthXMPPAccount *)account completion:^(id token, NSError *error) {
            if (!error) {
                ((OTROAuthXMPPAccount *)account).accountSpecificToken = token;
                [protocol connectUserInitiated:userInitiated];
            }
            else {
                DDLogError(@"Error Refreshing Token");
            }
        }];
    }
    else
    {
        [protocol connectUserInitiated:userInitiated];
    }
}

- (void)loginAccount:(OTRAccount *)account
{
    [self loginAccount:account userInitiated:NO];
}

- (void)loginAccounts:(NSArray *)accounts
{
    [accounts enumerateObjectsUsingBlock:^(OTRAccount * account, NSUInteger idx, BOOL *stop) {
        [self loginAccount:account];
    }];
}

- (void)goAwayForAllAccounts {
    [self.protocolManagers enumerateKeysAndObjectsUsingBlock:^(id key, id <OTRProtocol> protocol, BOOL *stop) {
        if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
            OTRXMPPManager *xmpp = (OTRXMPPManager*)protocol;
            [xmpp goAway];
        }
    }];
}

-(BOOL)isAccountConnected:(OTRAccount *)account;
{
    BOOL connected = NO;
    id <OTRProtocol> protocol = nil;
    protocol = [self.protocolManagers objectForKey:account.uniqueId];
    OTRXMPPManager *xmpp = (OTRXMPPManager*)protocol;
    NSParameterAssert([xmpp isKindOfClass:OTRXMPPManager.class]);
    if (![xmpp isKindOfClass:OTRXMPPManager.class]) {
        DDLogError(@"Wrong protocol class %@", protocol);
        return NO;
    }
    if (xmpp) {
        connected = xmpp.loginStatus == OTRLoginStatusAuthenticated;
    }
    return connected;
}

- (void)sendMessage:(OTROutgoingMessage *)message {
    __block OTRAccount * account = nil;
    [OTRDatabaseManager.shared.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.buddyUniqueId transaction:transaction];
        account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
    } completionBlock:^{
        OTRProtocolManager * protocolManager = [OTRProtocolManager shared];
        id<OTRProtocol> protocol = [protocolManager protocolForAccount:account];
        [protocol sendMessage:message];
    }];
}

+ (void)handleInviteForJID:(XMPPJID *)jid otrFingerprint:(nullable NSString *)otrFingerprint buddyAddedCallback:(nullable void (^)(OTRBuddy *buddy))buddyAddedCallback {
    NSParameterAssert(jid);
    if (!jid) { return; }
    NSString *jidString = jid.bare;
    NSString *message = [NSString stringWithString:jidString];
    if (otrFingerprint.length == 40) {
        message = [message stringByAppendingFormat:@"\n%@", otrFingerprint];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ADD_BUDDY_STRING() message:message preferredStyle:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert];
    NSMutableArray<OTRAccount*> *accounts = [NSMutableArray array];
    [OTRDatabaseManager.shared.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray<OTRAccount*> *allAccounts = [OTRAccount allAccountsWithTransaction:transaction];
        [allAccounts enumerateObjectsUsingBlock:^(OTRAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.isArchived) {
                [accounts addObject:obj];
            }
        }];
    }];
    [accounts enumerateObjectsUsingBlock:^(OTRAccount *account, NSUInteger idx, BOOL *stop) {
        if ([account isKindOfClass:[OTRXMPPAccount class]]) {
            OTRXMPPAccount *xmppAccount = (OTRXMPPAccount*)account;
            if ([xmppAccount.bareJID isEqualToJID:jid options:XMPPJIDCompareBare]) {
                // Don't allow adding yourself to yourself
                return;
            }
            // Not the best way to do this, but only show "Add" if you have a single account, otherwise show the account name to add it to.
            NSString *title = nil;
            if (accounts.count == 1) {
                title = ADD_STRING();
            } else {
                title = account.username;
            }
            UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                OTRXMPPManager *manager = (OTRXMPPManager *)[[OTRProtocolManager shared] protocolForAccount:account];

                OTRXMPPBuddy *buddy = [manager addToRosterWithJID:jid displayName:nil];

                /* TODO OTR fingerprint verificaction
                 if (otrFingerprint) {
                 // We are missing a method to add fingerprint to trust store
                 [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString verified:YES completion:nil];
                 }*/
                if (buddyAddedCallback != nil) {
                    buddyAddedCallback(buddy);
                }
            }];
            [alert addAction:action];
        }
    }];
    if (alert.actions.count > 0) {
        // No need to show anything if only option is "cancel"
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:CANCEL_STRING() style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        // This is janky af
        [OTRAppDelegate.appDelegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark Singleton Object Methods

+ (OTRProtocolManager*) shared {
    return [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
