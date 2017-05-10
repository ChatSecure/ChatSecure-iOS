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

@interface OTRAccountMigrationViewController : OTRBaseLoginViewController

@property (nonatomic, strong, readonly) OTRXMPPAccount *oldAccount;

/**
 * This creates an account registration view prepopulated with
 * your old account nickname. Once registration is complete
 * the existing contacts from oldAccount will be migrated to the new account.
 */
- (instancetype) initWithOldAccount:(OTRXMPPAccount*)oldAccount;

/**
 * Called when migration is complete, overridable by subclasses. The success flag
 * indicates whether the operation completed successfully or not. If you override this,
 * make sure to call the superclass implementation.
 */
-(void) onMigrationComplete:(BOOL)success;

@end
NS_ASSUME_NONNULL_END
