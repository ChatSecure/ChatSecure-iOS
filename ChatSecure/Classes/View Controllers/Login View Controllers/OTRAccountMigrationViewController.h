//
//  OTRAccountMigrationViewController.h
//  ChatSecure
//
//  Created by Chris Ballinger on 4/20/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRBaseLoginViewController.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRAccountMigrationViewController : OTRBaseLoginViewController

@property (nonatomic, strong, readonly) OTRAccount *oldAccount;

/**
 * This creates an account registration view prepopulated with
 * your old account nickname. Once registration is complete
 * the existing contacts from oldAccount will be migrated to the new account.
 */
- (instancetype) initWithOldAccount:(OTRAccount*)oldAccount;

@end
NS_ASSUME_NONNULL_END
