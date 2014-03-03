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
#import "OTRChatInputBar.h"
#import "OTRTitleSubtitleView.h"

@interface OTRChatViewController : UIViewController <UIActionSheetDelegate, UISplitViewControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,OTRChatInputBarDelegate>
{
    NSMutableArray * showDateForRowArray;
    NSDate *_previousShownSentDate;
    UIImage *_messageBubbleComposing;
    CGFloat _previousTextViewContentHeight;
    OTRChatInputBar * chatInputBar;
    OTRTitleSubtitleView * titleView;
}


@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton, *lockVerifiedButton;
@property (nonatomic, retain) UILabel *instructionsLabel;

@property (nonatomic, strong) UITableView * chatHistoryTableView;
@property (nonatomic, strong) NSFetchedResultsController *messagesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *buddyFetchedResultsController;

@property (nonatomic, retain) OTRManagedBuddy *buddy;

@property (nonatomic, retain) OTRBuddyListViewController *buddyListController;

@property (nonatomic, retain) NSURL *lastActionLink;

@property (nonatomic) BOOL isComposingVisible;

@property (nonatomic, retain) UISwipeGestureRecognizer * swipeGestureRecognizer;

- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;

@end
