//
//  OTRAccountMigrationViewController.h
//  ChatSecure
//
//  Created by Chris Ballinger on 4/20/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRBaseLoginViewController.h"
#import "OTRXMPPAccount.h"

NS_ASSUME_NONNULL_BEGIN
/** Show form row to spam your old contacts w/ new acct info */
FOUNDATION_EXPORT NSString *const kSpamYourContactsTag;

typedef NS_ENUM(NSInteger, MigrationStatus) {
    MigrationStatusUnknown = 0,
    MigrationStatusFailed,
    MigrationStatusCreating,
    MigrationStatusMigrating,
    MigrationStatusComplete
};

@interface OTRAccountMigrationViewController : OTRBaseLoginViewController

@property (nonatomic, strong, readonly) OTRXMPPAccount *oldAccount;

/** Whether or not the account is migrated within handleSuccessWithNewAccount:. This is to maybe fix a bug where the contacts are re-added multiple times. */
@property (nonatomic) MigrationStatus migrationStatus;

/**
 * This creates an account registration view prepopulated with
 * your old account nickname. Once registration is complete
 * the existing contacts from oldAccount will be migrated to the new account.
 */
- (instancetype) initWithOldAccount:(OTRXMPPAccount*)oldAccount;

@end
NS_ASSUME_NONNULL_END
