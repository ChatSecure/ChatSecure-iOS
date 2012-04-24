//
//  OTRAccountsViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRLoginViewController.h"

@interface OTRAccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    UITableView *accountsTableView;
    OTRLoginViewController *loginController;
    
    BOOL isAIMloggedIn;
    BOOL isXMPPloggedIn;
}
@property (retain, nonatomic) UITableView *accountsTableView;
@property (nonatomic, retain) UIImageView *logoView;

-(void)oscarLoggedInSuccessfully;
-(void)xmppLoggedInSuccessfully;
-(void)accountLoggedIn;
-(void)aimLoggedOff;
-(void)xmppLoggedOff;

@end
