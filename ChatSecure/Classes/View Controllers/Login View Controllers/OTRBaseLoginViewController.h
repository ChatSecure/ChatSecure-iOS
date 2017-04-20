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

@property (nonatomic) BOOL showsCancelButton;

@property (nonatomic, strong, nullable) OTRAccount *account;

@property (nonatomic, strong) id<OTRBaseLoginViewControllerHandlerProtocol> loginHandler;

@property (nonatomic) BOOL readOnly;

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
- (instancetype) initWithAccountType:(OTRAccountType)accountType;

@end
NS_ASSUME_NONNULL_END
