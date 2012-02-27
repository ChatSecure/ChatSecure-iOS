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



@interface OTRChatViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate,DTAttributedTextContentViewDelegate, UIActionSheetDelegate> {
    DTAttributedTextView *chatHistoryTextView;
    UITextField *messageTextField;
    UITextView *chatBox;
    OTRBuddyListViewController *buddyListController;
    IBOutlet UIView *viewChatHistory;
    IBOutlet UIView *viewChatBox;
    
    NSURL *lastActionLink;
    NSMutableString *rawChatHistory;
    
    UIBarButtonItem *lockButton;
    UIBarButtonItem *unlockedButton;
    ConnContext *context;
    
    NSString *protocol;
}

@property (nonatomic, retain) OTRProtocolManager *protocolManager;

@property (retain, nonatomic) DTAttributedTextView *chatHistoryTextView;
@property (retain, nonatomic) IBOutlet UITextField *messageTextField;
@property (retain, nonatomic) OTRBuddyListViewController *buddyListController;
@property (retain, nonatomic) IBOutlet UITextView *chatBox;
@property (nonatomic, retain) NSMutableString *rawChatHistory;
@property (nonatomic, retain) NSString *protocol;
@property (nonatomic, retain) NSString *accountName;
@property (nonatomic, retain) UIView *viewChatHistory;
@property (nonatomic, retain) UIView *viewChatBox;


- (IBAction)sendButtonPressed:(id)sender;
- (void)receiveMessage:(NSString*)message;
- (void)sendMessage:(NSString*)message;
- (void)scrollTextViewToBottom;

- (void)updateChatHistory;
- (void)setupLockButton;
- (void)refreshLockButton;
- (void)lockButtonPressed;

@end
