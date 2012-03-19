//
//  OTRChatViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRBuddyListViewController.h"
#import "DTAttributedTextView.h"
#import "context.h"
#import "OTRProtocolManager.h"

@interface OTRChatViewController : UIViewController <UITextFieldDelegate,DTAttributedTextContentViewDelegate, UIActionSheetDelegate> 

@property (nonatomic) ConnContext *context;
@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton;

@property (nonatomic, retain) OTRProtocolManager *protocolManager;

@property (nonatomic, retain) DTAttributedTextView *chatHistoryTextView;
@property (nonatomic, retain) UITextField *messageTextField;
@property (nonatomic, retain) UIButton *sendButton;

@property (nonatomic, retain) OTRBuddyListViewController *buddyListController;


@property (nonatomic, retain) UIView *chatBoxView;

@property (nonatomic, retain) NSMutableString *rawChatHistory;
@property (nonatomic, retain) NSString *protocol;
@property (nonatomic, retain) NSString *accountName;
@property (nonatomic, retain) NSURL *lastActionLink;
@property (nonatomic) BOOL keyboardIsShown;


- (void)sendButtonPressed:(id)sender;
- (void)receiveMessage:(NSString*)message;
- (void)sendMessage:(NSString*)message;
- (void)scrollTextViewToBottom;

- (void)updateChatHistory;
- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;

@end
