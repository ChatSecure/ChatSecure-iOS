//
//  OTRChooseAccountViewController.h
//  Off the Record
//
//  Created by David on 3/7/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;

@class OTRAccount;

@interface OTRChooseAccountViewController : UIViewController

@property (nonatomic, copy, nullable) void (^selectionBlock)(OTRChooseAccountViewController * _Nonnull chooseVC, OTRAccount * _Nonnull account);

@end
