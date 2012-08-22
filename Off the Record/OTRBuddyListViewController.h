//
//  OTRBuddyListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>
#import "OTRProtocolManager.h"

@class OTRChatViewController;

@interface OTRBuddyListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) NSArray *sortedBuddies;
@property (nonatomic, retain) NSMutableDictionary *buddyDictionary;
@property (nonatomic, retain) NSMutableArray *activeConversations;
@property (nonatomic, retain) UITableView *buddyListTableView;
@property (nonatomic, retain) OTRChatViewController *chatViewController;
@property (nonatomic, retain) OTRBuddy *selectedBuddy;

@property (nonatomic, retain) OTRProtocolManager *protocolManager;

-(void)enterConversationWithBuddy:(OTRBuddy*)buddy;
-(void)buddyListUpdate;
-(void)messageReceived:(NSNotification*)notification;

@end
