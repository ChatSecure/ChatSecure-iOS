//
//  OTRNewBuddyViewController.h
//  Off the Record
//
//  Created by David on 3/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OTRManagedAccount;

@interface OTRNewBuddyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    BOOL isXMPPaccount;
}

@property (nonatomic, strong)OTRManagedAccount * account;
@property (nonatomic, strong)UITextField * accountNameTextField;
@property (nonatomic, strong)UITextField * displayNameTextField;


-(id)initWithAccountObjectID:(NSManagedObjectID *)accountObjectID;

@end
