//
//  OTRInviteViewController.h
//  ChatSecure
//
//  Created by David Chiles on 7/8/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

@class OTRAccount;
@class BButton;

NS_ASSUME_NONNULL_BEGIN
@interface OTRInviteViewController : UIViewController

@property (nonatomic, strong, readonly) OTRAccount *account;

- (instancetype) initWithAccount:(OTRAccount*)account NS_DESIGNATED_INITIALIZER;

@end
NS_ASSUME_NONNULL_END
