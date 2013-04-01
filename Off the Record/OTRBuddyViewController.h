//
//  OTRBuddyViewController.h
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRManagedBuddy.h"
#import "TTTAttributedLabel.h"

@interface OTRBuddyViewController : UIViewController <TTTAttributedLabelDelegate, UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate>
{
    UITextField * displayNameTextField;
    UIButton * removeBuddyButton;
    UIButton * blockBuddyButton;
    BOOL isXMPPAccount;
}

@property (nonatomic, strong) OTRManagedBuddy * buddy;


-(id)initWithBuddyID:(NSManagedObjectID *)buddyID;

@end
