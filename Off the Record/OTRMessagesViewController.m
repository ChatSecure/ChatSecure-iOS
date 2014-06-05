//
//  OTRMessagesViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesViewController.h"

#import "OTRDatabaseView.h"
#import "OTRDatabaseManager.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage+JSQMessageData.h"
#import "JSQMessages.h"
#import "OTRProtocolManager.h"
#import "OTRXMPPTorAccount.h"
#import "OTRXMPPManager.h"
#import "OTRLockButton.h"
#import "OTRButtonView.h"
#import "Strings.h"
#import "UIAlertView+Blocks.h"
#import "OTRTitleSubtitleView.h"
#import "OTRKit.h"
#import "OTRMessagesCollectionViewCellIncoming.h"
#import "OTRMessagesCollectionViewCellOutgoing.h"
#import "OTRImages.h"

static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;

typedef NS_ENUM(int, OTRDropDownType) {
    OTRDropDownTypeNone          = 0,
    OTRDropDownTypeEncryption    = 1,
    OTRDropDownTypePush          = 2
};

@interface OTRMessagesViewController ()

@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *buddyMappings;

@property (nonatomic, strong) UIImageView *outgoingBubbleImageView;
@property (nonatomic, strong) UIImageView *incomingBubbleImageView;

@property (nonatomic, weak) id textViewNotificationObject;

@property (nonatomic, weak) OTRXMPPManager *xmppManager;

@property (nonatomic ,strong) UIBarButtonItem *lockBarButtonItem;
@property (nonatomic, strong) OTRLockButton *lockButton;
@property (nonatomic, strong) OTRButtonView *buttonDropdownView;
@property (nonatomic, strong) OTRTitleSubtitleView *titleView;

@end

@implementation OTRMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.outgoingCellIdentifier = [OTRMessagesCollectionViewCellOutgoing cellReuseIdentifier];
    self.incomingCellIdentifier = [OTRMessagesCollectionViewCellIncoming cellReuseIdentifier];
    
    [self.collectionView registerNib:[OTRMessagesCollectionViewCellOutgoing nib] forCellWithReuseIdentifier:[OTRMessagesCollectionViewCellOutgoing cellReuseIdentifier]];
    [self.collectionView registerNib:[OTRMessagesCollectionViewCellIncoming nib] forCellWithReuseIdentifier:[OTRMessagesCollectionViewCellIncoming cellReuseIdentifier]];
    
    
    self.automaticallyScrollsToMostRecentMessage = YES;
    
     ////// bubbles //////
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory outgoingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory incomingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    ////// Lock Button //////
    [self setupLockButotn];
    
     ////// TitleView //////
    self.titleView = [[OTRTitleSubtitleView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    self.titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.navigationItem.titleView = self.titleView;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleView:)];
    [self.titleView addGestureRecognizer:tapGestureRecognizer];
    
    [self refreshTitleView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    [self.collectionView reloadData];
    
    if (self.account) {
        [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isGeneratingKey) {
            if (isGeneratingKey) {
                [self refreshLockButton];
            }
        }];
    }
    
    
    self.textViewNotificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification object:self.inputToolbar.contentView.textView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self textViewDidChangeNotifcation:note];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yapDatabaseModified:) name:OTRUIDatabaseConnectionDidUpdateNotification object:nil];
    
    void (^refreshGeneratingLock)(OTRAccount *) = ^void(OTRAccount * account) {
        
        if ([account.uniqueId isEqualToString:self.account.uniqueId]) {
            [self refreshLockButton];
        }
        
    };
    
    [[NSNotificationCenter defaultCenter] addObserverForName:OTRDidFinishGeneratingPrivateKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([note.object isKindOfClass:[OTRAccount class]]) {
            refreshGeneratingLock(note.object);
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:OTRDidFinishGeneratingPrivateKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([note.object isKindOfClass:[OTRAccount class]]) {
            refreshGeneratingLock(note.object);
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:OTRMessageStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        if ([note.object isKindOfClass:[OTRBuddy class]]) {
            OTRBuddy *notificationBuddy = note.object;
            if ([notificationBuddy.uniqueId isEqualToString:self.buddy.uniqueId]) {
                [self refreshLockButton];
            }
        }
        }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.textViewNotificationObject];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OTRUIDatabaseConnectionDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OTRMessageStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OTRDidFinishGeneratingPrivateKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OTRWillStartGeneratingPrivateKeyNotification object:nil];
}

- (YapDatabaseConnection *)databaseConnection
{
    if (!_databaseConnection)
    {
        _databaseConnection = [OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection;
        [_databaseConnection beginLongLivedReadTransaction];
    }
    return _databaseConnection;
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    if ([self.buddy.uniqueId isEqualToString:buddy.uniqueId]) {
        // really same buddy with new info like chatState, EncryptionState, Name
        
        
        _buddy = buddy;
        
        [self refreshLockButton];
        
        if (buddy.chatState == kOTRChatStateComposing || buddy.chatState == kOTRChatStatePaused) {
            self.showTypingIndicator = YES;
        }
        else {
            self.showTypingIndicator = NO;
        }
        
        [self refreshTitleView];
    }
    else {
        //different buddy
        [self saveCurrentMessageText];
        _buddy = buddy;
        
        
        if (self.buddy) {
            self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRChatDatabaseViewExtensionName];
            self.buddyMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRBuddyDatabaseViewExtensionName];
            
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                self.account = [self.buddy accountWithTransaction:transaction];
                [self.messageMappings updateWithTransaction:transaction];
                [self.buddyMappings updateWithTransaction:transaction];
            }];
            
            if ([self.account isKindOfClass:[OTRXMPPAccount class]]) {
                self.xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
            }
        }
        else {
            self.messageMappings = nil;
            self.buddyMappings = nil;
            self.account = nil;
            self.xmppManager = nil;
        }
    }
    
    
    //refresh other parts of the view
    
}

- (void)refreshTitleView
{
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
 #pragma - mark titleView Methods

- (void)didTapTitleView:(id)sender
{
    void (^showPushDropDown)(void) = ^void(void) {
        UIButton *requestPushTokenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [requestPushTokenButton setTitle:@"Request" forState:UIControlStateNormal];
        [requestPushTokenButton addTarget:self action:@selector(requestPushToken:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *revokePushTokenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [revokePushTokenButton setTitle:@"Revoke" forState:UIControlStateNormal];
        [revokePushTokenButton addTarget:self action:@selector(revokePushToken:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *sendPushTokenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [sendPushTokenButton setTitle:@"Send" forState:UIControlStateNormal];
        [sendPushTokenButton addTarget:self action:@selector(sendPushToken:) forControlEvents:UIControlEventTouchUpInside];
        
        
        [self showDropdownWithTitle:@"Push Token Actions" buttons:@[requestPushTokenButton,revokePushTokenButton,sendPushTokenButton] animated:YES tag:OTRDropDownTypePush];
    };
    
    if (!self.buttonDropdownView) {
        showPushDropDown();
    }
    else {
        if (self.buttonDropdownView.tag == OTRDropDownTypePush) {
            [self hideDropdownAnimated:YES completion:nil];
        }
        else {
            [self hideDropdownAnimated:YES completion:showPushDropDown];
        }
    }
    
}
#pragma - mark Push Methods

- (void)revokePushToken:(id)sender
{
    
}

- (void)requestPushToken:(id)sender
{
    
}

- (void)sendPushToken:(id)sender
{
    
}

#pragma - mark lockButton Methods

- (void)setupLockButotn
{
    __weak OTRMessagesViewController *welf = self;
    self.lockButton = [OTRLockButton lockButtonWithInitailLockStatus:OTRLockStatusUnlocked withBlock:^(OTRLockStatus currentStatus) {
        
        void (^showEncryptionDropDown)(void) = ^void(void) {
            
            [[OTRKit sharedInstance] messageStateForUsername:welf.buddy.username accountName:welf.account.username protocol:welf.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
                NSString *encryptionString = INITIATE_ENCRYPTED_CHAT_STRING;
                NSString *fingerprintString = VERIFY_STRING;
                NSArray * buttons = nil;
                
                if (messageState == OTRKitMessageStateEncrypted) {
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
                
                [self showDropdownWithTitle:title buttons:buttons animated:YES tag:OTRDropDownTypeEncryption];
            }];
            
            
            
        };
        if (!self.buttonDropdownView) {
            showEncryptionDropDown();
        }
        else{
            if (self.buttonDropdownView.tag == OTRDropDownTypeEncryption) {
                [self hideDropdownAnimated:YES completion:nil];
            }
            else {
                [self hideDropdownAnimated:YES completion:showEncryptionDropDown];
            }
        }
        
        
    }];
    
    
    self.lockBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.lockButton];
    [self.navigationItem setRightBarButtonItem:self.lockBarButtonItem];
}

-(void)refreshLockButton
{
    [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isGeneratingKey) {
        if( isGeneratingKey) {
            [self addLockSpinner];
        }
        else {
            UIBarButtonItem * rightBarItem = self.navigationItem.rightBarButtonItem;
            if ([rightBarItem isEqual:self.lockBarButtonItem]) {
                
                
                [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isTrusted) {
                    
                    [[OTRKit sharedInstance] hasVerifiedFingerprintsForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL hasVerifiedFingerprints) {
                        
                        [[OTRKit sharedInstance] messageStateForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
                            
                            
                            if (messageState == OTRKitMessageStateEncrypted && isTrusted) {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndVerified;
                            }
                            else if (messageState == OTRKitMessageStateEncrypted && hasVerifiedFingerprints)
                            {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndError;
                            }
                            else if (messageState == OTRKitMessageStateEncrypted) {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndWarn;
                            }
                            else {
                                self.lockButton.lockStatus = OTRLockStatusUnlocked;
                            }
                            
                        }];
                        
                    }];
                    
                }];
            }

        }
        
    }];
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

- (void)encryptionButtonPressed:(id)sender
{
    [self hideDropdownAnimated:YES completion:nil];
    
    
    [[OTRKit sharedInstance] messageStateForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
        
        if (messageState == OTRKitMessageStateEncrypted) {
            [[OTRKit sharedInstance] disableEncryptionWithUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString];
        }
        else {
            [[OTRKit sharedInstance] initiateEncryptionWithUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString];
        }
        
        
    }];
}

- (void)verifyButtonPressed:(id)sender
{
    [self hideDropdownAnimated:YES completion:nil];
    
    [[OTRKit sharedInstance] fingerprintForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(NSString *ourFingerprintString) {
        
        [[OTRKit sharedInstance] activeFingerprintForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(NSString *theirFingerprintString) {
            
            [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL verified) {
                
                
                UIAlertView * alert;
                __weak OTRMessagesViewController * welf = self;
                
                RIButtonItem * verifiedButtonItem = [RIButtonItem itemWithLabel:VERIFIED_STRING action:^{
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:welf.account.username protocol:self.account.protocolTypeString verified:YES completion:^{
                        [welf refreshLockButton];
                    }];
                }];
                
                RIButtonItem * notVerifiedButtonItem = [RIButtonItem itemWithLabel:NOT_VERIFIED_STRING action:^{
                    
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf refreshLockButton];
                    }];
                }];
                
                RIButtonItem * verifyLaterButtonItem = [RIButtonItem itemWithLabel:VERIFY_LATER_STRING action:^{
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf refreshLockButton];
                    }];
                }];
                
                if(ourFingerprintString && theirFingerprintString) {
                    NSString *msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, self.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, self.buddy.username, theirFingerprintString];
                    if(verified)
                    {
                        alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifiedButtonItem otherButtonItems:notVerifiedButtonItem, nil];
                    }
                    else
                    {
                        alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifyLaterButtonItem otherButtonItems:verifiedButtonItem, nil];
                    }
                } else {
                    NSString *msg = SECURE_CONVERSATION_STRING;
                    alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
                }
                
                [alert show];
                
            }];
            
        }];
        
    }];
    
    
    
}

#pragma - mark  dropDown Methods

- (void)showDropdownWithTitle:(NSString *)title buttons:(NSArray *)buttons animated:(BOOL)animated tag:(NSInteger)tag
{
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    self.buttonDropdownView = [[OTRButtonView alloc] initWithTitile:title buttons:buttons];
    self.buttonDropdownView.tag = tag;
    
    self.buttonDropdownView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y-44, self.view.bounds.size.width, 44);
    
    [self.view addSubview:self.buttonDropdownView];
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = self.buttonDropdownView.frame;
        frame.origin.y = self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y;
        self.buttonDropdownView.frame = frame;
    } completion:nil];
    
}
- (void)hideDropdownAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (!self.buttonDropdownView) {
        if (completion) {
            completion();
        }
    }
    else {
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
            
            if (completion) {
                completion();
            }
        }];
    }
}

- (void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.inputToolbar.contentView.textView.text;
    if(![self.buddy.composingMessageString length])
    {
        [self.xmppManager sendChatState:kOTRChatStateInactive withBuddyID:self.buddy.uniqueId];
    }
    [self finishSendingMessage];
}

- (OTRMessage *)messageAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRMessage *message = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [[transaction ext:OTRChatDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.messageMappings];
    }];
    return message;
}

- (BOOL)showDateAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL showDate = NO;
    if (indexPath.row == 0) {
        showDate = YES;
    }
    else {
        OTRMessage *currentMessage = [self messageAtIndexPath:indexPath];
        OTRMessage *previousMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row-1 inSection:indexPath.section]];
        
        NSTimeInterval timeDifference = [currentMessage.date timeIntervalSinceDate:previousMessage.date];
        if (timeDifference > kOTRMessageSentDateShowTimeInterval) {
            showDate = YES;
        }
    }
    return showDate;
}

- (void)textViewDidChangeNotifcation:(NSNotification *)notification
{
    JSQMessagesComposerTextView *textView = notification.object;
    if ([textView.text length]) {
        //typing
        [self.xmppManager sendChatState:kOTRChatStateComposing withBuddyID:self.buddy.uniqueId];
    }
    else {
        [self.xmppManager sendChatState:kOTRChatStateActive withBuddyID:self.buddy.uniqueId];
        //done typing
    }
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text sender:(NSString *)sender date:(NSDate *)date
{
    OTRMessage *message = [[OTRMessage alloc] init];
    message.buddyUniqueId = self.buddy.uniqueId;
    message.text = text;
    message.transportedSecurely = NO;
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [message saveWithTransaction:transaction];
        
    } completionBlock:^{
        [self finishSendingMessage];
        [[OTRKit sharedInstance] encodeMessage:message.text tlvs:nil username:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString tag:message];
    }];
    
    
    
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessagesCollectionViewCell *cell = (OTRMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    
    if (message.isIncoming) {
        cell.textView.textColor = [UIColor blackColor];
    }
    else {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    if ([self.account isKindOfClass:[OTRXMPPTorAccount class]]) {
        cell.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    }
    else {
        cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
    }
    
    
    
    if (message.isTransportedSecurely) {
        cell.lockImageView.image = [UIImage imageNamed:@"lock"];
    }
    else {
        cell.lockImageView.image = nil;
    }
    
    if (message.error) {
        cell.errorImageView.image = [OTRImages warningImage];
    }
    else {
        cell.errorImageView.image = nil;
    }
    
    
    return cell;
}

#pragma - mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideDropdownAnimated:YES completion:nil];
}

#pragma mark - UICollectionView DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messageMappings numberOfItemsInSection:section];
}

#pragma - mark JSQMessagesCollectionViewDataSource Methods

 ////// Required //////
- (NSString *)sender
{
    if (self.account) {
        return self.account.uniqueId;
    }
    return @"JSQDefaultSender";
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView
       messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageAtIndexPath:indexPath];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    UIImageView *imageView = nil;
    if (message.isIncoming) {
        imageView = [[UIImageView alloc] initWithImage:self.incomingBubbleImageView.image highlightedImage:self.incomingBubbleImageView.highlightedImage];
    }
    else {
        imageView = [[UIImageView alloc] initWithImage:self.outgoingBubbleImageView.image highlightedImage:self.outgoingBubbleImageView.highlightedImage];
    }
    return imageView;
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

////// Optional //////

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showDateAtIndexPath:indexPath]) {
        OTRMessage *message = [self messageAtIndexPath:indexPath];
        if ([message.date timeIntervalSinceNow] > 86400) {
            return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
        }
        else {
            return [[NSAttributedString alloc] initWithString:[[JSQMessagesTimestampFormatter sharedFormatter] timeForDate:message.date]];
        }
    }
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    NSMutableString *string = [NSMutableString string];
    
    if (message.isDelivered) {
        [string appendString:@"Delivered"];
    }
    
    NSString *finalString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([finalString length]) {
        return [[NSAttributedString alloc] initWithString:finalString];
    }
    return nil;
    
}

- (CGSize)collectionView:(JSQMessagesCollectionView *)collectionView
                  layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath: indexPath];
    CGSize size = [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    if (message.isTransportedSecurely) {
        size.height += 28.0;
    }
    
    return size;


}


#pragma - mark  JSQMessagesCollectionViewDelegateFlowLayout Methods

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showDateAtIndexPath:indexPath]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    if (message.isDelivered) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return 0.0f;
}

- (void)messagesCollectionViewCellDidTapDelete:(OTRMessagesCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    __block OTRMessage *message = [self messageAtIndexPath:indexPath];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [message removeWithTransaction:transaction];
    }];
}

/*
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
 didTapAvatarImageView:(UIImageView *)avatarImageView
           atIndexPath:(NSIndexPath *)indexPath
{
    
}


- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView
didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    
}*/

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
                                                                         withMappings:self.messageMappings];
    
    NSArray *buddyRowChanges = nil;
    [[self.databaseConnection ext:OTRBuddyDatabaseViewExtensionName] getSectionChanges:nil
                                                                            rowChanges:&buddyRowChanges
                                                                      forNotifications:notifications
                                                                          withMappings:self.buddyMappings];
    
    for (YapDatabaseViewRowChange *rowChange in buddyRowChanges)
    {
        if (rowChange.type == YapDatabaseViewChangeUpdate) {
            __block OTRBuddy *updatedBuddy = nil;
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                updatedBuddy = [[transaction ext:OTRBuddyDatabaseViewExtensionName] objectAtIndexPath:rowChange.indexPath withMappings:self.buddyMappings];
            }];
            
            if (self.buddy.chatState != updatedBuddy.chatState) {
                self.buddy = updatedBuddy;
            }
            
            
        }
    }
    
    if ([rowChanges count]) {
        [self finishReceivingMessage];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
    
}

@end
