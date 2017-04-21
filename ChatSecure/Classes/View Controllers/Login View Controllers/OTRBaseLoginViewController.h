//
//  OTRBaseLoginViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import XLForm;
#import "OTRLoginHandler.h"
#import "OTRAccount.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRBaseLoginViewController : XLFormViewController

@property (nonatomic, strong, nullable) OTRAccount *account;
@property (nonatomic, strong) id<OTRBaseLoginViewControllerHandlerProtocol> loginHandler;

@property (nonatomic) BOOL showsCancelButton;
/** If true, do not allow editing of the form */
@property (nonatomic) BOOL readOnly;


/** Attempts to login with existing account or create/register account via form values. */
- (void)loginButtonPressed:(id)sender;

/**
 * Creates a view for logging in with an existing local & remote account.
 *
 * @param An account to use to create the view
 * @return A configured OTRBaseLoginViewController
 */
- (instancetype) initWithAccount:(OTRAccount*)account;

/**
 * Creates a view for logging in with an existing remote account.
 */
- (instancetype) initWithExistingAccountType:(OTRAccountType)accountType;

/** This is for registering new accounts on a server */
- (instancetype) initWithNewAccountType:(OTRAccountType)accountType;

@end
NS_ASSUME_NONNULL_END
