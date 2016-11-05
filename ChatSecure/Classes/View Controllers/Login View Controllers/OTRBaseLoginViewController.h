//
//  OTRBaseLoginViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import XLForm;
#import "OTRLoginHandler.h"
@class OTRAccount;

@interface OTRBaseLoginViewController : XLFormViewController

@property (nonatomic) BOOL showsCancelButton;

@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) id<OTRBaseLoginViewControllerHandlerProtocol> loginHandler;

@property (nonatomic) BOOL readOnly;

/**
 Creates an OTRBaseLoginViewController with correct form and login handler
 
 @param An account to use to create the view
 @return A configured OTRBaseLoginViewController
 */
+ (instancetype)loginViewControllerForAccount:(OTRAccount *)account;

@end
