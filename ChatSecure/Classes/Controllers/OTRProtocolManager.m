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
@import YapDatabase;

@import KVOController;
@import OTRAssets;
#import "OTRLog.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRXMPPPresenceSubscriptionRequest.h"

@interface OTRProtocolManager ()
@property (atomic, readwrite) NSUInteger numberOfConnectedProtocols;
@property (atomic, readwrite) NSUInteger numberOfConnectingProtocols;
@property (nonatomic, strong, readonly, nonnull) NSMutableDictionary<NSString*,id<OTRProtocol>> *protocolManagers;
@end

@implementation OTRProtocolManager
@synthesize lastInteractionDate = _lastInteractionDate;

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        _protocolManagers = [[NSMutableDictionary alloc] init];
        
        _numberOfConnectedProtocols = 0;
        _numberOfConnectingProtocols = 0;
        _encryptionManager = [[OTREncryptionManager alloc] init];
        
#if DEBUG
        NSURL *pushAPIEndpoint = [OTRBranding pushStagingAPIURL];
        if (!pushAPIEndpoint) {
            // This should only happen within test environment
            pushAPIEndpoint = [NSURL new];
        }
#else
        NSURL *pushAPIEndpoint = [OTRBranding pushAPIURL];
#endif
        
        // Casting here because it's easier than figuring out the
        // non-modular include spaghetti mess
        id<OTRPushTLVHandlerProtocol> tlvHandler = (id<OTRPushTLVHandlerProtocol>)self.encryptionManager.pushTLVHandler;
        if (pushAPIEndpoint != nil) {
            _pushController = [[PushController alloc] initWithBaseURL:pushAPIEndpoint sessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] databaseConnection:[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection tlvHandler:tlvHandler];
            self.encryptionManager.pushTLVHandler.delegate = self.pushController;
        }
    }
    return self;
}

- (void)removeProtocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account);
    if (!account) { return; }
    id<OTRProtocol> protocol = nil;
    @synchronized (self) {
        protocol =  [self.protocolManagers objectForKey:account.uniqueId];
    }
    if (protocol && [protocol respondsToSelector:@selector(disconnect)]) {
        [protocol disconnect];
    }
    [self.KVOController unobserve:protocol];
    @synchronized (self) {
        [self.protocolManagers removeObjectForKey:account.uniqueId];
    }
}

- (NSDate*) lastInteractionDate {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        return [NSDate date];
    }
    @synchronized (self) {
        return _lastInteractionDate;
    }
}

- (void)setLastInteractionDate:(NSDate *)lastInteractionDate {
    NSParameterAssert(lastInteractionDate != nil);
    if (!lastInteractionDate) { return; }
    @synchronized (self) {
        _lastInteractionDate = lastInteractionDate;
    }
}

- (void)addProtocol:(id<OTRProtocol>)protocol forAccount:(OTRAccount *)account
{
    @synchronized (self) {
        [self.protocolManagers setObject:protocol forKey:account.uniqueId];
    }
    [self.KVOController observe:protocol keyPath:NSStringFromSelector(@selector(connectionStatus)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld action:@selector(protocolDidChange:)];
}

- (BOOL)existsProtocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account.uniqueId);
    if (!account.uniqueId) { return NO; }
    @synchronized (self) {
        return [self.protocolManagers objectForKey:account.uniqueId] != nil;
    }
}

- (void)setProtocol:(id <OTRProtocol>)protocol forAccount:(OTRAccount *)account
{
    NSParameterAssert(protocol);
    NSParameterAssert(account.uniqueId);
    if (!protocol || !account.uniqueId) { return; }
    [self addProtocol:protocol forAccount:account];
}

- (id <OTRProtocol>)protocolForAccount:(OTRAccount *)account
{
    NSParameterAssert(account);
    if (!account.uniqueId) { return nil; }
    id <OTRProtocol> protocol = nil;
    @synchronized (self) {
         protocol = [self.protocolManagers objectForKey:account.uniqueId];
    }
    if(!protocol)
    {
        protocol = [[[account protocolClass] alloc] initWithAccount:account];
        if (protocol && account.uniqueId) {
            [self addProtocol:protocol forAccount:account];
        }
    }
    return protocol;
}

- (void)loginAccount:(OTRAccount *)account userInitiated:(BOOL)userInitiated
{
    NSParameterAssert(account);
    if (!account) { return; }
    id <OTRProtocol> protocol = [self protocolForAccount:account];
    if ([protocol connectionStatus] != OTRLoginStatusDisconnected) {
        //DDLogWarn(@"Account already connected %@", account);
    }
    
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
    @synchronized (self) {
        [self.protocolManagers enumerateKeysAndObjectsUsingBlock:^(id key, id <OTRProtocol> protocol, BOOL *stop) {
            if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
                OTRXMPPManager *xmpp = (OTRXMPPManager*)protocol;
                [xmpp goAway];
            }
        }];
    }
}

- (void)disconnectAllAccountsSocketOnly:(BOOL)socketOnly {
    @synchronized (self) {
        [self.protocolManagers enumerateKeysAndObjectsUsingBlock:^(id key, id <OTRProtocol> protocol, BOOL *stop) {
            [protocol disconnectSocketOnly:socketOnly];
        }];
    }
}

- (void)disconnectAllAccounts
{
    [self disconnectAllAccountsSocketOnly:NO];
}

- (void)protocolDidChange:(NSDictionary *)change
{
    __block NSUInteger connected = 0;
    __block NSUInteger connecting = 0;
    @synchronized (self) {
        [self.protocolManagers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<OTRProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj connectionStatus] == OTRProtocolConnectionStatusConnected) {
                connected++;
            } else if ([obj connectionStatus] == OTRProtocolConnectionStatusConnecting) {
                connecting++;
            }
        }];
    }
    self.numberOfConnectedProtocols = connected;
    self.numberOfConnectingProtocols = connecting;
}

-(BOOL)isAccountConnected:(OTRAccount *)account;
{
    BOOL connected = NO;
    id <OTRProtocol> protocol = nil;
    @synchronized (self) {
        protocol = [self.protocolManagers objectForKey:account.uniqueId];
    }
    if (protocol) {
        connected = [protocol connectionStatus] == OTRProtocolConnectionStatusConnected;
    }
    return connected;
}

- (void)sendMessage:(OTROutgoingMessage *)message {
    __block OTRAccount * account = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.buddyUniqueId transaction:transaction];
        account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
    } completionBlock:^{
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
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
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
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
                OTRXMPPManager *manager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
                
                __block OTRXMPPBuddy *buddy = nil;
                __block BOOL handled = NO;
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    buddy = [OTRXMPPBuddy fetchBuddyWithUsername:jidString withAccountUniqueId:account.uniqueId transaction:transaction];
                    if (!buddy) {
                        buddy = [[OTRXMPPBuddy alloc] init];
                        buddy.username = jidString;
                        buddy.accountUniqueId = account.uniqueId;
                    }
                    [buddy saveWithTransaction:transaction];
                    
                    // Check if we already have a subscription request from this user
                    OTRXMPPPresenceSubscriptionRequest *presenceRequest = [OTRXMPPPresenceSubscriptionRequest fetchPresenceSubscriptionRequestWithJID:jidString accontUniqueId:account.uniqueId transaction:transaction];
                    if (presenceRequest != nil) {
                        // We have an incoming subscription request, just answer that!
                        [manager.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
                        [presenceRequest removeWithTransaction:transaction];
                        handled = YES;
                    }
                }];
                if (!handled) {
                    [manager addBuddy:buddy];
                }
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
