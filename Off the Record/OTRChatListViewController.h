//
//  OTRChatListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRBuddyListViewController.h"

@interface OTRChatListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, retain) OTRBuddyListViewController *buddyController;
@property (retain, nonatomic) UITableView *chatListTableView;
@property (nonatomic, retain) NSMutableArray *activeConversations;

@end
