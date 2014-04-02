//
//  OTRNewBuddyViewController.h
//  Off the Record
//
//  Created by David on 3/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OTRAccount;

@interface OTRNewBuddyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong)OTRAccount * account;
@property (nonatomic, strong)UITextField * accountNameTextField;
@property (nonatomic, strong)UITextField * displayNameTextField;


-(id)initWithAccountId:(NSString *)accountId;

@end
