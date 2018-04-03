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
#import "OTRAccountMigrator.h"

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
@property (nonatomic, strong, nullable) OTRAccountMigrator *migrator;
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
    BOOL shouldSpamFriends = [[self.form formRowWithTag:kSpamYourContactsTag].value isEqual:@YES];
    self.migrator = [[OTRAccountMigrator alloc] initWithOldAccount:self.oldAccount migratedAccount:newAccount shouldSpamFriends:shouldSpamFriends];
    __weak typeof(self)weakSelf = self;
    [self.migrator migrateWithCompletion:^(BOOL success, NSError * _Nullable error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf onMigrationComplete:success];
        [super handleSuccessWithNewAccount:newAccount sender:sender];
    }];
}

-(void) onMigrationComplete:(BOOL)success {
    if (success) {
        self.migrationStatus = MigrationStatusComplete;
    } else {
        self.migrationStatus = MigrationStatusFailed;
    }
}


@end
