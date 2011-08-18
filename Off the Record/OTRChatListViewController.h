//
//  OTRChatListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRBuddyListViewController.h"

@interface OTRChatListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *chatListTableView;
}


@property (nonatomic, retain) OTRBuddyListViewController *buddyController;
@property (retain, nonatomic) IBOutlet UITableView *chatListTableView;

@end
