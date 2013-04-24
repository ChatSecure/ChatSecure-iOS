//
//  OTRChatViewController.m
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

#import "OTRChatViewController.h"
#import "OTREncryptionManager.h"
#import <QuartzCore/QuartzCore.h>
#import "Strings.h"
#import "OTRDoubleSetting.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"
#import "OTRMessageTableViewCell.h"
#import "DAKeyboardControl.h"
#import "OTRManagedStatus.h"
#import "OTRManagedEncryptionStatusMessage.h"
#import "OTRStatusMessageCell.h"



@interface OTRChatViewController(Private)

- (void) refreshView;



@end

@implementation OTRChatViewController
@synthesize buddyListController;
@synthesize lockButton, unlockedButton,lockVerifiedButton;
@synthesize lastActionLink;
@synthesize sendButton;
@synthesize buddy;
@synthesize instructionsLabel;
@synthesize chatHistoryTableView;
@synthesize textView;
@synthesize swipeGestureRecognizer;

- (void) dealloc {
    self.lastActionLink = nil;
    self.buddyListController = nil;
    self.buddy = nil;
    self.chatHistoryTableView = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.lockButton = nil;
    self.unlockedButton = nil;
    self.sendButton = nil;
    self.instructionsLabel = nil;
    self.chatHistoryTableView = nil;
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        //set notification for when keyboard shows/hides
        self.title = CHAT_STRING;
    }
    return self;
}

- (CGFloat) chatBoxViewHeight {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 50.0;
    } else {
        return 44.0;
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(void)setupLockButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonImage = [UIImage imageNamed:@"Lock_Locked.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    CGRect buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    lockButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonImage = [UIImage imageNamed:@"Lock_Unlocked.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    unlockedButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonImage = [UIImage imageNamed:@"Lock_Locked_Verified.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    lockVerifiedButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [self refreshLockButton];
}

-(void)refreshLockButton
{
    BOOL trusted = [[OTRKit sharedInstance] finerprintIsVerifiedForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
    int16_t currentEncryptionStatus = [self.buddy currentEncryptionStatus].statusValue;
    
    if(currentEncryptionStatus == kOTRKitMessageStateEncrypted && trusted)
    {
        self.navigationItem.rightBarButtonItem = lockVerifiedButton;
    }
    else if(currentEncryptionStatus == kOTRKitMessageStateEncrypted)
    {
        self.navigationItem.rightBarButtonItem = lockButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = unlockedButton;
    }
    self.navigationItem.rightBarButtonItem.accessibilityLabel = @"lock";
}

-(void)lockButtonPressed
{
    NSString *encryptionString = INITIATE_ENCRYPTED_CHAT_STRING;
    NSString * verifiedString = VERIFY_STRING;
    
    int16_t currentEncryptionStatus = [self.buddy currentEncryptionStatus].statusValue;
    
    if (currentEncryptionStatus == kOTRKitMessageStateEncrypted) {
        encryptionString = CANCEL_ENCRYPTED_CHAT_STRING;
    }
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:encryptionString, verifiedString, CLEAR_CHAT_HISTORY_STRING, nil];
    popupQuery.accessibilityLabel = @"secure";
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = ACTIONSHEET_ENCRYPTION_OPTIONS_TAG;
    [OTR_APP_DELEGATE presentActionSheet:popupQuery inView:self.view];
}



#pragma mark - View lifecycle

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:SEND_STRING forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _heightForRow = [NSMutableArray array];
    _messageBubbleComposing = [UIImage imageNamed:@"MessageBubbleTyping"];
    
    self.chatHistoryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1)];
    self.chatHistoryTableView.dataSource = self;
    self.chatHistoryTableView.delegate = self;
    self.chatHistoryTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);;
    self.chatHistoryTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.chatHistoryTableView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    [self.view addSubview:self.chatHistoryTableView];
    
    // Create messageInputBar to contain textView, messageInputBarBackgroundImageView, & sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin );
    messageInputBar.opaque = YES;
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)]; // 8 x 40
    
    
    _messageFontSize = [OTRSettingsManager floatForOTRSettingKey:kOTRSettingKeyFontSize];
    _previousTextViewContentHeight = MessageFontSize+20;
        
    
    
    
    
    
    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //sendButton.frame = CGRectMake(messageInputBar.frame.size.width-65, 8, 59, 26);
    sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin /* multiline input */ | UIViewAutoresizingFlexibleLeftMargin /* landscape */);
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
    [sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    CGFloat buttonWidth = [SEND_STRING sizeWithFont:[UIFont systemFontOfSize:16]].width+20;
    CGRect buttonFrame = CGRectMake(messageInputBar.frame.size.width-(buttonWidth+6), 8, buttonWidth, 26);
    sendButton.frame = buttonFrame;
    
    
    
    sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [sendButton setTitle:SEND_STRING forState:UIControlStateNormal];
    [sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [messageInputBar addSubview:sendButton];
    
    //[sendButton sizeToFit];
    
    CGFloat textViewWidth = messageInputBar.frame.size.width-TEXT_VIEW_X-(buttonWidth+6);
    
    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]]; // 32 x 40
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, textViewWidth+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = self.chatHistoryTableView.autoresizingMask;
    messageInputBarBackgroundImageView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    
    [messageInputBar addSubview:messageInputBarBackgroundImageView];

    
    // Create textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    textView = [[ACPlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, textViewWidth, TEXT_VIEW_HEIGHT_MIN)];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    textView.delegate = self;
    textView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithWhite:245/255.0f alpha:1];
    textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    textView.contentInset = UIEdgeInsetsMake(-6, 0, 0, 0);
    textView.scrollsToTop = NO;
    textView.font = [UIFont systemFontOfSize:MessageFontSize];
    textView.placeholder = MESSAGE_PLACEHOLDER_STRING;
    
    textView.clipsToBounds = YES;
    
    [messageInputBar addSubview:textView];
    
    [self.view addSubview:messageInputBar];
    
    self.view.keyboardTriggerOffset = messageInputBar.frame.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        CGRect messageInputBarFrame = messageInputBar.frame;
        messageInputBarFrame.origin.y = keyboardFrameInView.origin.y - messageInputBarFrame.size.height;
        messageInputBar.frame = messageInputBarFrame;
        
        chatHistoryTableView.contentInset = chatHistoryTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-keyboardFrameInView.origin.y, 0);
    }];
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom)];
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    

    //messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    //sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    //[self.view addSubview:chatBoxView];
    //[self.chatBoxView addSubview:messageTextField];
    //[self.chatBoxView addSubview:sendButton];
    
    
    [self setupLockButton];
    
    
    
    //set notification for when a key is pressed.
    //turn off scrolling and set the font details.
    //chatBox.scrollEnabled = NO;
    //chatBox.font = [UIFont fontWithName:@"Helvetica" size:14];
}

-(void)handleSwipeFrom
{
    if (swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)moveMessageBarBottom
{
    UIView *messageInputBar = textView.superview;
    CGRect newTextFieldFrame = messageInputBar.frame;
    CGFloat viewHeight = self.view.frame.size.height;
    
    newTextFieldFrame.origin.y = viewHeight - newTextFieldFrame.size.height;
    
    messageInputBar.frame = newTextFieldFrame;
    chatHistoryTableView.contentInset = chatHistoryTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-viewHeight-1, 0);
    
}

- (void) showDisconnectionAlert:(NSNotification*)notification {
    NSMutableString *message = [NSMutableString stringWithFormat:DISCONNECTED_MESSAGE_STRING, buddy.account.username];
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        [message appendFormat:@" %@", DISCONNECTION_WARNING_STRING];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DISCONNECTED_TITLE_STRING message:message delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles: nil];
    [alert show];
}

- (void) setBuddy:(OTRManagedBuddy *)newBuddy {
    [self saveCurrentMessageText];
    
    buddy = newBuddy;
    
    [self refreshView];
    if (buddy) {
        self.title = newBuddy.displayName;
        [self refreshLockButton];
        [self updateChatState:NO];
    }
    
    
}

-(BOOL)isComposingVisible
{
    if ([self.chatHistoryTableView numberOfRowsInSection:0] == [[self.messagesFetchedResultsController fetchedObjects] count]) {
        return NO;
    }
    return YES;
}
-(NSIndexPath *)lastIndexPath
{
    return [NSIndexPath indexPathForRow:([self.chatHistoryTableView numberOfRowsInSection:0] - 1) inSection:0];
}


-(void)removeComposing
{
    [self.chatHistoryTableView beginUpdates];
    [self.chatHistoryTableView deleteRowsAtIndexPaths:@[[self lastIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.chatHistoryTableView endUpdates];
    [self scrollToBottomAnimated:YES];
    
}
-(void)addComposing
{
    NSIndexPath * lastIndexPath = [self lastIndexPath];
    NSInteger newLast = [lastIndexPath indexAtPosition:lastIndexPath.length-1]+1;
    lastIndexPath = [[lastIndexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:newLast];
    [self.chatHistoryTableView beginUpdates];
    [self.chatHistoryTableView insertRowsAtIndexPaths:@[lastIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.chatHistoryTableView endUpdates];
    [self scrollToBottomAnimated:YES];
}

- (void)updateChatState:(BOOL)animated
{
    switch (self.buddy.chatStateValue) {
        case kOTRChatStateComposing:
            {
                if (![self isComposingVisible]) {
                    [self addComposing];
                }
            }
        break;
        case kOTRChatStatePaused:
            {
                if (![self isComposingVisible]) {
                [self addComposing];
                }
            }
            break;
        case kOTRChatStateActive:
            if ([self isComposingVisible]) {
                [self removeComposing];
            }
            break;
        default:
            if ([self isComposingVisible]) {
                [self removeComposing];
            }
            break;
    }
}
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self scrollToBottomAnimated:YES];
}


- (void)textViewDidChange:(UITextView *)tView {
    // Change height of _tableView & messageInputBar to match textView's content height.
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
    //    NSLog(@"textViewContentHeight: %f", textViewContentHeight);
    
    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }
    
    float duration = 0.2f;
    
    
    if (changeInHeight) {
        CGRect frame = textView.frame;
        frame.size.height = MIN(textViewContentHeight, ContentHeightMax);
        textView.frame = frame;
        [UIView animateWithDuration:duration animations:^{
            
            
            self.chatHistoryTableView.contentInset = self.chatHistoryTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.chatHistoryTableView.contentInset.bottom+changeInHeight, 0);
            [self scrollToBottomAnimated:NO];
            
            UIView *messageInputBar = textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
            self.view.keyboardTriggerOffset = messageInputBar.frame.size.height;
        } completion:^(BOOL finished) {
            [textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
        
    }
    
    // Enable/disable sendButton if textView.text has/lacks length.
    if ([textView.text length]) {
        sendButton.enabled = YES;
        [buddy sendComposingChatState];
        sendButton.titleLabel.alpha = 1;
    } else {
        sendButton.enabled = NO;
        [buddy sendActiveChatState];
        sendButton.titleLabel.alpha = 0.5f;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSRange textFieldRange = NSMakeRange(0, [textField.text length]);
    
    [buddy sendComposingChatState];
    
    if (NSEqualRanges(range, textFieldRange) && [string length] == 0)
    {
        [buddy sendActiveChatState];
    }
    
    return YES;
}

- (void) encryptionStateChangeNotification:(NSNotification *) notification
{
    [self refreshLockButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [textField resignFirstResponder];
    } else {
        [self sendButtonPressed:nil];
    }
    return YES;
}


- (void)sendButtonPressed:(id)sender {
    int16_t currentEncryptionStatus = [self.buddy currentEncryptionStatus].statusValue;
    BOOL secure = currentEncryptionStatus == kOTRKitMessageStateEncrypted;
    [buddy sendMessage:textView.text secure:secure];
    textView.text = nil;
    [self textViewDidChange:textView];
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex: %d",buttonIndex);
    if(actionSheet.tag == ACTIONSHEET_ENCRYPTION_OPTIONS_TAG)
    {
        if (buttonIndex == 1) // Verify
        {
            NSString *msg = nil;
            NSString *ourFingerprintString = [[OTRKit sharedInstance] fingerprintForAccountName:buddy.account.username protocol:buddy.account.protocol];
            NSString *theirFingerprintString = [[OTRKit sharedInstance] fingerprintForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            BOOL trusted = [[OTRKit sharedInstance] finerprintIsVerifiedForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            
            
            UIAlertView * alert;
            if(ourFingerprintString && theirFingerprintString) {
                msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, buddy.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, buddy.accountName, theirFingerprintString];
                if(trusted)
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg delegate:self cancelButtonTitle:VERIFIED_STRING otherButtonTitles:NOT_VERIFIED_STRING, nil];
                    alert.tag = ALERTVIEW_VERIFIED_TAG;
                }
                else
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg delegate:self cancelButtonTitle:VERIFY_LATER_STRING otherButtonTitles:VERIFIED_STRING, nil];
                    alert.tag = ALERTVIEW_NOT_VERIFIED_TAG;
                }
            } else {
                msg = SECURE_CONVERSATION_STRING;
               alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            }
                            
            [alert show];
        }
        else if (buttonIndex == 0) // Initiate/cancel encryption
        {
            int16_t currentEncryptionStatus = [self.buddy currentEncryptionStatus].statusValue;
            if(currentEncryptionStatus == kOTRKitMessageStateEncrypted)
            {
                [[OTRKit sharedInstance]disableEncryptionForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            } else {
                OTRManagedBuddy* theBuddy = buddy;
                OTRManagedMessage * newMessage = [OTRManagedMessage newMessageToBuddy:theBuddy message:@"" encrypted:YES];
                OTRManagedMessage *encodedMessage = [OTRCodec encodeMessage:newMessage];
                [OTRManagedMessage sendMessage:encodedMessage];
            }
        }
        else if (buttonIndex == 2) { // Clear Chat History
            [buddy deleteAllMessages];
        }
        else if (buttonIndex == actionSheet.cancelButtonIndex) // Cancel
        {
            
        }
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1 && alertView.tag == ALERTVIEW_NOT_VERIFIED_TAG)
    {
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol verrified:YES];
        [self refreshLockButton];
    }
    else if(buttonIndex == 1 && alertView.tag == ALERTVIEW_VERIFIED_TAG)
    {
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:buddy.accountName accountName:buddy.account.username  protocol:buddy.account.protocol verrified:NO];
        [self refreshLockButton];
    }
}


- (void) refreshView {
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
    if (!buddy) {
        if (!instructionsLabel) {
            int labelWidth = 500;
            int labelHeight = 100;
            self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-labelWidth/2, self.view.frame.size.height/2-labelHeight/2, labelWidth, labelHeight)];
            instructionsLabel.text = CHAT_INSTRUCTIONS_LABEL_STRING;
            instructionsLabel.numberOfLines = 2;
            instructionsLabel.backgroundColor = self.chatHistoryTableView.backgroundColor;
            [self.view addSubview:instructionsLabel];
            self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        if (instructionsLabel) {
            [self.instructionsLabel removeFromSuperview];
            self.instructionsLabel = nil;
        }
        [self buddyFetchedResultsController];
        _heightForRow = [NSMutableArray array];
        _previousShownSentDate = nil;
        [self.buddy allMessagesRead];
        [self.chatHistoryTableView reloadData];
        [self.textView resignFirstResponder];
        [self moveMessageBarBottom];
        
        _messageFontSize = [OTRSettingsManager floatForOTRSettingKey:kOTRSettingKeyFontSize];
        
        
        
        if(![self.buddy.composingMessageString length])
        {
            [self.buddy sendActiveChatState];
            textView.text = nil;
        }
        else{
            self.textView.text = self.buddy.composingMessageString;
            
        }
        [self textViewDidChange:textView];
        
        [self scrollToBottomAnimated:NO];
        [self refreshLockButton];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{

    [self.buddy allMessagesRead];
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self setBuddy:nil];
    [super viewDidDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshView];
    [self updateChatState:NO];
    
    
}

-(void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.textView.text;
    if(![self.buddy.composingMessageString length])
    {
        [self.buddy sendInactiveChatState];
    }
    self.textView.text = nil;
    //[self textViewDidChange:textView];
}

/*- (void)debugButton:(UIBarButtonItem *)sender
{
	textView.contentView.drawDebugFrames = !textView.contentView.drawDebugFrames;
	[DTCoreTextLayoutFrame setShouldDrawDebugFrames:textView.contentView.drawDebugFrames];
	[self.view setNeedsDisplay];
}*/


//detailedView delegate methods
- (void)splitViewController:(UISplitViewController*)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController:(UIPopoverController*)pc
{  
    [barButtonItem setTitle:BUDDY_LIST_STRING];
    
    
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}


- (void)splitViewController:(UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = [self.chatHistoryTableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [self.chatHistoryTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"heightForRowAtIndexPath: %@", indexPath);
    
    if (indexPath.row < [[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects])
    {
        NSArray *messageDetails = nil;
        if ([_heightForRow count] > indexPath.row) {
            messageDetails = _heightForRow[indexPath.row];
        }
        
        CGFloat messageSentDateLabelHeight = 0;
        CGFloat messageDeliveredLabelHeight = 0;
        CGFloat messageTextLabelHeight = 0;
        
        if (messageDetails) {
            messageSentDateLabelHeight = [messageDetails[0] floatValue];
            messageTextLabelHeight = [messageDetails[1] CGSizeValue].height;
            messageDeliveredLabelHeight = [messageDetails[2] floatValue];
        }
        
        id messageOrStatus = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        if([messageOrStatus isKindOfClass:[OTRManagedMessage class]])
        {
            OTRManagedMessage * message = (OTRManagedMessage *)messageOrStatus;
            
            
            if (!messageDetails)
            {
                if ((!_previousShownSentDate || [message.date timeIntervalSinceDate:_previousShownSentDate] > MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL)) {
                    _previousShownSentDate = message.date;
                    messageSentDateLabelHeight = MESSAGE_SENT_DATE_LABEL_HEIGHT;
                }
                CGSize messageTextLabelSize = [OTRMessageTableViewCell messageTextLabelSize:message.message];
                messageTextLabelHeight = messageTextLabelSize.height;
                
                
                //messageTextLabelHeight = MESSAGE_DELIVERED_LABEL_HEIGHT;
                
                
                _heightForRow[indexPath.row] = @[@(messageSentDateLabelHeight), [NSValue valueWithCGSize:messageTextLabelSize], @(messageDeliveredLabelHeight)];
            }
            
            return messageSentDateLabelHeight+messageTextLabelHeight+messageDeliveredLabelHeight+MESSAGE_MARGIN_TOP+MESSAGE_MARGIN_BOTTOM;
        }
        else
        {
            if(!messageDetails)
            {
                _heightForRow[indexPath.row] = @[@(MESSAGE_SENT_DATE_LABEL_HEIGHT), [NSValue valueWithCGSize:CGSizeZero], @(messageDeliveredLabelHeight)];
            }
            
            return MESSAGE_SENT_DATE_LABEL_HEIGHT;
        }
        
        
    }
    else
    {
        //Composing messsage height
        CGSize messageTextLabelSize =[OTRMessageTableViewCell messageTextLabelSize:@"T"];
        return messageTextLabelSize.height+MESSAGE_MARGIN_TOP+MESSAGE_MARGIN_BOTTOM;
    }
    
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numMessages = [[self.messagesFetchedResultsController sections][section] numberOfObjects];
    if (buddy.chatStateValue == kOTRChatStateComposing || buddy.chatStateValue == kOTRChatStatePaused) {
        numMessages +=1;
    }
    return numMessages;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastIndex = ([[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects]-1);
    BOOL isLastRow = indexPath.row > lastIndex;
    BOOL isComposing = buddy.chatStateValue == kOTRChatStateComposing;
    BOOL isPaused = buddy.chatStateValue == kOTRChatStatePaused;
    BOOL isComposingRow = ((isComposing || isPaused) && isLastRow);
    if (isComposingRow){
        UITableViewCell * cell;
        static NSString *ComposingCellIdentifier = @"composingCell";
        cell = [tableView dequeueReusableCellWithIdentifier:ComposingCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ComposingCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UIImageView *messageBackgroundImageView;
            messageBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
            messageBackgroundImageView.tag = MESSAGE_BACKGROUND_IMAGE_VIEW_TAG;
            messageBackgroundImageView.backgroundColor = tableView.backgroundColor; // speeds scrolling
            [cell.contentView addSubview:messageBackgroundImageView];
            
            messageBackgroundImageView.frame = CGRectMake(0, 0, _messageBubbleComposing.size.width, _messageBubbleComposing.size.height);
            messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            messageBackgroundImageView.image = _messageBubbleComposing;
            

        }
        return cell;
    }
    else if( [[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects] > indexPath.row) {
        
        id messageOrStatus = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        NSArray *messageDetails = _heightForRow[indexPath.row];
        BOOL showDate = [messageDetails[0] boolValue];

        if ([messageOrStatus isKindOfClass:[OTRManagedMessage class]]) {
            OTRManagedMessage * message = (OTRManagedMessage *)messageOrStatus;
            static NSString *CellIdentifier = @"Cell";
            OTRMessageTableViewCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[OTRMessageTableViewCell alloc] initWithMessage:message withDate:showDate reuseIdentifier:CellIdentifier];
            } else {
                cell.showDate = showDate;
                cell.message = message;
                
            }
            return cell;
        }
        else if ([messageOrStatus isKindOfClass:[OTRManagedStatus class]] || [messageOrStatus isKindOfClass:[OTRManagedEncryptionStatusMessage class]])
        {
            static NSString *CellIdentifier = @"statusCell";
            UITableViewCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[OTRStatusMessageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            }
            
            
            NSString * cellText = nil;
            OTRManagedMessageAndStatus * managedStatus = (OTRManagedMessageAndStatus *)messageOrStatus;
            
            if ([messageOrStatus isKindOfClass:[OTRManagedStatus class]]) {
                if (managedStatus.isIncomingValue) {
                    cellText = [NSString stringWithFormat:@"New Status Message: %@",managedStatus.message];
                }
                else{
                    cellText = [NSString stringWithFormat:@"You are: %@",managedStatus.message];
                }
            }
            else{
                cellText = managedStatus.message;
            }
            
            
            ((OTRStatusMessageCell *)cell).statusMessageLabel.text = cellText;
            
            cell.userInteractionEnabled = NO;
            return cell;
        }
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

-(NSFetchedResultsController *)buddyFetchedResultsController{
    if (_buddyFetchedResultsController)
        return _buddyFetchedResultsController;
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"self == %@",self.buddy];
    //NSPredicate * chatStateFilter = [NSPredicate predicateWithFormat:@"chatState == %d OR chatState == %d",kOTRChatStateComposing,kOTRChatStatePaused];
    //NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,chatStateFilter]];
    
    _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:nil ascending:YES delegate:self];
    
    return _buddyFetchedResultsController;
}

- (NSFetchedResultsController *)messagesFetchedResultsController {
    if (_messagesFetchedResultsController)
    {
        return _messagesFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"self.buddy == %@",self.buddy];
    NSPredicate * encryptionFilter = [NSPredicate predicateWithFormat:@"isEncrypted == NO"];
    NSPredicate * messagePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,encryptionFilter]];

    _messagesFetchedResultsController = [OTRManagedMessageAndStatus MR_fetchAllGroupedBy:nil withPredicate:messagePredicate sortedBy:@"date" ascending:YES delegate:self];

    return _messagesFetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self updateChatState:YES];
    [self refreshLockButton];
    if ([controller isEqual:self.messagesFetchedResultsController])
    {
        [self.chatHistoryTableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = nil;
    
    if ([controller isEqual:_messagesFetchedResultsController])
    {
        tableView = self.chatHistoryTableView;
        
        
        switch(type) {
            case NSFetchedResultsChangeInsert:
            {
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
                
                
                id possibleMessage = [controller objectAtIndexPath:newIndexPath];
                if ([possibleMessage isKindOfClass:[OTRManagedMessage class]]) {
                    ((OTRManagedMessage *)possibleMessage).isReadValue = YES;
                }
                
            }
                break;
            case NSFetchedResultsChangeUpdate:
            {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
                break;
            case NSFetchedResultsChangeDelete:
            {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([controller isEqual:self.messagesFetchedResultsController])
    {
        [self.chatHistoryTableView endUpdates];
        [self scrollToBottomAnimated:YES];
    }
}


@end
