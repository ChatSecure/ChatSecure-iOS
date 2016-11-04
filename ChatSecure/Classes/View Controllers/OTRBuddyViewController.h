//
//  OTRBuddyViewController.h
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;
@import TTTAttributedLabel;

@class OTRBuddy;

@interface OTRBuddyViewController : UIViewController <TTTAttributedLabelDelegate, UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate>
{
    UITextField * displayNameTextField;
    UIButton * removeBuddyButton;
    UIButton * blockBuddyButton;
    BOOL isXMPPAccount;
}

@property (nonatomic, strong) OTRBuddy *buddy;


-(id)initWithBuddyID:(NSString *)buddyID;

@end
