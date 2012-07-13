//
//  OTRAccountsViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRLoginViewController.h"

@interface OTRAccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) OTRLoginViewController *loginController;
@property (nonatomic, retain) UITableView *accountsTableView;
@property (nonatomic, retain) UIImageView *logoView;

-(void)protocolLoggedInSuccessfully:(NSNotification *)notification;
-(void)protocolLoggedOff:(NSNotification *)notification;
-(void)accountLoggedIn;

@end
