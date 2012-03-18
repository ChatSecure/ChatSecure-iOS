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

@interface OTRChatViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate,DTAttributedTextContentViewDelegate, UIActionSheetDelegate> 

@property (nonatomic) ConnContext *context;
@property (nonatomic, retain) UIBarButtonItem *lockButton, *unlockedButton;

@property (nonatomic, retain) OTRProtocolManager *protocolManager;

@property (retain, nonatomic) DTAttributedTextView *chatHistoryTextView;
@property (retain, nonatomic) UITextField *messageTextField;
@property (retain, nonatomic) UITextView *chatBox;

@property (retain, nonatomic) OTRBuddyListViewController *buddyListController;


@property (nonatomic, retain) UIView *viewChatHistory;
@property (nonatomic, retain) UIView *viewChatBox;

@property (nonatomic, retain) NSMutableString *rawChatHistory;
@property (nonatomic, retain) NSString *protocol;
@property (nonatomic, retain) NSString *accountName;
@property (nonatomic, retain) NSURL *lastActionLink;


- (void)sendButtonPressed:(id)sender;
- (void)receiveMessage:(NSString*)message;
- (void)sendMessage:(NSString*)message;
- (void)scrollTextViewToBottom;

- (void)updateChatHistory;
- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;

@end
