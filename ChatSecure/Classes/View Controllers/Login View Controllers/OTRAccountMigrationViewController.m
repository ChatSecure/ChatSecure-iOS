//
//  OTRAccountMigrationViewController.m
//  ChatSecure
//
//  Created by Chris Ballinger on 4/20/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRAccountMigrationViewController.h"
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRXMPPManager.h"
#import "OTRStrings.h"
#import "OTRDatabaseManager.h"
#import "OTRYapMessageSendAction.h"
#import "OTRLog.h"
#import "OTRXMPPManager_Private.h"

NSString *const kSpamYourContactsTag = @"kSpamYourContactsTag";

typedef NS_ENUM(NSInteger, MigrationStatus) {
    MigrationStatusUnknown = 0,
    MigrationStatusFailed,
    MigrationStatusCreating,
    MigrationStatusMigrating,
    MigrationStatusComplete
};

@interface OTRAccountMigrationViewController ()
/** Whether or not the account is migrated within handleSuccessWithNewAccount:. This is to maybe fix a bug where the contacts are re-added multiple times. */
@property (nonatomic) MigrationStatus migrationStatus;
@end

@implementation OTRAccountMigrationViewController

- (instancetype) initWithOldAccount:(OTRXMPPAccount*)oldAccount {
    NSParameterAssert(oldAccount);
    if (self = [super initWithNewAccountType:oldAccount.accountType]) {
        _migrationStatus = MigrationStatusUnknown;
        _oldAccount = oldAccount;
        XLFormRowDescriptor *spamRow = [XLFormRowDescriptor formRowDescriptorWithTag:kSpamYourContactsTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:MESSAGE_FRIENDS_WITH_NEW_INFO_STRING()];
        spamRow.value = @YES;
        XLFormRowDescriptor *nicknameRow = [self.form formRowWithTag:kOTRXLFormNicknameTextFieldTag];
        NSParameterAssert(nicknameRow != nil);
        if (nicknameRow) {
            nicknameRow.value = oldAccount.displayName;
            [self.form addFormRow:spamRow afterRow:nicknameRow];
            nicknameRow.sectionDescriptor.footerTitle = MIGRATION_FORM_DETAIL_STRING();
        }
        // Don't let people migrate Tor accounts to non-Tor accounts
        if (oldAccount.accountType == OTRAccountTypeXMPPTor) {
            XLFormRowDescriptor *torRow = [self.form formRowWithTag:kOTRXLFormUseTorTag];
            torRow.value = @YES;
            torRow.disabled = @YES;
        }
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = MIGRATE_ACCOUNT_STRING();
}

#pragma mark - Superclass Overrides

- (void)handleError:(NSError *)error {
    self.migrationStatus = MigrationStatusFailed;
    [super handleError:error];
}

- (void)loginButtonPressed:(id)sender {
    // If account isn't logged in, login so we can spam old contacts & update your old vCard.jid with new details
    BOOL isConnected = [[OTRProtocolManager sharedInstance] isAccountConnected:self.oldAccount];
    if (!isConnected) {
        // TODO: Fix Tor connection issues
        [[OTRProtocolManager sharedInstance] loginAccount:self.oldAccount];
    }
    self.migrationStatus = MigrationStatusCreating;
    [super loginButtonPressed:sender];
}

- (void) handleSuccessWithNewAccount:(OTRXMPPAccount*)newAccount sender:(id)sender {
    if (self.migrationStatus != MigrationStatusCreating) {
        [super handleSuccessWithNewAccount:newAccount sender:sender];
        return;
    }
    self.migrationStatus = MigrationStatusMigrating;
    [OTRDatabaseManager.shared.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [newAccount saveWithTransaction:transaction];
    }];
    // This is where we do the migration before passing off to the superclass
    
    OTRXMPPManager *oldXmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:self.oldAccount];
    OTRXMPPManager *newXmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:newAccount];
    
    NSParameterAssert(oldXmpp);
    NSParameterAssert(newXmpp);
    
    BOOL shouldSpamFriends = [[self.form formRowWithTag:kSpamYourContactsTag].value isEqual:@YES];
    
    // Step 1 - Add old contacts to new account
    
    NSString *messageText = [NSString stringWithFormat:@"%@: %@", MY_NEW_ACCOUNT_INFO_STRING(), newAccount.bareJID.bare];
    NSMutableArray<OTROutgoingMessage*> *outgoingMessages = [NSMutableArray array];
    __block NSArray<OTRXMPPBuddy*> *buddies = @[];
    __block NSMutableArray<OTRBuddy*> *newBuddies = [NSMutableArray array];
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddies = [self.oldAccount allBuddiesWithTransaction:transaction];
        newBuddies = [NSMutableArray arrayWithCapacity:buddies.count];
        [buddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // Don't add yourself to your new roster
            if ([obj.bareJID isEqualToJID:self.oldAccount.bareJID options:XMPPJIDCompareBare]) {
                return;
            }
            OTRXMPPBuddy *newBuddy = [[OTRXMPPBuddy alloc] init];
            newBuddy.username = obj.username;
            newBuddy.accountUniqueId = newAccount.uniqueId;
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
            if (shouldSpamFriends) {
                OTROutgoingMessage *message = [OTROutgoingMessage messageToBuddy:obj text:messageText transaction:transaction];
                [outgoingMessages addObject:message];
            }
        }];
    }];
    
    
    [OTRDatabaseManager.shared.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [newBuddies enumerateObjectsUsingBlock:^(OTRBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj saveWithTransaction:transaction];
        }];
    }];
    [newXmpp addBuddies:newBuddies];
    
    // Step 2 - Message old contacts that you have new account
    
    if (shouldSpamFriends) {
        [oldXmpp enqueueMessages:outgoingMessages];
    }
    
    // Step 3 - Copy your avatar from old account to new account
    
    [newXmpp setAvatar:self.oldAccount.avatarImage completion:^(BOOL success) {
        DDLogVerbose(@"Avatar copied to new account: success=%d", success);
    }];
    
    // Step 4 - Update your old account's vCard with new JID
    
    XMPPvCardTemp *vCard = self.oldAccount.vCardTemp;
    vCard.jid = newAccount.bareJID;
    self.oldAccount.waitingForvCardTempFetch = NO;
    self.oldAccount.lastUpdatedvCardTemp = [NSDate date];
    [OTRDatabaseManager.shared.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [self.oldAccount saveWithTransaction:transaction];
    }];
    [oldXmpp.xmppvCardTempModule updateMyvCardTemp:vCard];
    
    // Step 5 - Update your old account's vCard.image to force other client's to refresh your whole vCard
    
    [oldXmpp setAvatar:self.oldAccount.avatarImage completion:^(BOOL success) {
        DDLogVerbose(@"Avatar copied to on account to force vCard update: success=%d", success);
    }];
    
    // Step 6 - Mark your old conversations as 'archived'
    
    [OTRDatabaseManager.shared.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [buddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj = [obj copy];
            obj.isArchived = YES;
            [obj saveWithTransaction:transaction];
        }];
    }];
    self.migrationStatus = MigrationStatusComplete;
    [super handleSuccessWithNewAccount:newAccount sender:sender];
}



@end
