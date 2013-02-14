//
//  OTRChatViewController.h
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
#import "OTRBuddyListViewController.h"
#import "OTRProtocolManager.h"
#import "OTRManagedBuddy.h"

@interface OTRChatViewController : UIViewController <UITextFieldDelegate,UIWebViewDelegate, UIActionSheetDelegate, UISplitViewControllerDelegate,UIAlertViewDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>
{
    NSMutableArray * _heightForRow;
    NSDate *_previousShownSentDate;
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    UIImage *_messageBubbleComposing;
}


@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton, *lockVerifiedButton;
@property (nonatomic, retain) UITextField *messageTextField;
@property (nonatomic, retain) UIButton *sendButton;
@property (nonatomic, retain) UIView *chatBoxView;
@property (nonatomic, retain) UILabel *instructionsLabel;
@property (nonatomic, strong) UILabel *chatStateLabel;
@property (nonatomic, strong) UIImageView * chatStateImage;

@property (nonatomic, strong) UITableView * chatHistoryTableView;
@property (nonatomic, strong) NSFetchedResultsController *messagesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *buddyFetchedResultsController;

@property (nonatomic, retain) OTRManagedBuddy *buddy;

@property (nonatomic, retain) OTRBuddyListViewController *buddyListController;

@property (nonatomic, retain) NSURL *lastActionLink;

@property (nonatomic, strong) NSTimer * pausedChatStateTimer;
@property (nonatomic, strong) NSTimer * inactiveChatStateTimer;


- (void)sendButtonPressed:(id)sender;
- (void)scrollTextViewToBottom;

- (void)updateChatHistory;
- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;
- (void)updateChatState:(BOOL)animated;

@end
