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
#import "OTRBuddy.h"
#import "OTRUIKeyboardListener.h"

@interface OTRChatViewController : UIViewController <UITextFieldDelegate,UIWebViewDelegate, UIActionSheetDelegate, UISplitViewControllerDelegate> 


@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton;
@property (nonatomic, retain) UITextField *messageTextField;
@property (nonatomic, retain) UIButton *sendButton;
@property (nonatomic, retain) UIView *chatBoxView;
@property (nonatomic, retain) UILabel *instructionsLabel;
@property (nonatomic, strong) UILabel *chatStateLabel;
@property (nonatomic, strong) UIImageView * chatStateImage;

@property (nonatomic, retain) OTRBuddy *buddy;

@property (nonatomic, retain) UIWebView *chatHistoryTextView;
@property (nonatomic, retain) OTRBuddyListViewController *buddyListController;

@property (nonatomic, retain) NSURL *lastActionLink;
@property (nonatomic) BOOL keyboardIsShown;

@property (nonatomic, strong) OTRUIKeyboardListener * keyboardListener;




- (void)sendButtonPressed:(id)sender;
- (void)scrollTextViewToBottom;

- (void)updateChatHistory;
- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;
- (void)updateChatState:(BOOL)animated;

@end
