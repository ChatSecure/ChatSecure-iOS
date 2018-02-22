//
//  OTRAccountMigrator.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRAccountMigrator.h"
#import "OTRDatabaseManager.h"
#import "OTRProtocolManager.h"
#import "OTRXMPPManager.h"
#import "OTRLog.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPManager_Private.h"
#import "NSURL+ChatSecure.h"
@import KVOController;

@import OTRAssets;

@interface OTRAccountMigrator ()
@property (nonatomic) BOOL isMigrationInProgress;
@property (nonatomic, copy, nullable) void (^completion)(BOOL success, NSError * _Nullable error);
@end

@implementation OTRAccountMigrator

- (instancetype) initWithOldAccount:(OTRXMPPAccount*)oldAccount
                         migratedAccount:(OTRXMPPAccount*)migratedAccount
                  shouldSpamFriends:(BOOL)shouldSpamFriends {
    NSParameterAssert(oldAccount != nil);
    NSParameterAssert(migratedAccount != nil);
    if (self = [super init]) {
        _oldAccount = oldAccount;
        _migratedAccount = migratedAccount;
        _shouldSpamFriends = shouldSpamFriends;
    }
    return self;
}

- (BOOL) areBothAccountsAreOnline {
    BOOL areConnected = [OTRProtocolManager.shared isAccountConnected:self.oldAccount] && [OTRProtocolManager.shared isAccountConnected:self.migratedAccount];
    return areConnected;
}

- (void) loginAccountsIfNeeded {
    if ([self areBothAccountsAreOnline]) {
        return;
    }
    [@[self.oldAccount, self.migratedAccount] enumerateObjectsUsingBlock:^(OTRXMPPAccount *  _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([OTRProtocolManager.shared isAccountConnected:self.oldAccount]) {
            return;
        }
        OTRXMPPManager *xmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
        [self.KVOController observe:xmpp keyPath:NSStringFromSelector(@selector(loginStatus)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld action:@selector(connectionStatusDidChange:)];
        [OTRProtocolManager.shared loginAccount:self.oldAccount];
    }];
}

- (void)connectionStatusDidChange:(NSDictionary *)change {
    if ([self areBothAccountsAreOnline]) {
        [self migrateOnlineAccountsWithCompletion:self.completion];
    }
}

- (void) migrateWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    if (self.isMigrationInProgress) {
        DDLogWarn(@"Migration already started");
        completion(NO, [NSError errorWithDomain:@"org.chatsecure.ChatSecure" code:MigratorErrorInProgress userInfo:@{NSLocalizedDescriptionKey: @"Migration in progress"}]);
        return;
    }
    self.isMigrationInProgress = YES;
    self.completion = completion;
    NSParameterAssert(completion != nil);
    [OTRDatabaseManager.shared.writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self.migratedAccount saveWithTransaction:transaction];
    }];
    if ([self areBothAccountsAreOnline]) {
        [self migrateOnlineAccountsWithCompletion:completion];
        return;
    }
    [self loginAccountsIfNeeded];
}


- (void) migrateOnlineAccountsWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    NSParameterAssert(completion != nil);
    NSParameterAssert([self areBothAccountsAreOnline]);

    // This is where we do the migration before passing off to the superclass
    
    OTRXMPPManager *oldXmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:self.oldAccount];
    OTRXMPPManager *newXmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:self.migratedAccount];
    
    NSParameterAssert(oldXmpp);
    NSParameterAssert(newXmpp);
    
    
    // Step 1 - Add old contacts to new account
    
    // This is a special hint in the URL to indicate that we're migrating
    // TODO: include OTR/OMEMO fingerprints
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:@"m" value:@"1"];
    NSURL *shareLink = [NSURL otr_shareLink:NSURL.otr_shareBaseURL jid:self.migratedAccount.bareJID queryItems:@[item]];
    
    NSString *messageText = [NSString stringWithFormat:@"%@: %@", MY_NEW_ACCOUNT_INFO_STRING(), (shareLink != nil) ? shareLink : self.migratedAccount.bareJID.bare];
    NSMutableArray<id<OTRMessageProtocol>> *outgoingMessages = [NSMutableArray array];
    __block NSArray<OTRXMPPBuddy*> *buddies = @[];
    __block NSMutableArray<OTRBuddy*> *newBuddies = [NSMutableArray array];
    [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddies = [self.oldAccount allBuddiesWithTransaction:transaction];
        newBuddies = [NSMutableArray arrayWithCapacity:buddies.count];
        [buddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // Don't add yourself to your new roster
            if ([obj.bareJID isEqualToJID:self.oldAccount.bareJID options:XMPPJIDCompareBare]) {
                return;
            }
            OTRXMPPBuddy *newBuddy = [[OTRXMPPBuddy alloc] init];
            newBuddy.username = obj.username;
            newBuddy.accountUniqueId = self.migratedAccount.uniqueId;
            // Show buddies in list only if you've talked to them before
            if (obj.lastMessageId.length > 0 && !obj.isArchived) {
                newBuddy.lastMessageId = @"";
            }
            newBuddy.isArchived = obj.isArchived;
            newBuddy.avatarData = obj.avatarData;
            newBuddy.displayName = obj.displayName;
            newBuddy.preferredSecurity = obj.preferredSecurity;
            [newBuddies addObject:newBuddy];
            
            // If spamming friends, create some messages for them
            if (self.shouldSpamFriends) {
                id<OTRMessageProtocol> message = [obj outgoingMessageWithText:messageText transaction:transaction];
                [outgoingMessages addObject:message];
            }
        }];
    }];
    
    
    [OTRDatabaseManager.shared.writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [newBuddies enumerateObjectsUsingBlock:^(OTRBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj saveWithTransaction:transaction];
        }];
    }];
    [newXmpp addBuddies:newBuddies];
    
    // Step 2 - Message old contacts that you have new account
    
    if (self.shouldSpamFriends) {
        [oldXmpp enqueueMessages:outgoingMessages];
    }
    
    // Step 3 - Copy your avatar from old account to new account
    
    [newXmpp setAvatar:self.oldAccount.avatarImage completion:^(BOOL success) {
        DDLogVerbose(@"Avatar copied to new account: success=%d", success);
    }];
    
    // Step 4 - Update your old account's vCard with new JID
    
    XMPPvCardTemp *vCard = self.oldAccount.vCardTemp;
    vCard.jid = self.migratedAccount.bareJID;
    self.oldAccount.waitingForvCardTempFetch = NO;
    self.oldAccount.lastUpdatedvCardTemp = [NSDate date];
    [OTRDatabaseManager.shared.writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [self.oldAccount saveWithTransaction:transaction];
    }];
    [oldXmpp.xmppvCardTempModule updateMyvCardTemp:vCard];
    
    // Step 5 - Update your old account's vCard.image to force other client's to refresh your whole vCard
    
    [oldXmpp setAvatar:self.oldAccount.avatarImage completion:^(BOOL success) {
        DDLogVerbose(@"Avatar copied to on account to force vCard update: success=%d", success);
    }];
    
    // Step 6 - Mark your old conversations as 'archived'
    
    [OTRDatabaseManager.shared.writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [buddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj = [obj copy];
            obj.isArchived = YES;
            [obj saveWithTransaction:transaction];
        }];
    }];
    completion(YES, nil);
    self.completion = nil;
    self.isMigrationInProgress = NO;
    [self.KVOController unobserve:oldXmpp];
    [self.KVOController unobserve:newXmpp];
}

@end
