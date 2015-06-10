//
//  OTRBaseLoginViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XLFormViewController.h"
@class OTRAccount;

@protocol OTRBaseLoginViewControllerHandlerProtocol <NSObject>

@required
- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(NSError *error, OTRAccount *account))completion;
- (void)moveAccountValues:(OTRAccount *)account intoForm:(XLFormDescriptor *)form;

@end

@interface OTRBaseLoginViewController : XLFormViewController

@property (nonatomic, strong) UIBarButtonItem *loginCreateButtonItem;

@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) id<OTRBaseLoginViewControllerHandlerProtocol> createLoginHandler;

@property (nonatomic, copy) void (^successBlock)(void);

@end
