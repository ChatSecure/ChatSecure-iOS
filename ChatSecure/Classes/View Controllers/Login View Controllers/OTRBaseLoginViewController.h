//
//  OTRBaseLoginViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XLFormViewController.h"
#import "OTRLoginHandler.h"
@class OTRAccount;

@interface OTRBaseLoginViewController : XLFormViewController

@property (nonatomic, strong) UIBarButtonItem *loginCreateButtonItem;
@property (nonatomic) BOOL showsCancelButton;

@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) id<OTRBaseLoginViewControllerHandlerProtocol> createLoginHandler;

/** if completionBlock is set, you must dismiss VC manually */
@property (nonatomic, copy) void (^completionBlock)(OTRAccount *account, NSError *error);

/**
 Creates an OTRBaseLoginViewController with correct form and login handler
 
 @param An account to use to create the view
 @return A configured OTRBaseLoginViewController
 */
+ (instancetype)loginViewControllerForAccount:(OTRAccount *)account;

@end
