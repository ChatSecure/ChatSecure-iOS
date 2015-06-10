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
#import "OTRLog.h"

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
#import "OTRImages.h"
#import "UIActivityViewController+ChatSecure.h"
#import "OTRUtilities.h"
#import "OTRProtocolManager.h"
#import "OTRLoginViewController.h"
#import "OTRColors.h"
#import "JSQMessagesCollectionViewCell+ChatSecure.h"
#import "NSString+FontAwesome.h"
#import "OTRAttachmentPicker.h"
#import "OTRImageItem.h"
#import "OTRVideoItem.h"
#import "OTRAudioItem.h"
#import "JTSImageViewController.h"
#import "OTRAudioControlsView.h"
#import "OTRPlayPauseProgressView.h"
#import "OTRAudioPlaybackController.h"
#import "OTRMediaFileManager.h"
#import "OTRMediaServer.h"
#import "UIImage+ChatSecure.h"

@import AVFoundation;
@import MediaPlayer;

static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;

typedef NS_ENUM(int, OTRDropDownType) {
    OTRDropDownTypeNone          = 0,
    OTRDropDownTypeEncryption    = 1,
    OTRDropDownTypePush          = 2
};

@interface OTRMessagesViewController () <UITextViewDelegate, OTRAttachmentPickerDelegate>

@property (nonatomic, strong) YapDatabaseConnection *uiDatabaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;

@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;

@property (nonatomic, weak) id databaseConnectionDidUpdateNotificationObject;
@property (nonatomic, weak) id didFinishGeneratingPrivateKeyNotificationObject;
@property (nonatomic, weak) id messageStateDidChangeNotificationObject;

@property (nonatomic ,strong) UIBarButtonItem *lockBarButtonItem;
@property (nonatomic, strong) OTRLockButton *lockButton;
@property (nonatomic, strong) OTRButtonView *buttonDropdownView;
@property (nonatomic, strong) OTRTitleSubtitleView *titleView;

@property (nonatomic, strong) OTRAttachmentPicker *attachmentPicker;
@property (nonatomic, strong) OTRAudioPlaybackController *audioPlaybackController;

@end

@implementation OTRMessagesViewController


#pragma - mark Lifecylce Methods

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyScrollsToMostRecentMessage = YES;
    
     ////// bubbles //////
    JSQMessagesBubbleImageFactory *bubbleImageFactory = [[JSQMessagesBubbleImageFactory alloc] init];
                                                         
    self.outgoingBubbleImage = [bubbleImageFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    self.incomingBubbleImage = [bubbleImageFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    
    ////// Lock Button //////
    [self setupLockButton];
    
     ////// TitleView //////
    self.titleView = [[OTRTitleSubtitleView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    self.titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.navigationItem.titleView = self.titleView;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleView:)];
    [self.titleView addGestureRecognizer:tapGestureRecognizer];
    
    [self refreshTitleView];
    
    ////// Send Button //////
    self.sendButton = [JSQMessagesToolbarButtonFactory defaultSendButtonItem];
    
    ////// Attachment Button //////
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.cameraButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFont size:20];
    self.cameraButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cameraButton setTitle:[NSString fa_stringForFontAwesomeIcon:FACamera] forState:UIControlStateNormal];
    self.cameraButton.frame = CGRectMake(0, 0, 22, 32);
    
    ////// Microphone Button //////
    self.microphoneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.microphoneButton.frame = CGRectMake(0, 0, 22, 32);
    self.microphoneButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFont size:20];
    self.microphoneButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.microphoneButton setTitle:[NSString fa_stringForFontAwesomeIcon:FAMicrophone]
          forState:UIControlStateNormal];
    
    self.audioPlaybackController = [[OTRAudioPlaybackController alloc] init];
    
    ////// TextViewUpdates //////
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTextViewChangedNotification:) name:UITextViewTextDidChangeNotification object:self.inputToolbar.contentView.textView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self updateEncryptionState];
    
    __weak typeof(self)weakSelf = self;
    
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.messageMappings updateWithTransaction:transaction];
    }];
    
    void (^refreshGeneratingLock)(OTRAccount *) = ^void(OTRAccount * account) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if ([account.uniqueId isEqualToString:strongSelf.account.uniqueId]) {
            [strongSelf updateEncryptionState];
        }
    };
    
    self.didFinishGeneratingPrivateKeyNotificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:OTRDidFinishGeneratingPrivateKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([note.object isKindOfClass:[OTRAccount class]]) {
            refreshGeneratingLock(note.object);
        }
    }];
   
    self.messageStateDidChangeNotificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:OTRMessageStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if ([note.object isKindOfClass:[OTRBuddy class]]) {
            OTRBuddy *notificationBuddy = note.object;
            if ([notificationBuddy.uniqueId isEqualToString:strongSelf.buddy.uniqueId]) {
                [strongSelf updateEncryptionState];
            }
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self saveCurrentMessageText];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.databaseConnectionDidUpdateNotificationObject];
    [[NSNotificationCenter defaultCenter] removeObserver:self.messageStateDidChangeNotificationObject];
    [[NSNotificationCenter defaultCenter] removeObserver:self.didFinishGeneratingPrivateKeyNotificationObject];
    
    [self.inputToolbar.contentView.textView resignFirstResponder];
}

#pragma - mark Database

- (YapDatabaseConnection *)uiDatabaseConnection
{
    NSAssert([NSThread isMainThread], @"Must access uiDatabaseConnection on main thread!");
    if (!_uiDatabaseConnection) {
        YapDatabase *database = [OTRDatabaseManager sharedInstance].database;
        _uiDatabaseConnection = [database newConnection];
        [_uiDatabaseConnection beginLongLivedReadTransaction];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:database];
    }
    return _uiDatabaseConnection;
}

#pragma - mark Setters & getters

- (OTRAttachmentPicker *)attachmentPicker
{
    if (!_attachmentPicker) {
        _attachmentPicker = [[OTRAttachmentPicker alloc] initWithParentViewController:self delegate:self];
    }
    return _attachmentPicker;
}

- (NSArray*) indexPathsToCount:(NSUInteger)count {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    OTRBuddy *originalBuddy = self.buddy;
    
    
    if ([originalBuddy.uniqueId isEqualToString:buddy.uniqueId]) {
        _buddy = buddy;
        
        //Update chatstate if it changed
        if (originalBuddy.chatState != self.buddy.chatState) {
            if (buddy.chatState == kOTRChatStateComposing || buddy.chatState == kOTRChatStatePaused) {
                self.showTypingIndicator = YES;
            }
            else {
                self.showTypingIndicator = NO;
            }
        }
        
        //Update title view if the status or username or display name have changed
        if (originalBuddy.status != self.buddy.status || ![originalBuddy.username isEqualToString:self.buddy.username] || ![originalBuddy.displayName isEqualToString:self.buddy.displayName]) {
            [self refreshTitleView];
        }
        
        
    } else {
        //different buddy
        [self saveCurrentMessageText];
        
        _buddy = buddy;
        if (self.buddy) {
            NSParameterAssert(self.buddy.uniqueId != nil);
            self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRChatDatabaseViewExtensionName];
            self.inputToolbar.contentView.textView.text = self.buddy.composingMessageString;

            [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                _account = [self.buddy accountWithTransaction:transaction];
                [self.messageMappings updateWithTransaction:transaction];
            }];
            
            if ([self.account isKindOfClass:[OTRXMPPAccount class]]) {
                _xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
            }
        } else {
            self.messageMappings = nil;
            _account = nil;
            _xmppManager = nil;
        }
        [self refreshTitleView];
        [self.collectionView reloadData];
    }
}

- (void)refreshTitleView
{
    if ([self.buddy.displayName length]) {
        self.titleView.titleLabel.text = self.buddy.displayName;
    }
    else {
        self.titleView.titleLabel.text = self.buddy.username;
    }
    
    if([self.account.displayName length]) {
        self.titleView.subtitleLabel.text = self.account.displayName;
    }
    else {
        self.titleView.subtitleLabel.text = self.account.username;
    }
    
    //Create big circle and the imageview will resize it down
    if (!self.buddy) {
        self.titleView.titleImageView.image = nil;
    } else {
       self.titleView.titleImageView.image = [OTRImages circleWithRadius:50 lineWidth:0 lineColor:nil fillColor:[OTRColors colorWithStatus:self.buddy.status]];
    }
    
}

- (void)showMessageError:(NSError *)error
{
    if (error) {
        RIButtonItem *okButton = [RIButtonItem itemWithLabel:OK_STRING];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:error.localizedDescription cancelButtonItem:okButton otherButtonItems:nil];
        
        [alertView show];
    }
}

#pragma - mark titleView Methods

- (void)didTapTitleView:(id)sender
{
#ifndef CHATSECURE_PUSH
    return;
#endif
    /*
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
     */
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

- (void)setupLockButton
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

-(void)updateEncryptionState
{
    if (!self.account) {
        return;
    }
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
                            
                            //Set correct lock icon and status
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
                            
                            [self setupAccessoryButtonsWithMessageState:messageState];
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
    [self updateEncryptionState];
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
                        [welf updateEncryptionState];
                    }];
                }];
                
                RIButtonItem * notVerifiedButtonItem = [RIButtonItem itemWithLabel:NOT_VERIFIED_STRING action:^{
                    
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf updateEncryptionState];
                    }];
                }];
                
                RIButtonItem * verifyLaterButtonItem = [RIButtonItem itemWithLabel:VERIFY_LATER_STRING action:^{
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf updateEncryptionState];
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

- (void)setupAccessoryButtonsWithMessageState:(OTRKitMessageState)messageState
{
    self.inputToolbar.contentView.rightBarButtonItem = self.sendButton;
    self.inputToolbar.sendButtonLocation = JSQMessagesInputSendButtonLocationRight;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
}

- (void)connectButtonPressed:(id)sender
{
    [self hideDropdownAnimated:YES completion:nil];
    
    //If we have the password then we can login with that password otherwise show login UI to enter password
    if ([self.account.password length]) {
        [[OTRProtocolManager sharedInstance] loginAccount:self.account userInitiated:YES];
        
    } else {
        [OTRLoginViewController showLoginViewControllerWithAccount:self.account fromViewController:self completion:nil];
    }
    
    
}

#pragma - mark  dropDown Methods

- (void)showDropdownWithTitle:(NSString *)title buttons:(NSArray *)buttons animated:(BOOL)animated tag:(NSInteger)tag
{
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    self.buttonDropdownView = [[OTRButtonView alloc] initWithTitle:title buttons:buttons];
    self.buttonDropdownView.tag = tag;
    
    CGFloat height = [OTRButtonView heightForTitle:title width:self.view.bounds.size.width buttons:buttons];
    
    self.buttonDropdownView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y-height, self.view.bounds.size.width, height);
    
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
    if (!self.buddy) {
        return;
    }
    self.buddy.composingMessageString = self.inputToolbar.contentView.textView.text;
    __block OTRBuddy *buddy = [self.buddy copy];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [buddy saveWithTransaction:transaction];
    }];
    
    if (![self.buddy.composingMessageString length]) {
        [self.xmppManager sendChatState:kOTRChatStateInactive withBuddyID:self.buddy.uniqueId];
    }
    
}

- (OTRMessage *)messageAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRMessage *message = nil;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:OTRChatDatabaseViewExtensionName];
        NSParameterAssert(viewTransaction != nil);
        NSParameterAssert(self.messageMappings != nil);
        NSParameterAssert(indexPath != nil);
        NSUInteger row = indexPath.row;
        NSUInteger section = indexPath.section;
        
        NSAssert(row < [self.messageMappings numberOfItemsInSection:section], @"Cannot fetch message because row %d is >= numberOfItemsInSection %d", (int)row, (int)[self.messageMappings numberOfItemsInSection:section]);
        
        message = [viewTransaction objectAtRow:row inSection:section withMappings:self.messageMappings];
        NSParameterAssert(message != nil);
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

- (void)receivedTextViewChangedNotification:(NSNotification *)notification
{
    //implemented in subclasses
    return;
}

#pragma - mark Sending Media Items

- (void)sendMediaItem:(OTRMediaItem *)mediaItem data:(NSData *)data tag:(id)tag
{
    if (data) {
        
        [[OTRProtocolManager sharedInstance].encryptionManager.dataHandler sendFileWithName:mediaItem.filename fileData:data username:self.buddy.username accountName:self.account.username protocol:kOTRProtocolTypeXMPP tag:tag];
        
    } else {
        NSURL *url = [[OTRMediaServer sharedInstance] urlForMediaItem:mediaItem buddyUniqueId:self.buddy.uniqueId];
        
        [[OTRProtocolManager sharedInstance].encryptionManager.dataHandler sendFileWithURL:url username:self.buddy.username accountName:self.account.username protocol:kOTRProtocolTypeXMPP tag:tag];
    }
    
    [mediaItem touchParentMessage];
}

#pragma - mark Media Display Methods

- (void)showImage:(OTRImageItem *)imageItem fromCollectionView:(JSQMessagesCollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    //FIXME: Possible for image to not be in cache?
    UIImage *image = [OTRImages imageWithIdentifier:imageItem.uniqueId];
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = image;
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[JSQMessagesCollectionViewCell class]]) {
        UIView *cellContainterView = ((JSQMessagesCollectionViewCell *)cell).messageBubbleContainerView;
        imageInfo.referenceRect = cellContainterView.bounds;
        imageInfo.referenceView = cellContainterView;
        imageInfo.referenceCornerRadius = 10;
    }
    
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
    
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)showVideo:(OTRVideoItem *)videoItem fromCollectionView:(JSQMessagesCollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    if (videoItem.filename) {
        NSURL *videoURL = [[OTRMediaServer sharedInstance] urlForMediaItem:videoItem buddyUniqueId:self.buddy.uniqueId];
        MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
        [self presentViewController:moviePlayerViewController animated:YES completion:nil];
    }
}

- (void)playOrPauseAudio:(OTRAudioItem *)audioItem fromCollectionView:(JSQMessagesCollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    NSError *error = nil;
    if  ([audioItem.uniqueId isEqualToString:self.audioPlaybackController.currentAudioItem.uniqueId]) {
        if  ([self.audioPlaybackController isPlaying]) {
            [self.audioPlaybackController pauseCurrentlyPlaying];
        }
        else {
            [self.audioPlaybackController resumeCurrentlyPlaying];
        }
    }
    else {
        [self.audioPlaybackController stopCurrentlyPlaying];
        OTRAudioControlsView *audioControls = [self audioControllsfromCollectionView:collectionView atIndexPath:indexPath];
        [self.audioPlaybackController attachAudioControlsView:audioControls];
        [self.audioPlaybackController playAudioItem:audioItem buddyUniqueId:self.buddy.uniqueId error:&error];
    }
    
    if (error) {
         DDLogError(@"Audio Playback Error: %@",error);
    }
   
}

- (OTRAudioControlsView *)audioControllsfromCollectionView:(JSQMessagesCollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[JSQMessagesCollectionViewCell class]]) {
        UIView *mediaView = ((JSQMessagesCollectionViewCell *)cell).mediaView;
        UIView *view = [mediaView viewWithTag:kOTRAudioControlsViewTag];
        if ([view isKindOfClass:[OTRAudioControlsView class]]) {
            return (OTRAudioControlsView *)view;
        }
    }
    
    return nil;
}


#pragma mark - JSQMessagesViewController method overrides

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    
    if (message.isIncoming) {
        cell.textView.textColor = [UIColor blackColor];
    }
    else {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    if ([message.mediaItemUniqueId isEqualToString:self.audioPlaybackController.currentAudioItem.uniqueId]) {
        UIView *view = [cell.mediaView viewWithTag:kOTRAudioControlsViewTag];
        if ([view isKindOfClass:[OTRAudioControlsView class]]) {
            [self.audioPlaybackController attachAudioControlsView:(OTRAudioControlsView *)view];
        }
    }
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(delete:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    self.navigationController.providesPresentationContextTransitionStyle = YES;
    self.navigationController.definesPresentationContext = YES;
    
    if ([[OTRProtocolManager sharedInstance] isAccountConnected:self.account]) {
        //Account is connected
        
        OTRMessage *message = [[OTRMessage alloc] init];
        message.buddyUniqueId = self.buddy.uniqueId;
        message.text = text;
        message.read = YES;
        message.transportedSecurely = NO;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [message saveWithTransaction:transaction];
            self.buddy.lastMessageDate = message.date;
            [self.buddy saveWithTransaction:transaction];
        } completionBlock:^{
            [[OTRKit sharedInstance] encodeMessage:message.text tlvs:nil username:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString tag:message];
        }];
        
    } else {
        //Account is not currently connected
        [self hideDropdownAnimated:YES completion:^{
            UIButton *okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [okButton setTitle:CONNECT_STRING forState:UIControlStateNormal];
            [okButton addTarget:self action:@selector(connectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            
            [self showDropdownWithTitle:YOU_ARE_NOT_CONNECTED_STRING buttons:@[okButton] animated:YES tag:0];
        }];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    if ([sender isEqual:self.cameraButton]) {
        [self.attachmentPicker showAlertControllerWithCompletion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(delete:)) {
        [self deleteMessageAtIndexPath:indexPath];
    }
    else {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

#pragma - mark UIPopoverPresentationControllerDelegate Methods

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    // Without setting this, there will be a crash on iPad
    // This delegate is set in the OTRAttachmentPicker
    popoverPresentationController.sourceView = self.cameraButton;
}

#pragma - mark OTRAttachmentPickerDelegate Methods

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    if (photo) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            
            CGFloat scaleFactor = 0.25;
            CGSize newSize = CGSizeMake(photo.size.width * scaleFactor, photo.size.height * scaleFactor);
            UIImage *scaledImage = [UIImage otr_imageWithImage:photo scaledToSize:newSize];
            
            __block NSData *imageData = UIImageJPEGRepresentation(scaledImage, 0.5);
            
            NSString *UUID = [[NSUUID UUID] UUIDString];
            
            __block OTRImageItem *imageItem  = [[OTRImageItem alloc] init];
            imageItem.width = photo.size.width;
            imageItem.height = photo.size.height;
            imageItem.isIncoming = NO;
            imageItem.filename = [UUID stringByAppendingPathExtension:@"jpg"];
            
            __block OTRMessage *message = [[OTRMessage alloc] init];
            message.read = YES;
            message.incoming = NO;
            message.buddyUniqueId = self.buddy.uniqueId;
            message.mediaItemUniqueId = imageItem.uniqueId;
            message.transportedSecurely = YES;
            
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [message saveWithTransaction:transaction];
                [imageItem saveWithTransaction:transaction];
            } completionBlock:^{
                [[OTRMediaFileManager sharedInstance] setData:imageData forItem:imageItem buddyUniqueId:self.buddy.uniqueId completion:^(NSInteger bytesWritten, NSError *error) {
                    [imageItem touchParentMessage];
                    if (error) {
                        message.error = error;
                        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                            [message saveWithTransaction:transaction];
                        }];
                    }
                    [self sendMediaItem:imageItem data:imageData tag:message];
                    
                } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
            }];
        });
    }
}

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotVideoURL:(NSURL *)videoURL
{
    __block OTRVideoItem *videoItem = [OTRVideoItem videoItemWithFileURL:videoURL];
    
    __block OTRMessage *message = [[OTRMessage alloc] init];
    message.read = YES;
    message.incoming = NO;
    message.mediaItemUniqueId = videoItem.uniqueId;
    message.buddyUniqueId = self.buddy.uniqueId;
    message.transportedSecurely = YES;
    
    NSString *newPath = [OTRMediaFileManager pathForMediaItem:videoItem buddyUniqueId:self.buddy.uniqueId];
    [[OTRMediaFileManager sharedInstance] copyDataFromFilePath:videoURL.path toEncryptedPath:newPath completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoURL.path]) {
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:videoURL.path error:&err];
            if (err) {
                DDLogError(@"Error Removing Video File");
            }
            
        }
        
        message.error = error;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [videoItem saveWithTransaction:transaction];
            [message saveWithTransaction:transaction];
        }];
        
        [self sendMediaItem:videoItem data:nil tag:message];
        
    }];
}

- (void)sendAudioFileURL:(NSURL *)url
{
    __block OTRMessage *message = [[OTRMessage alloc] init];
    message.read = YES;
    message.incoming = NO;
    message.buddyUniqueId = self.buddy.uniqueId;
    
    __block OTRAudioItem *audioItem = [[OTRAudioItem alloc] init];
    audioItem.isIncoming = message.incoming;
    audioItem.filename = [[url absoluteString] lastPathComponent];
    
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:url];
    audioItem.timeLength = CMTimeGetSeconds(audioAsset.duration);
    
    message.mediaItemUniqueId = audioItem.uniqueId;
    
    NSString *newPath = [OTRMediaFileManager pathForMediaItem:audioItem buddyUniqueId:self.buddy.uniqueId];
    
    [[OTRMediaFileManager sharedInstance] copyDataFromFilePath:url.path toEncryptedPath:newPath completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:url.path error:&err];
            if (err) {
                DDLogError(@"Error Removing Audio File");
            }
        }
        
        message.error = error;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [message saveWithTransaction:transaction];
            [audioItem saveWithTransaction:transaction];
        }];
        
        [self sendMediaItem:audioItem data:nil tag:message];        
    }];
}

#pragma - mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideDropdownAnimated:YES completion:nil];
}

#pragma mark - UICollectionView DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfMessages = [self.messageMappings numberOfItemsInSection:section];
    return numberOfMessages;
}

#pragma - mark JSQMessagesCollectionViewDataSource Methods

- (NSString *)senderDisplayName
{
    NSString *senderDisplayName = nil;
    if (self.account) {
        if ([self.account.displayName length]) {
            senderDisplayName = self.account.displayName;
        } else {
            senderDisplayName = self.account.username;
        }
    } else {
        senderDisplayName = @"";
    }
    
    return senderDisplayName;
}

- (NSString *)senderId
{
    NSString *senderId = nil;
    if (self.account) {
        senderId = self.account.uniqueId;
    } else {
        senderId = @"";
    }
    return senderId;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    JSQMessagesBubbleImage *image = nil;
    if (message.isIncoming) {
        image = self.incomingBubbleImage;
    }
    else {
        image = self.outgoingBubbleImage;
    }
    return image;
}

- (id <JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    UIImage *avatarImage = nil;
    if (message.error) {
        avatarImage = [OTRImages circleWarningWithColor:[OTRColors warnColor]];
    }
    else if (message.isIncoming) {
        avatarImage = [self.buddy avatarImage];
    }
    else {
        avatarImage = [self.account avatarImage];
    }
    
    if (avatarImage) {
        NSUInteger diameter = MIN(avatarImage.size.width, avatarImage.size.height);
        return [JSQMessagesAvatarImageFactory avatarImageWithImage:avatarImage diameter:diameter];
    }
    return nil;
}

////// Optional //////

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showDateAtIndexPath:indexPath]) {
        OTRMessage *message = [self messageAtIndexPath:indexPath];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
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
    
    UIFont *font = [UIFont fontWithName:kFontAwesomeFont size:12];
    NSDictionary *iconAttributes = @{NSFontAttributeName: font};
    
    
    ////// Lock Icon //////
    NSString *lockString = nil;
    if (message.transportedSecurely) {
        lockString = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FALock]];
    }
    else {
        lockString = [NSString fa_stringForFontAwesomeIcon:FAUnlock];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:lockString attributes:iconAttributes];
    
    ////// Delivered Icon //////
    if (message.isDelivered) {
        NSString *iconString = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheck]];
        
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:iconString attributes:iconAttributes]];
    }
    else if([message isMediaMessage]) {
        
        __block OTRMediaItem *mediaItem = nil;
        //Get the media item
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            mediaItem = [OTRMediaItem fetchObjectWithUniqueID:message.mediaItemUniqueId transaction:transaction];
        }];
        
        float percentProgress = mediaItem.transferProgress * 100;
        
        NSString *progressString = nil;
        NSUInteger insertIndex = 0;
        
        if (mediaItem.isIncoming && mediaItem.transferProgress < 1) {
            progressString = [NSString stringWithFormat:@" %@ %.0f%%",INCOMING_STRING,percentProgress];
            insertIndex = [attributedString length];
        } else if (!mediaItem.isIncoming) {
            if(percentProgress > 0) {
                progressString = [NSString stringWithFormat:@"%@ %.0f%% ",SENDING_STRING,percentProgress];
            } else {
                progressString = [NSString stringWithFormat:@"%@ ",WAITING_STRING];
            }
        }
        
        if ([progressString length]) {
            UIFont *font = [UIFont systemFontOfSize:12];
            [attributedString insertAttributedString:[[NSAttributedString alloc] initWithString:progressString attributes:@{NSFontAttributeName: font}] atIndex:insertIndex];
        }
        
        
    }
    
    
    return attributedString;
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
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRMessage *message = [self messageAtIndexPath:indexPath];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [message removeWithTransaction:transaction];
        //Update Last message date for sorting and grouping
        [self.buddy updateLastMessageDateWithTransaction:transaction];
        [self.buddy saveWithTransaction:transaction];
    }];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    if (message.error) {
        [self showMessageError:message.error];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    OTRMessage *message = [self messageAtIndexPath:indexPath];
    if ([message isMediaMessage]) {
        __block OTRMediaItem *item = nil;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
             item = [OTRImageItem fetchObjectWithUniqueID:message.mediaItemUniqueId transaction:transaction];
        } completionBlock:^{
            if ([item isKindOfClass:[OTRImageItem class]]) {
                [self showImage:(OTRImageItem *)item fromCollectionView:collectionView atIndexPath:indexPath];
            }
            else if ([item isKindOfClass:[OTRVideoItem class]]) {
                [self showVideo:(OTRVideoItem *)item fromCollectionView:collectionView atIndexPath:indexPath];
            }
            else if ([item isKindOfClass:[OTRAudioItem class]]) {
                [self playOrPauseAudio:(OTRAudioItem *)item fromCollectionView:collectionView atIndexPath:indexPath];
            }
        }];
    }
}

#pragma mark - YapDatabaseNotificatino Method

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = [self.uiDatabaseConnection beginLongLivedReadTransaction];
    
    //TODO check if the view is not visible
    // If the view isn't visible, we might decide to skip the UI animation stuff.
//    if ([self viewIsNotVisible])
//    {
//        // Since we moved our databaseConnection to a new commit,
//        // we need to update the mappings too.
//        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
//            [self.messageMappings updateWithTransaction:transaction];
//        }];
//        return;
//    }
    
    NSArray *messageRowChanges = nil;
    
    [[self.uiDatabaseConnection ext:OTRChatDatabaseViewExtensionName] getSectionChanges:nil
                                                                           rowChanges:&messageRowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.messageMappings];
    
    
    BOOL buddyChanged = [self.uiDatabaseConnection hasChangeForKey:self.buddy.uniqueId inCollection:[OTRBuddy collection] inNotifications:notifications];
    if (buddyChanged)
    {
        __block OTRBuddy *updatedBuddy = nil;
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            updatedBuddy = [OTRBuddy fetchObjectWithUniqueID:self.buddy.uniqueId transaction:transaction];
        }];
        self.buddy = updatedBuddy;
    }
    
    // When deleting messages/buddies we shouldn't animate the changes
    if (!self.buddy) {
        [self.collectionView reloadData];
        return;
    }
    
    //Changes in the messages add new one or deleted some
    if (messageRowChanges.count) {
        NSUInteger collectionViewNumberOfItems = [self.collectionView numberOfItemsInSection:0];
        NSUInteger numberMappingsItems = [self.messageMappings numberOfItemsInSection:0];
        
        
        if(numberMappingsItems > collectionViewNumberOfItems && numberMappingsItems > 0) {
            //Inserted new item, probably at the end
            //Get last message and test if isIncoming
            NSIndexPath *lastMessageIndexPath = [NSIndexPath indexPathForRow:numberMappingsItems - 1 inSection:0];
            OTRMessage *lastMessage = [self messageAtIndexPath:lastMessageIndexPath];
            if (lastMessage.isIncoming) {
                [self finishReceivingMessage];
            } else {
                [self finishSendingMessage];
            }
        } else {
            //deleted a message or message updated
            [self.collectionView performBatchUpdates:^{
                
                for (YapDatabaseViewRowChange *rowChange in messageRowChanges)
                {
                    switch (rowChange.type)
                    {
                        case YapDatabaseViewChangeDelete :
                        {
                            [self.collectionView deleteItemsAtIndexPaths:@[rowChange.indexPath]];
                            break;
                        }
                        case YapDatabaseViewChangeInsert :
                        {
                            [self.collectionView insertItemsAtIndexPaths:@[ rowChange.newIndexPath ]];
                            break;
                        }
                        case YapDatabaseViewChangeMove :
                        {
                            [self.collectionView moveItemAtIndexPath:rowChange.indexPath toIndexPath:rowChange.newIndexPath];
                            break;
                        }
                        case YapDatabaseViewChangeUpdate :
                        {
                            [self.collectionView reloadItemsAtIndexPaths:@[ rowChange.indexPath]];
                            break;
                        }
                    }
                }
            } completion:nil];
        }
    }
}

#pragma mark UISplitViewControllerDelegate methods

- (void) splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    barButtonItem.title = aViewController.title;
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void) splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    self.navigationItem.leftBarButtonItem = nil;
}

#pragma - mark UITextViewDelegateMethods

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    UIActivityViewController *activityViewController = [UIActivityViewController otr_linkActivityViewControllerWithURLs:@[URL]];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityViewController.popoverPresentationController.sourceView = textView;
        activityViewController.popoverPresentationController.sourceRect = textView.bounds;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return NO;
}

@end
