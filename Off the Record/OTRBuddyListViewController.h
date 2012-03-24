//
//  OTRBuddyListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRProtocolManager.h"

@class OTRChatViewController;

@interface OTRBuddyListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    NSArray *sortedBuddies;
}

@property (nonatomic, retain) IBOutlet UITableView *buddyListTableView;
@property (nonatomic, retain) OTRChatViewController *chatViewController;
@property (nonatomic, retain) UIViewController *chatListController;
@property (nonatomic, retain) UITabBarController *tabController;

@property (nonatomic, retain) OTRProtocolManager *protocolManager;
@property (nonatomic, retain) NSMutableDictionary *recentMessages;

-(void)startConversation:(NSString*)buddyName withProtocol:(NSString*)protocol withMessage:(NSString*)message;
-(void)enterConversation:(NSString*)buddyName withProtocol:(NSString*)protocol withMessage:(NSString*)message;
-(void)buddyListUpdate;
-(void)messageReceived:(NSNotification*)notification;

@end
