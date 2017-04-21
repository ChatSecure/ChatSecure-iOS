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

NSString *const kSpamYourContactsTag = @"kSpamYourContactsTag";

@implementation OTRAccountMigrationViewController

- (instancetype) initWithOldAccount:(OTRAccount*)oldAccount {
    NSParameterAssert(oldAccount);
    if (self = [super initWithNewAccountType:oldAccount.accountType]) {
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
        
    }
    return self;
}

// Override superclass
- (void)loginButtonPressed:(id)sender {
//    OTRXMPPManager *oldXmpp = [[OTRProtocolManager sharedInstance] protocolForAccount:self.oldAccount];
//    OTRXMPPManager *oldXmpp = [[OTRProtocolManager sharedInstance] protocolForAccount:self.oldAccount];
//    if (oldXmpp && []) {
//        
//    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = MIGRATE_ACCOUNT_STRING();
}

@end
