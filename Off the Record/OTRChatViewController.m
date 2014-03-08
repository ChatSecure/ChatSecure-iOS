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
#import <QuartzCore/QuartzCore.h>
#import "Strings.h"
#import "OTRDoubleSetting.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"

#import "DAKeyboardControl.h"
#import "OTRManagedStatusMessage.h"
#import "OTRManagedEncryptionMessage.h"
#import "OTRStatusMessageCell.h"
#import "OTRUtilities.h"
#import "OTRLockButton.h"

#import "OTRIncomingMessageTableViewCell.h"
#import "OTROutgoingMessageTableViewCell.h"
#import "UIAlertView+Blocks.h"

#import "OTRImages.h"
#import "OTRComposingImageView.h"

static NSUInteger const kOTRActionSheetEncryptionOptionsTag = 201;
static NSUInteger const kOTRAlertViewVerifiedTag = 202;
static NSUInteger const kOTRAlertViewNotVerifiedTag = 203;
static CGFloat const kOTRChatBarHeight = 40;
static CGFloat const kOTRMessageMarginBottom = 10;
static CGFloat const kOTRMessageMarginTop = 7;
static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;


typedef NS_ENUM(NSInteger, OTRChatViewTags) {
    OTRChatViewAlertViewVerifiedTag            = 200,
    OTRChatViewAlertViewNotVerifiedTag         = 201,
    OTRChatViewActionSheetEncryptionOptionsTag = 202
};

@interface OTRChatViewController ()

@property (nonatomic, strong) UIView *composingImageView;
@property (nonatomic, readonly) CGFloat initialBarChatBarHeight;
@property (nonatomic, strong) OTRLockButton *lockButton;
@property (nonatomic, strong) UIBarButtonItem *lockBarButtonItem;
@property (nonatomic, strong) NSMutableArray *showDateForRowArray;
@property (nonatomic, strong) NSDate *previousShownSentDate;
@property (nonatomic, strong) OTRChatInputBar *chatInputBar;
@property (nonatomic, strong) OTRTitleSubtitleView *titleView;
@property (nonatomic) CGFloat previousTextViewContentHeight;

@end

@implementation OTRChatViewController

- (void) dealloc {
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
    
}

- (id)init {
    if (self = [super init]) {
        //set notification for when keyboard shows/hides
        self.title = CHAT_STRING;
        self.titleView = [[OTRTitleSubtitleView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.navigationItem.titleView = self.titleView;
    }
    return self;
}

- (CGFloat)initialBarChatBarHeight
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        return 40;
    }
    else{
        return 42;
    }
}

-(void)setupLockButton
{
    __weak OTRChatViewController * weakSelf = self;
    self.lockButton = [OTRLockButton lockButtonWithInitailLockStatus:OTRLockStatusUnlocked withBlock:^(OTRLockStatus currentStatus){
        NSString *encryptionString = INITIATE_ENCRYPTED_CHAT_STRING;
        NSString * verifiedString = VERIFY_STRING;
        
        if ([[OTRKit sharedInstance] isConversationEncryptedForUsername:weakSelf.buddy.accountName accountName:weakSelf.buddy.account.username protocol:weakSelf.buddy.account.protocol]) {
            encryptionString = CANCEL_ENCRYPTED_CHAT_STRING;
        }
        
         NSString * title = nil;
        if (currentStatus == OTRLockStatusLockedAndError) {
            title = LOCKED_ERROR_STRING;
        }
        else if (currentStatus == OTRLockStatusLockedAndWarn) {
            title = LOCKED_WARN_STRING;
        }
        else if (currentStatus == OTRLockStatusLockedAndVerified){
            title = LOCKED_SECURE_STRING;
        }
        else if (currentStatus == OTRLockStatusUnlocked){
            title = UNLOCKED_ALERT_STRING;
        }
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:title delegate:weakSelf cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:encryptionString, verifiedString, CLEAR_CHAT_HISTORY_STRING, nil];
        popupQuery.accessibilityLabel = @"secure";
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        popupQuery.tag = OTRChatViewActionSheetEncryptionOptionsTag;
        [OTR_APP_DELEGATE presentActionSheet:popupQuery inView:weakSelf.view];
    }];
    
    self.lockBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.lockButton];
    [self.navigationItem setRightBarButtonItem:self.lockBarButtonItem];
    
    [self refreshLockButton];
}

-(void)refreshLockButton
{
    [OTRCodec isGeneratingKeyForBuddy:self.buddy completion:^(BOOL isGeneratingKey) {
        if (isGeneratingKey) {
            [self addLockSpinner];
        }
    }];
    UIBarButtonItem * rightBarItem = self.navigationItem.rightBarButtonItem;
    if ([rightBarItem isEqual:self.lockBarButtonItem]) {
        BOOL isTrusted = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
        BOOL isEncrypted = [[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
        BOOL  hasVerifiedFingerprints = [[OTRKit sharedInstance] hasVerifiedFingerprintsForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
        
        if (isEncrypted && isTrusted) {
            self.lockButton.lockStatus = OTRLockStatusLockedAndVerified;
        }
        else if (isEncrypted && hasVerifiedFingerprints)
        {
            self.lockButton.lockStatus = OTRLockStatusLockedAndError;
        }
        else if (isEncrypted) {
            self.lockButton.lockStatus = OTRLockStatusLockedAndWarn;
        }
        else {
            self.lockButton.lockStatus = OTRLockStatusUnlocked;
        }
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.showDateForRowArray = [NSMutableArray array];
    
    self.chatHistoryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
    [self.chatHistoryTableView registerClass:[OTRIncomingMessageTableViewCell class]
                      forCellReuseIdentifier:[OTRIncomingMessageTableViewCell reuseIdentifier]];
    [self.chatHistoryTableView registerClass:[OTROutgoingMessageTableViewCell class]
                      forCellReuseIdentifier:[OTROutgoingMessageTableViewCell reuseIdentifier]];
    
    
    UIEdgeInsets insets = self.chatHistoryTableView.contentInset;
    insets.bottom = self.initialBarChatBarHeight;
    
    self.chatHistoryTableView.contentInset = self.chatHistoryTableView.scrollIndicatorInsets = insets;
    
    self.chatHistoryTableView.dataSource = self;
    self.chatHistoryTableView.delegate = self;
    self.chatHistoryTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);;
    self.chatHistoryTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.chatHistoryTableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.chatHistoryTableView];
    
    [self.chatHistoryTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    
    self.previousTextViewContentHeight = kOTRMessageFontSize+20;
        
    CGRect barRect = CGRectMake(0, self.view.frame.size.height-self.initialBarChatBarHeight, self.view.frame.size.width, self.initialBarChatBarHeight);
    
    self.chatInputBar = [[OTRChatInputBar alloc] initWithFrame:barRect withDelegate:self];
   
    [self.view addSubview:self.chatInputBar];
    
    self.view.keyboardTriggerOffset = self.chatInputBar.frame.size.height;
    
    self.swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom)];
    [self.view addGestureRecognizer:self.swipeGestureRecognizer];
    
    [self setupLockButton];
    
    
}
-(void)handleSwipeFrom
{
    if (self.swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) showDisconnectionAlert:(NSNotification*)notification {
    NSMutableString *message = [NSMutableString stringWithFormat:DISCONNECTED_MESSAGE_STRING, self.buddy.account.username];
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        [message appendFormat:@" %@", DISCONNECTION_WARNING_STRING];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DISCONNECTED_TITLE_STRING message:message delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles: nil];
    [alert show];
}

- (void) setBuddy:(OTRManagedBuddy *)newBuddy {
    [self saveCurrentMessageText];
    
    _buddy = newBuddy;
    
    [self refreshView];
    if (self.buddy) {
        if ([newBuddy.displayName length]) {
            self.titleView.titleLabel.text = newBuddy.displayName;
        }
        else {
            self.titleView.titleLabel.text = newBuddy.accountName;
        }
        
        if(newBuddy.account.displayName.length) {
            self.titleView.subtitleLabel.text = newBuddy.account.displayName;
        }
        else {
            self.titleView.subtitleLabel.text = newBuddy.account.username;
        }
        
        [self refreshLockButton];
        [self updateChatState:NO];
    }
    
    
}

-(NSIndexPath *)lastIndexPath
{
    return [NSIndexPath indexPathForRow:([self.chatHistoryTableView numberOfRowsInSection:0] - 1) inSection:0];
}


-(void)removeComposing
{
    self.isComposingVisible = NO;
    [self.chatHistoryTableView beginUpdates];
    [self.chatHistoryTableView deleteRowsAtIndexPaths:@[[self lastIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.chatHistoryTableView endUpdates];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [(OTRComposingImageView *)self.composingImageView stopBlinking];
    }
    
    [self scrollToBottomAnimated:YES];
    
}
-(void)addComposing
{
    if (!self.composingImageView) {
        self.composingImageView = [OTRImages typingBubbleView];
    }
    
    self.isComposingVisible = YES;
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
                if (!self.isComposingVisible) {
                    [self addComposing];
                }
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                    if (!((OTRComposingImageView *)self.composingImageView).isBlinking) {
                        [(OTRComposingImageView *)self.composingImageView startBlinking];
                    }
                }
                
            }
        break;
        case kOTRChatStatePaused:
            {
                if (!self.isComposingVisible) {
                    [self addComposing];
                }
                
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                    [(OTRComposingImageView *)self.composingImageView stopBlinking];
                }
            }
            break;
        case kOTRChatStateActive:
            if (self.isComposingVisible) {
                [self removeComposing];
            }
            break;
        default:
            if (self.isComposingVisible) {
                [self removeComposing];
            }
            break;
    }
}
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self scrollToBottomAnimated:YES];
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //DDLogInfo(@"buttonIndex: %d",buttonIndex);
    if(actionSheet.tag == OTRChatViewActionSheetEncryptionOptionsTag)
    {
        if (buttonIndex == 1) // Verify
        {
            NSString *msg = nil;
            NSString *ourFingerprintString = [[OTRKit sharedInstance] fingerprintForAccountName:self.buddy.account.username protocol:self.buddy.account.protocol];
            NSString *theirFingerprintString = [[OTRKit sharedInstance] fingerprintForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
            BOOL trusted = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
            
            
            UIAlertView * alert;
            __weak OTRChatViewController * weakSelf = self;
            RIButtonItem * verifiedButtonItem = [RIButtonItem itemWithLabel:VERIFIED_STRING action:^{
                [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.accountName accountName:weakSelf.buddy.account.username protocol:weakSelf.buddy.account.protocol verrified:YES];
                [weakSelf refreshLockButton];
            }];
            RIButtonItem * notVerifiedButtonItem = [RIButtonItem itemWithLabel:NOT_VERIFIED_STRING action:^{
                [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.accountName accountName:weakSelf.buddy.account.username protocol:weakSelf.buddy.account.protocol verrified:NO];
                [weakSelf refreshLockButton];
            }];
            RIButtonItem * verifyLaterButtonItem = [RIButtonItem itemWithLabel:VERIFY_LATER_STRING action:^{
                [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.accountName accountName:weakSelf.buddy.account.username protocol:weakSelf.buddy.account.protocol verrified:NO];
                [weakSelf refreshLockButton];
            }];

            if(ourFingerprintString && theirFingerprintString) {
                msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, self.buddy.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, self.buddy.accountName, theirFingerprintString];
                if(trusted)
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifiedButtonItem otherButtonItems:notVerifiedButtonItem, nil];
                }
                else
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifyLaterButtonItem otherButtonItems:verifiedButtonItem, nil];
                }
            } else {
                msg = SECURE_CONVERSATION_STRING;
                alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            }
                            
            [alert show];
        }
        else if (buttonIndex == 0) // Initiate/cancel encryption
        {
            if([[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol])
            {
                [[OTRKit sharedInstance] disableEncryptionForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
            } else {
                void (^sendInitateOTRMessage)(void) = ^void (void) {
                    [OTRCodec generateOtrInitiateOrRefreshMessageTobuddy:self.buddy completionBlock:^(OTRManagedChatMessage *message) {
                        [OTRProtocolManager sendMessage:message];
                    }];
                };
                [OTRCodec hasGeneratedKeyForAccount:self.buddy.account completionBlock:^(BOOL hasGeneratedKey) {
                    if (!hasGeneratedKey) {
                        [self addLockSpinner];
                        [OTRCodec generatePrivateKeyFor:self.buddy.account completionBlock:^(BOOL generatedKey) {
                            [self removeLockSpinner];
                            sendInitateOTRMessage();
                        }];
                    }
                    else {
                        sendInitateOTRMessage();
                    }
                }];
            }
        }
        else if (buttonIndex == 2) { // Clear Chat History
            NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
            [self.buddy deleteAllMessagesInContext:context];
            [context MR_saveToPersistentStoreAndWait];
        }
        else if (buttonIndex == actionSheet.cancelButtonIndex) // Cancel
        {
            
        }
    }
}

-(void)addLockSpinner {
    UIActivityIndicatorView * activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activityIndicatorView sizeToFit];
    [activityIndicatorView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    UIBarButtonItem * activityBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
    [activityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = activityBarButtonItem;
}
-(void)removeLockSpinner {
    self.navigationItem.rightBarButtonItem = self.lockBarButtonItem;
    [self refreshLockButton];
}

- (void) refreshView {
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
    if (!self.buddy) {
        if (!self.instructionsLabel) {
            int labelWidth = 500;
            int labelHeight = 100;
            self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-labelWidth/2, self.view.frame.size.height/2-labelHeight/2, labelWidth, labelHeight)];
            self.instructionsLabel.text = CHAT_INSTRUCTIONS_LABEL_STRING;
            self.instructionsLabel.numberOfLines = 2;
            self.instructionsLabel.backgroundColor = self.chatHistoryTableView.backgroundColor;
            [self.view addSubview:self.instructionsLabel];
            //self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        if (self.instructionsLabel) {
            [self.instructionsLabel removeFromSuperview];
            self.instructionsLabel = nil;
        }
        [self buddyFetchedResultsController];
        [self messagesFetchedResultsController];
        self.showDateForRowArray = [NSMutableArray array];
        self.previousShownSentDate = nil;
        
        NSManagedObjectContext *context = self.buddy.managedObjectContext;
        [self.buddy setAllMessagesRead:YES];
        [context MR_saveToPersistentStoreAndWait];
        
        [self.chatHistoryTableView reloadData];
               
        
        
        if(![self.buddy.composingMessageString length])
        {
            [self.buddy sendActiveChatState];
            self.chatInputBar.textView.text = nil;
        }
        else{
            self.chatInputBar.textView.text = self.buddy.composingMessageString;
            
        }
        
        [self scrollToBottomAnimated:NO];
        [self refreshLockButton];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSManagedObjectContext * context = self.buddy.managedObjectContext;
    [self.buddy setAllMessagesRead:YES];
    [context MR_saveToPersistentStoreWithCompletion:nil];
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.view removeKeyboardControl];
    [self setBuddy:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __weak OTRChatViewController * chatViewController = self;
    __weak OTRChatInputBar * weakChatInputbar = self.chatInputBar;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        CGRect messageInputBarFrame = weakChatInputbar.frame;
        messageInputBarFrame.origin.y = keyboardFrameInView.origin.y - messageInputBarFrame.size.height;
        weakChatInputbar.frame = messageInputBarFrame;
        
        UIEdgeInsets tableViewContentInset = chatViewController.chatHistoryTableView.contentInset;
        tableViewContentInset.bottom = chatViewController.view.frame.size.height-weakChatInputbar.frame.origin.y;
        chatViewController.chatHistoryTableView.contentInset = chatViewController.chatHistoryTableView.scrollIndicatorInsets = tableViewContentInset;
        [chatViewController scrollToBottomAnimated:NO];
    }];
    
    [self refreshView];
    [self updateChatState:NO];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    // KLUDGE: Work around keyboard visibility bug where chat input view is visible but keyboard is not
    if (self.view.keyboardFrameInView.size.height == 0 && self.chatInputBar.frame.origin.y < self.view.frame.size.height - self.chatInputBar.frame.size.height) {
        [self.chatInputBar.textView becomeFirstResponder];
    }
    // KLUDGE: If chatInputBar is beyond the bounds of the screen for some unknown reason, force it back into place
    if (self.chatInputBar.frame.origin.y > self.view.frame.size.height - self.chatInputBar.frame.size.height) {
        CGRect newFrame = self.chatInputBar.frame;
        newFrame.origin.y = self.view.frame.size.height - self.chatInputBar.frame.size.height;
        self.chatInputBar.frame = newFrame;
    }

}

-(void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.chatInputBar.textView.text;
    if(![self.buddy.composingMessageString length])
    {
        [self.buddy sendInactiveChatState];
    }
    self.chatInputBar.textView.text = nil;
}


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

- (BOOL)showDateForMessageAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < [self.showDateForRowArray count]) {
        return [self.showDateForRowArray[indexPath.row] boolValue];
    }
    else if (indexPath.row - [self.showDateForRowArray count] > 0)
    {
        [self showDateForMessageAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row-1 inSection:indexPath.section]];
    }
    
    __block BOOL showDate = NO;
    if (indexPath.row < [[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects]) {
        id messageOrStatus = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        if([messageOrStatus isKindOfClass:[OTRManagedChatMessage class]]) {
            //only OTRManagedMessage get dates
            
            OTRManagedChatMessage * currentMessage = (OTRManagedChatMessage *)messageOrStatus;
            
            if (!_previousShownSentDate || [currentMessage.date timeIntervalSinceDate:_previousShownSentDate] > kOTRMessageSentDateShowTimeInterval) {
                _previousShownSentDate = currentMessage.date;
                showDate = YES;
            }
        }
    }
    
    
    [self.showDateForRowArray addObject:[NSNumber numberWithBool:showDate]];
    
    return showDate;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0;
    if (indexPath.row < [[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects])
    {
        BOOL showDate = [self showDateForMessageAtIndexPath:indexPath];
        id messageOrStatus = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        if([messageOrStatus isKindOfClass:[OTRManagedChatMessage class]]) {

            OTRManagedChatMessage * message = (OTRManagedChatMessage *)messageOrStatus;
            height = [OTRMessageTableViewCell heightForMesssage:message.message showDate:showDate];
            
        }
        else {
            height = kOTRMessageSentDateLabelHeight;
        }
    }
    else
    {
        //Composing messsage height
        CGSize messageTextLabelSize =[OTRMessageTableViewCell messageTextLabelSize:@"T"];
        height = messageTextLabelSize.height+kOTRMessageMarginTop+kOTRMessageMarginBottom;
    }
    return height;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numMessages = [[self.messagesFetchedResultsController sections][section] numberOfObjects];
    if (self.isComposingVisible) {
        numMessages +=1;
    }
    return numMessages;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastIndex = ([[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects]-1);
    BOOL isLastRow = indexPath.row > lastIndex;
    BOOL isComposing = self.buddy.chatStateValue == kOTRChatStateComposing;
    BOOL isPaused = self.buddy.chatStateValue == kOTRChatStatePaused;
    BOOL isComposingRow = ((isComposing || isPaused) && isLastRow);
    if (isComposingRow){
        UITableViewCell * cell;
        static NSString *ComposingCellIdentifier = @"composingCell";
        cell = [tableView dequeueReusableCellWithIdentifier:ComposingCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ComposingCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            self.composingImageView.backgroundColor = tableView.backgroundColor; // speeds scrolling
            [cell.contentView addSubview:self.composingImageView];
            
            //messageBackgroundImageView.frame = CGRectMake(0, 0, _messageBubbleComposing.size.width, _messageBubbleComposing.size.height);
            //messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        }
        return cell;
    }
    else if([[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects] > indexPath.row) {
        
        id messageOrStatus = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        BOOL showDate = [self showDateForMessageAtIndexPath:indexPath];

        if ([messageOrStatus isKindOfClass:[OTRManagedMessage class]]) {
            OTRManagedMessage * message = (OTRManagedMessage *)messageOrStatus;
            NSString * reuseIdentifier = nil;
            if (message.isIncomingValue) {
                reuseIdentifier = [OTRIncomingMessageTableViewCell reuseIdentifier];
            }
            else {
                reuseIdentifier = [OTROutgoingMessageTableViewCell reuseIdentifier];
            }
            
            OTRMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
            
            cell.showDate = showDate;
            [cell setMessage:message];
            
            return cell;
        }
        else if ([messageOrStatus isKindOfClass:[OTRManagedStatusMessage class]] || [messageOrStatus isKindOfClass:[OTRManagedEncryptionMessage class]])
        {
            static NSString *statusCellIdentifier = @"statusCell";
            UITableViewCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:statusCellIdentifier];
            if (!cell) {
                cell = [[OTRStatusMessageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:statusCellIdentifier];
            }
            
            
            NSString * cellText = nil;
            OTRManagedMessage * managedStatus = (OTRManagedMessage *)messageOrStatus;
            
            if ([messageOrStatus isKindOfClass:[OTRManagedStatusMessage class]]) {
                if (managedStatus.isIncomingValue) {
                    cellText = [NSString stringWithFormat:INCOMING_STATUS_MESSAGE,managedStatus.message];
                }
                else{
                    cellText = [NSString stringWithFormat:YOUR_STATUS_MESSAGE,managedStatus.message];
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
    
    _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:nil ascending:YES delegate:self];
    
    return _buddyFetchedResultsController;
}

- (NSFetchedResultsController *)messagesFetchedResultsController {
    if (_messagesFetchedResultsController)
    {
        return _messagesFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedMessageRelationships.buddy,self.buddy];
    NSPredicate * encryptionFilter = [NSPredicate predicateWithFormat:@"%K == NO",OTRManagedMessageAttributes.isEncrypted];
    NSPredicate * messagePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,encryptionFilter]];

    _messagesFetchedResultsController = [OTRManagedMessage MR_fetchAllGroupedBy:nil withPredicate:messagePredicate sortedBy:OTRManagedMessageAttributes.date ascending:YES delegate:self];

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
                if ([possibleMessage isKindOfClass:[OTRManagedChatMessage class]]) {
                    ((OTRManagedChatMessage *)possibleMessage).isReadValue = YES;
                }
                
            }
                break;
            case NSFetchedResultsChangeUpdate:
            {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
                break;
            case NSFetchedResultsChangeDelete:
            {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
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

#pragma mark OTRChatInputBarDelegate Methods

- (void)sendButtonPressedForInputBar:(OTRChatInputBar *)inputBar
{
    if ([inputBar.textView isFirstResponder]) {
        //trick to include last auto correct suggestion
        [inputBar.textView resignFirstResponder];
        [inputBar.textView becomeFirstResponder];
    }
    NSString * text = inputBar.textView.text;
    if ([text length]) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_context];
        OTRManagedChatMessage * message = [OTRManagedChatMessage newMessageToBuddy:self.buddy message:text encrypted:NO inContext:context];
        
        [context MR_saveToPersistentStoreAndWait];
        
        BOOL inSecureConversation = [[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.accountName accountName:self.buddy.account.username protocol:self.buddy.account.protocol];
        BOOL secure = inSecureConversation || [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyOpportunisticOtr];
        if(secure)
        {
            //check if need to generate keys
            [OTRCodec hasGeneratedKeyForAccount:self.buddy.account completionBlock:^(BOOL hasGeneratedKey) {
                if (!hasGeneratedKey) {
                    [self addLockSpinner];
                    [OTRCodec generatePrivateKeyFor:self.buddy.account completionBlock:^(BOOL generatedKey) {
                        [self removeLockSpinner];
                        [OTRCodec encodeMessage:message completionBlock:^(OTRManagedChatMessage *message) {
                            [OTRProtocolManager sendMessage:message];
                        }];
                    }];
                }
                else {
                    [OTRCodec encodeMessage:message completionBlock:^(OTRManagedChatMessage *message) {
                        [OTRProtocolManager sendMessage:message];
                    }];
                }
            }];
        }
        else {
            [OTRProtocolManager sendMessage:message];
        }
        self.chatInputBar.textView.text = nil;
    }
}

-(BOOL)inputBar:(OTRChatInputBar *)inputBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
     NSRange textFieldRange = NSMakeRange(0, [inputBar.textView.text length]);
     
     [self.buddy sendComposingChatState];
     
     if (NSEqualRanges(range, textFieldRange) && [text length] == 0)
     {
          [self.buddy sendActiveChatState];
     }
     
     return YES;
}

-(void)didChangeFrameForInputBur:(OTRChatInputBar *)inputBar
{
    UIEdgeInsets tableViewInsets = self.chatHistoryTableView.contentInset;
    tableViewInsets.bottom = self.view.frame.size.height - inputBar.frame.origin.y;
    self.chatHistoryTableView.contentInset = self.chatHistoryTableView.scrollIndicatorInsets = tableViewInsets;
    self.view.keyboardTriggerOffset = inputBar.frame.size.height;
}

- (void)inputBarDidBeginEditing:(OTRChatInputBar *)inputBar
{
    [self scrollToBottomAnimated:YES];
}


@end
