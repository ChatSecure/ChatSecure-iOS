//
//  OTRBuddyListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRProtocolManager.h"

@interface OTRBuddyListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    
    
    UITableView *buddyListTableView;
    
    
    NSMutableDictionary *chatViewControllers;
    
    UIViewController *loginController;
    
    OTRProtocolManager *protocolManager;
    
    AIMBlist *buddyList;
}

@property (nonatomic, retain) IBOutlet UITableView *buddyListTableView;
@property (nonatomic, retain) NSMutableDictionary *chatViewControllers;
@property (nonatomic, retain) UIViewController *chatListController;
@property (nonatomic, retain) UITabBarController *tabController;

@property (nonatomic, retain)     OTRProtocolManager *protocolManager;

-(void)enterConversation:(NSString*)buddyName;
-(void)loggedInSuccessfully;
-(void)buddyListUpdate;
-(void)messageReceived:(NSNotification*)notification;

@end
