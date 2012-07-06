//
//  OTRChatViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRBuddyListViewController.h"
#import "context.h"
#import "OTRProtocolManager.h"
#import "OTRBuddy.h"
#import "OTRUIKeyboardListener.h"

@interface OTRChatViewController : UIViewController <UITextFieldDelegate,UIWebViewDelegate, UIActionSheetDelegate, UISplitViewControllerDelegate> 


@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton;
@property (nonatomic, retain) UITextField *messageTextField;
@property (nonatomic, retain) UIButton *sendButton;
@property (nonatomic, retain) UIView *chatBoxView;
@property (nonatomic, retain) UILabel *instructionsLabel;

@property (nonatomic) ConnContext *context;
@property (nonatomic, retain) OTRBuddy *buddy;

//@property (nonatomic, retain) DTAttributedTextView *chatHistoryTextView;
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

@end
