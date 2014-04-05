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
#import "OTRStatusMessageCell.h"
#import "OTRUtilities.h"
#import "OTRLockButton.h"

#import "OTRIncomingMessageTableViewCell.h"
#import "OTROutgoingMessageTableViewCell.h"
#import "UIAlertView+Blocks.h"

#import "OTRImages.h"
#import "OTRButtonView.h"
#import "OTRComposingImageView.h"
#import "OTRChatBubbleView.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"

#import "OTRXMPPManager.h"

static CGFloat const kOTRMessageMarginBottom = 10;
static CGFloat const kOTRMessageMarginTop = 7;
static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;


typedef NS_ENUM(NSInteger, OTRChatViewTags) {
    OTRChatViewAlertViewVerifiedTag            = 200,
    OTRChatViewAlertViewNotVerifiedTag         = 201,
    OTRChatViewActionSheetEncryptionOptionsTag = 202
};

@interface OTRChatViewController () <UIActionSheetDelegate,UIAlertViewDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,OTRChatInputBarDelegate>

@property (nonatomic) CGFloat previousTextViewContentHeight;
@property (nonatomic, readonly) CGFloat initialBarChatBarHeight;

@property (nonatomic, strong) UIView *composingImageView;
@property (nonatomic, strong) OTRLockButton *lockButton;
@property (nonatomic, strong) UIBarButtonItem *lockBarButtonItem;
@property (nonatomic, strong) NSMutableArray *showDateForRowArray;
@property (nonatomic, strong) NSDate *previousShownSentDate;
@property (nonatomic, strong) OTRChatInputBar *chatInputBar;
@property (nonatomic, strong) OTRTitleSubtitleView *titleView;

@property (nonatomic, strong) OTRButtonView *buttonDropdownView;
@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, retain) NSURL *lastActionLink;
@property (nonatomic) BOOL isComposingVisible;
@property (nonatomic, retain) UISwipeGestureRecognizer * swipeGestureRecognizer;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *buddyMappings;

@end

@implementation OTRChatViewController

- (id)init {
    if (self = [super init]) {
        //set notification for when keyboard shows/hides
        self.title = CHAT_STRING;
        self.titleView = [[OTRTitleSubtitleView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.navigationItem.titleView = self.titleView;
        self.databaseConnection = [OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection;
        [self.databaseConnection beginLongLivedReadTransaction];
        
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
        
        if (self.buttonDropdownView) {
            [self hideDropdown:YES];
            return;
        }
        
        NSString *encryptionString = INITIATE_ENCRYPTED_CHAT_STRING;
        NSString *fingerprintString = VERIFY_STRING;
        NSArray * buttons = nil;
        
        if ([[OTRKit sharedInstance] isConversationEncryptedForUsername:weakSelf.buddy.username accountName:weakSelf.account.username protocol:[weakSelf.account protocolTypeString]]) {
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
        
        UIButton *encryptionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [encryptionButton setTitle:encryptionString forState:UIControlStateNormal];
        [encryptionButton addTarget:self action:@selector(encryptionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if (currentStatus == OTRLockStatusUnlocked || currentStatus == OTRLockStatusUnlocked) {
            buttons = @[encryptionButton];
        }
        else {
            UIButton *fingerprintButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [fingerprintButton setTitle:fingerprintString forState:UIControlStateNormal];
            [fingerprintButton addTarget:self action:@selector(verifyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            buttons = @[encryptionButton,fingerprintButton];
        }
        
        [self showDropdownWithTitle:title buttons:buttons animated:YES];
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
        BOOL isTrusted = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
        BOOL isEncrypted = [[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
        BOOL  hasVerifiedFingerprints = [[OTRKit sharedInstance] hasVerifiedFingerprintsForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
        
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
    
    self.chatHistoryTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                             style:UITableViewStylePlain];
    
    [self.chatHistoryTableView registerClass:[OTRIncomingMessageTableViewCell class]
                      forCellReuseIdentifier:[OTRIncomingMessageTableViewCell reuseIdentifier]];
    [self.chatHistoryTableView registerClass:[OTROutgoingMessageTableViewCell class]
                      forCellReuseIdentifier:[OTROutgoingMessageTableViewCell reuseIdentifier]];
    
    
    UIEdgeInsets insets = self.chatHistoryTableView.contentInset;
    insets.bottom = self.initialBarChatBarHeight;
    
    self.chatHistoryTableView.contentInset = self.chatHistoryTableView.scrollIndicatorInsets = insets;
    
    self.chatHistoryTableView.dataSource = self;
    self.chatHistoryTableView.delegate = self;
    self.chatHistoryTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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

- (void)viewWillDisappear:(BOOL)animated
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self.buddy setAllMessagesRead:transaction];
    }];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:OTRUIDatabaseConnectionDidUpdateNotification
                                               object:nil];
    
}

#pragma - mark helper Methods

-(void)handleSwipeFrom
{
    if (self.swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) showDisconnectionAlert:(NSNotification*)notification {
    NSMutableString *message = [NSMutableString stringWithFormat:DISCONNECTED_MESSAGE_STRING, self.account.username];
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        [message appendFormat:@" %@", DISCONNECTION_WARNING_STRING];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DISCONNECTED_TITLE_STRING message:message delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles: nil];
    [alert show];
}

- (OTRXMPPManager *)xmppManager
{
    if ([self.account isKindOfClass:[OTRXMPPAccount class]]) {
        return (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
    }
    return nil;
    
}


-(NSIndexPath *)lastIndexPath
{
    return [NSIndexPath indexPathForRow:([self.chatHistoryTableView numberOfRowsInSection:0] - 1) inSection:0];
}

#pragma  - mark ComposingView Methods

-(void)removeComposing
{
    self.isComposingVisible = NO;

    [self.chatHistoryTableView deleteRowsAtIndexPaths:@[[self lastIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];

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

    [self.chatHistoryTableView insertRowsAtIndexPaths:@[lastIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    
    
    
    [self scrollToBottomAnimated:YES];
}

- (void)updateChatState:(BOOL)animated
{
    switch (self.buddy.chatState) {
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

#pragma - mark iOS 6 Rotate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

#pragma - mark LockButton Methods

- (void)verifyButtonPressed:(id)sender
{
    [self hideDropdown:YES];
    NSString *msg = nil;
    NSString *ourFingerprintString = [[OTRKit sharedInstance] fingerprintForAccountName:self.account.username protocol:[self.account protocolTypeString]];
    NSString *theirFingerprintString = [[OTRKit sharedInstance] fingerprintForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
    BOOL trusted = [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
    
    
    UIAlertView * alert;
    __weak OTRChatViewController * weakSelf = self;
    RIButtonItem * verifiedButtonItem = [RIButtonItem itemWithLabel:VERIFIED_STRING action:^{
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.username accountName:weakSelf.account.username protocol:[weakSelf.account protocolTypeString] verrified:YES];
        [weakSelf refreshLockButton];
    }];
    RIButtonItem * notVerifiedButtonItem = [RIButtonItem itemWithLabel:NOT_VERIFIED_STRING action:^{
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.username accountName:weakSelf.account.username protocol:[weakSelf.account protocolTypeString] verrified:NO];
        [weakSelf refreshLockButton];
    }];
    RIButtonItem * verifyLaterButtonItem = [RIButtonItem itemWithLabel:VERIFY_LATER_STRING action:^{
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:weakSelf.buddy.username accountName:weakSelf.account.username protocol:[weakSelf.account protocolTypeString] verrified:NO];
        [weakSelf refreshLockButton];
    }];
    
    if(ourFingerprintString && theirFingerprintString) {
        msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, self.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, self.buddy.username, theirFingerprintString];
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

- (void)encryptionButtonPressed:(id)sender
{
    [self hideDropdown:YES];
    if([[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]])
    {
        [[OTRKit sharedInstance] disableEncryptionForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
    } else {
        void (^sendInitateOTRMessage)(void) = ^void (void) {
            [OTRCodec generateOtrInitiateOrRefreshMessageTobuddy:self.buddy completionBlock:^(OTRMessage *message) {
                [[OTRProtocolManager sharedInstance] sendMessage:message];
            }];
        };
        [OTRCodec hasGeneratedKeyForAccount:self.account completionBlock:^(BOOL hasGeneratedKey) {
            if (!hasGeneratedKey) {
                [self addLockSpinner];
                [OTRCodec generatePrivateKeyFor:self.account completionBlock:^(BOOL generatedKey) {
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

#pragma - mark Dropdown Methods

- (void)showDropdownWithTitle:(NSString *)title buttons:(NSArray *)buttons animated:(BOOL)animated
{
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    self.buttonDropdownView = [[OTRButtonView alloc] initWithTitile:title buttons:buttons];
    
    self.buttonDropdownView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y-44, self.view.bounds.size.width, 44);
    
    [self.view addSubview:self.buttonDropdownView];
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = self.buttonDropdownView.frame;
        frame.origin.y = self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y;
        self.buttonDropdownView.frame = frame;
    } completion:nil];
    
}

- (void)hideDropdown:(BOOL)animated
{
    if (!self.buttonDropdownView) {
        return;
    }
    
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = self.buttonDropdownView.frame;
        CGFloat navBarBottom = self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y;
        frame.origin.y = navBarBottom - frame.size.height;
        self.buttonDropdownView.frame = frame;
        
    } completion:^(BOOL finished) {
        if (finished) {
            [self.buttonDropdownView removeFromSuperview];
            self.buttonDropdownView = nil;
        }
    }];
}

#pragma - mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideDropdown:YES];
}

#pragma - mark Refresh Methods

- (void) refreshView {
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
        
        self.showDateForRowArray = [NSMutableArray array];
        self.previousShownSentDate = nil;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.buddy setAllMessagesRead:transaction];
        }];
        
        [self.chatHistoryTableView reloadData];
        
        if(![self.buddy.composingMessageString length])
        {
            [[self xmppManager] sendChatState:kOTRChatStateActive withBuddyID:self.buddy.uniqueId];
            self.chatInputBar.textView.text = nil;
        }
        else{
            self.chatInputBar.textView.text = self.buddy.composingMessageString;
            
        }
        
        [self scrollToBottomAnimated:NO];
        [self refreshLockButton];
        [self updateChatState:NO];
    }
    
}

- (void) setBuddy:(OTRBuddy *)newBuddy {
    
    if (![_buddy.uniqueId isEqualToString:newBuddy.uniqueId]) {
        [self saveCurrentMessageText];
        
        //BOOL chatStatus = [OTRDatabaseView registerChatDatabaseViewWithBuddyUniqueId:newBuddy.uniqueId];
        //BOOL buddyStatus = [OTRDatabaseView registerBuddyDatabaseViewWithBuddyUniqueId:newBuddy.uniqueId];
        
        if (newBuddy) {
            self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[newBuddy.uniqueId] view:OTRChatDatabaseViewExtensionName];
            self.buddyMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[newBuddy.uniqueId] view:OTRBuddyDatabaseViewExtensionName];
            
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                self.account = [newBuddy accountWithTransaction:transaction];
                [self.mappings updateWithTransaction:transaction];
                [self.buddyMappings updateWithTransaction:transaction];
            }];
        }
        else {
            self.mappings = nil;
            self.buddyMappings = nil;
            self.account = nil;
        }
        
    }
    
    _buddy = newBuddy;
    
    [self refreshView];
    if (self.buddy) {
        if ([self.buddy.displayName length]) {
            self.titleView.titleLabel.text = self.buddy.displayName;
        }
        else {
            self.titleView.titleLabel.text = self.buddy.username;
        }
        
        if(self.account.displayName.length) {
            self.titleView.subtitleLabel.text = self.account.displayName;
        }
        else {
            self.titleView.subtitleLabel.text = self.account.username;
        }
    }
}

-(void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.chatInputBar.textView.text;
    if(![self.buddy.composingMessageString length])
    {
        [[self xmppManager] sendChatState:kOTRChatStateInactive withBuddyID:self.buddy.uniqueId];
    }
    self.chatInputBar.textView.text = nil;
}


#pragma - mark detailedView delegate methods
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

- (OTRMessage *)messageAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRMessage *message = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [[transaction ext:OTRChatDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    return message;
}


- (BOOL)showDateForMessageAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < [self.showDateForRowArray count]) {
        return [self.showDateForRowArray[indexPath.row] boolValue];
    }
    else if (indexPath.row - [self.showDateForRowArray count] > 0)
    {
        [self showDateForMessageAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row-1 inSection:indexPath.section]];
    }
    
    BOOL showDate = NO;
    if (indexPath.row < [self.mappings numberOfItemsInSection:indexPath.section]) {
        OTRMessage *message = [self messageAtIndexPath:indexPath];
        
        if (!_previousShownSentDate || [message.date timeIntervalSinceDate:_previousShownSentDate] > kOTRMessageSentDateShowTimeInterval) {
            _previousShownSentDate = message.date;
            showDate = YES;
        }
    }
    
    [self.showDateForRowArray addObject:[NSNumber numberWithBool:showDate]];
    
    return showDate;
}

#pragma - mark UITableView Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0;
    if (indexPath.row < [self.mappings numberOfItemsInSection:indexPath.section])
    {
        BOOL showDate = [self showDateForMessageAtIndexPath:indexPath];
        OTRMessage *message = [self messageAtIndexPath:indexPath];
        
        height = [OTRMessageTableViewCell heightForMesssage:message.text showDate:showDate];
    }
    else
    {
        //Composing messsage height
        CGSize messageTextLabelSize =[OTRMessageTableViewCell messageTextLabelSize:@"T"];
        height = messageTextLabelSize.height+kOTRMessageMarginTop+kOTRMessageMarginBottom;
    }
    return height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numMessages = [self.mappings numberOfItemsInSection:section];
    if (self.isComposingVisible) {
        numMessages +=1;
    }
    return numMessages;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastIndex = ([self.mappings numberOfItemsInSection:indexPath.section]-1);
    BOOL isLastRow = indexPath.row > lastIndex;
    BOOL isComposing = self.buddy.chatState == kOTRChatStateComposing;
    BOOL isPaused = self.buddy.chatState == kOTRChatStatePaused;
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
        }
        return cell;
    }
    else{
        
        OTRMessage *message = [self messageAtIndexPath:indexPath];
        BOOL showDate = [self showDateForMessageAtIndexPath:indexPath];

        NSString * reuseIdentifier = nil;
        if (message.isIncoming) {
            reuseIdentifier = [OTRIncomingMessageTableViewCell reuseIdentifier];
        }
        else {
            reuseIdentifier = [OTROutgoingMessageTableViewCell reuseIdentifier];
        }
        
        OTRMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        if ([self.account isKindOfClass:[OTRXMPPTorAccount class]]) {
            cell.bubbleView.messageTextLabel.dataDetectorTypes = UIDataDetectorTypeNone;
        }
        else {
            cell.bubbleView.messageTextLabel.dataDetectorTypes = UIDataDetectorTypeLink;
        }
        
        cell.showDate = showDate;
        [cell setMessage:message];
        
        return cell;
    }
}

#pragma mark - YapDatabaseNotificatino Method

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = notification.userInfo[@"notifications"];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRChatDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                           rowChanges:&rowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.mappings];
    
    NSArray *buddyRowChanges = nil;
    [[self.databaseConnection ext:OTRBuddyDatabaseViewExtensionName] getSectionChanges:nil
                                                                            rowChanges:&buddyRowChanges
                                                                      forNotifications:notifications
                                                                          withMappings:self.buddyMappings];
    [self.chatHistoryTableView beginUpdates];
    for (YapDatabaseViewRowChange *rowChange in buddyRowChanges)
    {
        if (rowChange.type == YapDatabaseViewChangeUpdate) {
            __block OTRBuddy *updatedBuddy = nil;
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                updatedBuddy = [[transaction ext:OTRBuddyDatabaseViewExtensionName] objectAtIndexPath:rowChange.indexPath withMappings:self.buddyMappings];
            }];
            
            if (self.buddy.chatState != updatedBuddy.chatState || self.buddy.encryptionStatus != updatedBuddy.encryptionStatus) {
                self.buddy = updatedBuddy;
            }
            

        }
    }
    
    // No need to update mappings.
    // The above method did it automatically.
    /*
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }*/
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.chatHistoryTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.chatHistoryTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.chatHistoryTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.chatHistoryTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.chatHistoryTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.chatHistoryTableView endUpdates];
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
        
        
        
        BOOL inSecureConversation = [[OTRKit sharedInstance] isConversationEncryptedForUsername:self.buddy.username accountName:self.account.username protocol:[self.account protocolTypeString]];
        BOOL secure = inSecureConversation || [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyOpportunisticOtr];
        
        OTRMessage *message = [[OTRMessage alloc] init];
        message.buddyUniqueId = self.buddy.uniqueId;
        message.text = text;
        message.transportedSecurely = secure;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:message forKey:message.uniqueId inCollection:[OTRMessage collection]];
        }];
        
        if(secure)
        {
            //check if need to generate keys
            [OTRCodec hasGeneratedKeyForAccount:self.account completionBlock:^(BOOL hasGeneratedKey) {
                if (!hasGeneratedKey) {
                    [self addLockSpinner];
                    [OTRCodec generatePrivateKeyFor:self.account completionBlock:^(BOOL generatedKey) {
                        [self removeLockSpinner];
                        [OTRCodec encodeMessage:message completionBlock:^(OTRMessage *message) {
                            [[OTRProtocolManager sharedInstance] sendMessage:message];
                        }];
                    }];
                }
                else {
                    [OTRCodec encodeMessage:message completionBlock:^(OTRMessage *message) {
                        [[OTRProtocolManager sharedInstance] sendMessage:message];
                    }];
                }
            }];
        }
        else {
            [[OTRProtocolManager sharedInstance] sendMessage:message];
        }
        self.chatInputBar.textView.text = nil;
    }
}

-(BOOL)inputBar:(OTRChatInputBar *)inputBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
     NSRange textFieldRange = NSMakeRange(0, [inputBar.textView.text length]);
    
    [[self xmppManager] sendChatState:kOTRChatStateComposing withBuddyID:self.buddy.uniqueId];
     
     if (NSEqualRanges(range, textFieldRange) && [text length] == 0)
     {
          [[self xmppManager] sendChatState:kOTRChatStateActive withBuddyID:self.buddy.uniqueId];
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
