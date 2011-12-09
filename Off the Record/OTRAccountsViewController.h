//
//  OTRAccountsViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRLoginViewController.h"

@interface OTRAccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    UITableView *accountsTableView;
    OTRLoginViewController *loginController;
    UIBarButtonItem *aboutButton;
    
    BOOL isAIMloggedIn;
    BOOL isXMPPloggedIn;
}
@property (retain, nonatomic) IBOutlet UITableView *accountsTableView;

-(void)oscarLoggedInSuccessfully;
-(void)xmppLoggedInSuccessfully;
-(void)accountLoggedIn;
-(void)showAboutScreen;

@end
