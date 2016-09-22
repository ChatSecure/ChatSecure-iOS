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
@import OTRAssets;
#import "OTRTitleSubtitleView.h"
@import OTRKit;
#import "OTRImages.h"
#import "UIActivityViewController+ChatSecure.h"
#import "OTRUtilities.h"
#import "OTRProtocolManager.h"
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
#import "OTRBaseLoginViewController.h"
#import "OTRLanguageManager.h"
#import "OTRDataHandler.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import YapDatabase.YapDatabaseView;
@import PureLayout;

@import AVFoundation;
@import MediaPlayer;

static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;

typedef NS_ENUM(int, OTRDropDownType) {
    OTRDropDownTypeNone          = 0,
    OTRDropDownTypeEncryption    = 1,
    OTRDropDownTypePush          = 2
};

@interface OTRMessagesViewController () <UITextViewDelegate, OTRAttachmentPickerDelegate, OTRYapViewHandlerDelegateProtocol, OTRMessagesCollectionViewFlowLayoutSizeProtocol>

@property (nonatomic, strong) OTRYapViewHandler *viewHandler;

@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;

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

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.senderId = @"";
        self.senderDisplayName = @"";
        _state = [[MessagesViewControllerState alloc] init];
    }
    return self;
}

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
    
    /** Setup databse view handler*/
    YapDatabaseConnection *connection = [self.databaseConnection.database newConnection];
    self.viewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:connection];
    self.viewHandler.delegate = self;
    
    ///Custom Layout to account for no bubble cells
    OTRMessagesCollectionViewFlowLayout *layout = [[OTRMessagesCollectionViewFlowLayout alloc] init];
    layout.sizeDelegate = self;
    self.collectionView.collectionViewLayout = layout;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
    __weak typeof(self)weakSelf = self;
    
    void (^refreshGeneratingLock)(OTRAccount *) = ^void(OTRAccount * account) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSString *accountKey = [strongSelf buddy].accountUniqueId;
        if ([account.uniqueId isEqualToString:accountKey]) {
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
    
    if ([self.threadKey length]) {
        [self.viewHandler.keyCollectionObserver observe:self.threadKey collection:self.threadCollection];
        [self updateViewWithKey:self.threadKey colleciton:self.threadCollection];
        [self.viewHandler setup:OTRChatDatabaseViewExtensionName groups:@[self.threadKey]];
        if(![self.inputToolbar.contentView.textView.text length]) {
            [self moveLastComposingTextForThreadKey:self.threadKey colleciton:self.threadCollection toTextView:self.inputToolbar.contentView.textView];
        }
    }
    
    
    [self.collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self saveCurrentMessageText:self.inputToolbar.contentView.textView.text threadKey:self.threadKey colleciton:self.threadCollection];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.messageStateDidChangeNotificationObject];
    [[NSNotificationCenter defaultCenter] removeObserver:self.didFinishGeneratingPrivateKeyNotificationObject];
    
    [self.inputToolbar.contentView.textView resignFirstResponder];
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

- (id<OTRThreadOwner>)threadObject {
    __block id <OTRThreadOwner> object = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        object = [transaction objectForKey:self.threadKey inCollection:self.threadCollection];
    }];
    return object;
}

- (OTRBuddy *)buddy {
    id <OTRThreadOwner> object = [self threadObject];
    if ([object isKindOfClass:[OTRBuddy class]]) {
        return (OTRBuddy *)object;
    }
    return nil;
}

- (OTRAccount *)account {
    __block OTRAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        id <OTRThreadOwner> thread =  [transaction objectForKey:self.threadKey inCollection:self.threadCollection];
        account = [OTRAccount fetchObjectWithUniqueID:[thread threadAccountIdentifier] transaction:transaction];
    }];
    
    return account;
}

- (void)setThreadKey:(NSString *)key collection:(NSString *)collection
{
    NSString *oldKey = self.threadKey;
    NSString *oldCollection = self.threadCollection;
    
    self.threadKey = key;
    self.threadCollection = collection;
    self.senderId = [self.threadObject threadAccountIdentifier];
    
    if (![oldKey isEqualToString:key] || ![oldCollection isEqualToString:collection]) {
        [self saveCurrentMessageText:self.inputToolbar.contentView.textView.text threadKey:oldKey colleciton:oldCollection];
    }
    
    [self.viewHandler.keyCollectionObserver stopObserving:oldKey collection:oldCollection];
    [self.viewHandler.keyCollectionObserver observe:self.threadKey collection:self.threadCollection];
    [self updateViewWithKey:self.threadKey colleciton:self.threadCollection];
    [self.viewHandler setup:OTRChatDatabaseViewExtensionName groups:@[self.threadKey]];
    [self moveLastComposingTextForThreadKey:self.threadKey colleciton:self.threadCollection toTextView:self.inputToolbar.contentView.textView];
    [self.collectionView reloadData];
}

- (YapDatabaseConnection *)databaseConnection
{
    if (!_databaseConnection) {
        _databaseConnection = [[OTRDatabaseManager sharedInstance].database newConnection];
    }
    return _databaseConnection;
}

- (OTRXMPPManager *)xmppManager {
    OTRAccount *account = [self account];
    return (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
}

- (void)updateViewWithKey:(NSString *)key colleciton:(NSString *)collection
{
    if ([collection isEqualToString:[OTRBuddy collection]]) {
        __block OTRBuddy *buddy = nil;
        __block OTRAccount *account = nil;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            buddy = [OTRBuddy fetchObjectWithUniqueID:key transaction:transaction];
            account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
        }];
        
        
        
        //Update UI now
        if (buddy.chatState == kOTRChatStateComposing || buddy.chatState == kOTRChatStatePaused) {
            self.showTypingIndicator = YES;
        }
        else {
            self.showTypingIndicator = NO;
        }
        
        // Update Buddy Status
        BOOL previousState = self.state.isThreadOnline;
        self.state.isThreadOnline = buddy.status != OTRThreadStatusOffline;
        
        // Auto-inititate OTR when contact comes online
        if (!previousState && self.state.isThreadOnline) {
            [[OTRProtocolManager sharedInstance].encryptionManager maybeRefreshOTRSessionForBuddyKey:key collection:collection];
        }
        [self didUpdateState];
        
        //Update Buddy knock status
        //Async because this calls down to the database and iterates over a relation. Might slowdown the UI if on main thread
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __typeof__(self) strongSelf = weakSelf;
            __block BOOL canKnock = [[[OTRAppDelegate appDelegate].pushController pushStorage] numberOfTokensForBuddy:buddy.uniqueId createdByThisAccount:NO] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (canKnock != strongSelf.state.canKnock) {
                    strongSelf.state.canKnock = canKnock;
                    [strongSelf didUpdateState];
                }
            });
            
        });
        
        [self refreshTitleView];
    }
    
    // Set all messages as read
    id <OTRThreadOwner>threadOwner = [self threadObject];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [threadOwner setAllMessagesAsReadInTransaction:transaction];
    }];
}

- (void)refreshTitleView
{
    id<OTRThreadOwner> thread = [self threadObject];
    OTRAccount *account = [self account];
    self.titleView.titleLabel.text = [thread threadName];
    
    if([self.account.displayName length]) {
        self.titleView.subtitleLabel.text = account.displayName;
    }
    else {
        self.titleView.subtitleLabel.text = account.username;
    }
    
    //Create big circle and the imageview will resize it down
    if (!self.buddy) {
        self.titleView.titleImageView.image = nil;
    } else {
       self.titleView.titleImageView.image = [OTRImages circleWithRadius:50 lineWidth:0 lineColor:nil fillColor:[OTRColors colorWithStatus:[thread currentStatus]]];
    }
    
}

- (void)showMessageError:(NSError *)error
{
    if (error) {
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:nil];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ERROR_STRING message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:okButton];
        [self presentViewController:alertController animated:YES completion:nil];
    }
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
    
    [self.navigationItem setRightBarButtonItem:[self rightBarButtonItem]];
}

- (UIBarButtonItem *)rightBarButtonItem
{
    if (!self.lockBarButtonItem) {
        self.lockBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.lockButton];
    }
    return self.lockBarButtonItem;
}

-(void)updateEncryptionState
{
    if (!self.account || !self.rightBarButtonItem) {
        return;
    }
    [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isGeneratingKey) {
        if( isGeneratingKey) {
            [self addLockSpinner];
        }
        else {
            UIBarButtonItem * rightBarItem = self.navigationItem.rightBarButtonItem;
            if ([rightBarItem isEqual:self.lockBarButtonItem]) {
                
                [[OTRProtocolManager sharedInstance].encryptionManager currentEncryptionState:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isTrusted, BOOL hasVerifiedFingerprints, OTRKitMessageState messageState) {
                    
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
                    
                    self.state.isEncrypted = messageState == OTRKitMessageStateEncrypted;
                    [self didUpdateState];
                    
                } completionQueue:nil];
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
                
                
                UIAlertController * alert = nil;
                
                UIAlertAction * verifiedButtonItem = [UIAlertAction actionWithTitle:VERIFIED_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:YES completion:^{
                        [self updateEncryptionState];
                    }];
                }];
                
                UIAlertAction * notVerifiedButtonItem = [UIAlertAction actionWithTitle:NOT_VERIFIED_STRING style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [self updateEncryptionState];
                    }];
                }];
                
                UIAlertAction * verifyLaterButtonItem = [UIAlertAction actionWithTitle:VERIFY_LATER_STRING style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [self updateEncryptionState];
                    }];
                }];
                
                if(ourFingerprintString && theirFingerprintString) {
                    NSString *msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, self.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, self.buddy.username, theirFingerprintString];
                    alert = [UIAlertController alertControllerWithTitle:VERIFY_FINGERPRINT_STRING message:msg preferredStyle:UIAlertControllerStyleAlert];

                    if(verified)
                    {
                        [alert addAction:verifiedButtonItem];
                        [alert addAction:notVerifiedButtonItem];
                    }
                    else
                    {
                        [alert addAction:verifyLaterButtonItem];
                        [alert addAction:verifiedButtonItem];
                    }
                } else {
                    alert = [UIAlertController alertControllerWithTitle:nil message:SECURE_CONVERSATION_STRING preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:ok];
                }
                
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }];
    }];
}

- (void)setupAccessoryButtonsWithMessageState:(OTRKitMessageState)messageState buddyStatus:(OTRThreadStatus)status textViewHasText:(BOOL)hasText
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
        OTRBaseLoginViewController *loginViewController = [OTRBaseLoginViewController loginViewControllerForAccount:self.account];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nav animated:YES completion:nil];
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
    
    [self.view addSubview:self.buttonDropdownView];
    
    [self.buttonDropdownView autoSetDimension:ALDimensionHeight toSize:height];
    [self.buttonDropdownView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.buttonDropdownView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    self.buttonDropdownView.topLayoutConstraint = [self.buttonDropdownView autoPinToTopLayoutGuideOfViewController:self withInset:height*-1];
    
    [self.buttonDropdownView layoutIfNeeded];
    
    [UIView animateWithDuration:duration animations:^{
        self.buttonDropdownView.topLayoutConstraint.constant = 0.0;
        [self.buttonDropdownView layoutIfNeeded];
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
            CGFloat height = self.buttonDropdownView.frame.size.height;
            self.buttonDropdownView.topLayoutConstraint.constant = height*-1;
            [self.buttonDropdownView layoutIfNeeded];
            
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

- (void)saveCurrentMessageText:(NSString *)text threadKey:(NSString *)key colleciton:(NSString *)collection
{
    if (![key length] || ![collection length]) {
        return;
    }
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        id <OTRThreadOwner> thread = [[transaction objectForKey:key inCollection:collection] copy];
        [thread setCurrentMessageText:text];
        [transaction setObject:thread forKey:key inCollection:collection];
        
        //Send inactive chat State
        OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:[thread threadAccountIdentifier] transaction:transaction];
        OTRXMPPManager *xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
        if (![text length]) {
            [xmppManager sendChatState:kOTRChatStateInactive withBuddyID:[thread threadAccountIdentifier]];
        }
    }];
}

//* Takes the current value out of the thread object and sets it to the text view and nils out result*/
- (void)moveLastComposingTextForThreadKey:(NSString *)key colleciton:(NSString *)collection toTextView:(UITextView *)textView {
    
    if (![key length] || ![collection length] || !textView) {
        return;
    }
    
    __block NSString *text = nil;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        id <OTRThreadOwner> thread = [[transaction objectForKey:key inCollection:collection] copy];
        text = [thread currentMessageText];
        [thread setCurrentMessageText:nil];
        [transaction setObject:thread forKey:key inCollection:collection];
    } completionQueue:dispatch_get_main_queue() completionBlock:^{
        textView.text = text;
        [self receivedTextViewChanged:textView];
    }];
}

- (id <OTRMessageProtocol,JSQMessageData>)messageAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewHandler object:indexPath];
}

- (BOOL)showDateAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL showDate = NO;
    if (indexPath.row == 0) {
        showDate = YES;
    }
    else {
        id <OTRMessageProtocol> currentMessage = [self messageAtIndexPath:indexPath];
        id <OTRMessageProtocol> previousMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row-1 inSection:indexPath.section]];
        
        NSTimeInterval timeDifference = [[currentMessage date] timeIntervalSinceDate:[previousMessage date]];
        if (timeDifference > kOTRMessageSentDateShowTimeInterval) {
            showDate = YES;
        }
    }
    return showDate;
}

- (BOOL)showSenderDisplayNameAtIndexPath:(NSIndexPath *)indexPath {
    id<OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    
    if(![self.threadCollection isEqualToString:[OTRXMPPRoom collection]]) {
        return NO;
    }
    
    if ([[message senderId] isEqualToString:self.senderId]) {
        return NO;
    }
    
    if(indexPath.row -1 >= 0) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        id<OTRMessageProtocol,JSQMessageData> previousMessage = [self messageAtIndexPath:previousIndexPath];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isPushMessageAtIndexPath:(NSIndexPath *)indexPath {
    id message = [self messageAtIndexPath:indexPath];
    return [message isKindOfClass:[PushMessage class]];
}

- (void)receivedTextViewChangedNotification:(NSNotification *)notification
{
    //Check if the text state changes from having some text to some or vice versa
    UITextView *textView = notification.object;
    [self receivedTextViewChanged:textView];
}

- (void)receivedTextViewChanged:(UITextView *)textView {
    BOOL hasText = [textView.text length] > 0;
    if(hasText != self.state.hasText) {
        self.state.hasText = hasText;
        [self didUpdateState];
    }
    
    //Everytime the textview has text and a notification comes through we are 'typing' otherwise we are done typing
    if (hasText) {
        [self isTyping];
    } else {
        [self didFinishTyping];
    }
    
    return;

}

#pragma - mark Update UI

- (void)didUpdateState {
    
}

- (void)isTyping {
    
}

- (void)didFinishTyping {
    
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

#pragma MARK - OTRMessagesCollectionViewFlowLayoutSizeProtocol methods

- (BOOL)hasBubbleSizeForCellAtIndexPath:(NSIndexPath *)indexPath {
    return ![self isPushMessageAtIndexPath:indexPath];
}

#pragma mark - JSQMessagesViewController method overrides

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    //Fixes times when there needs to be two lines (date & knock sent) and doesn't seem to affect one line instances
    cell.cellTopLabel.numberOfLines = 0;
    
    id <OTRMessageProtocol>message = [self messageAtIndexPath:indexPath];
    
    UIColor *textColor = nil;
    if ([message messageIncoming]) {
        textColor = [UIColor blackColor];
    }
    else {
        textColor = [UIColor whiteColor];
    }
    if (cell.textView != nil)
        cell.textView.textColor = textColor;

	// Do not allow clickable links for Tor accounts to prevent information leakage
    if ([self.account isKindOfClass:[OTRXMPPTorAccount class]]) {
        cell.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    }
    else {
        cell.textView.dataDetectorTypes = UIDataDetectorTypeLink;
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    if ([[message messageMediaItemKey] isEqualToString:self.audioPlaybackController.currentAudioItem.uniqueId]) {
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
        
        __block OTRMessage *message = [[OTRMessage alloc] init];
        message.buddyUniqueId = self.threadKey;
        message.text = text;
        message.read = YES;
        message.transportedSecurely = NO;
        
        __weak __typeof__(self) weakSelf = self;
        [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            __typeof__(self) strongSelf = weakSelf;
            [message saveWithTransaction:transaction];
            OTRBuddy *buddy = [[OTRBuddy fetchObjectWithUniqueID:strongSelf.threadKey transaction:transaction] copy];
            buddy.composingMessageString = nil;
            buddy.lastMessageDate = message.date;
            [buddy saveWithTransaction:transaction];
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

- (void)sendPhoto:(UIImage *)photo asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize {
    if (photo) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            
            CGFloat scaleFactor = 0.25;
            CGSize newSize = CGSizeMake(photo.size.width * scaleFactor, photo.size.height * scaleFactor);
            UIImage *scaledImage = shouldResize ? [UIImage otr_imageWithImage:photo scaledToSize:newSize] : photo;
            
            __block NSData *imageData = nil;
            if (!asJPEG) {
                imageData = UIImagePNGRepresentation(scaledImage);
            } else {
                imageData = UIImageJPEGRepresentation(scaledImage, 0.5);
            }
            NSString *UUID = [[NSUUID UUID] UUIDString];
            
            __block OTRImageItem *imageItem  = [[OTRImageItem alloc] init];
            imageItem.width = photo.size.width;
            imageItem.height = photo.size.height;
            imageItem.isIncoming = NO;
            imageItem.filename = [UUID stringByAppendingPathExtension:(asJPEG ? @"jpg" : @"png")];
            
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

#pragma - mark OTRAttachmentPickerDelegate Methods

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    [self sendPhoto:photo asJPEG:YES shouldResize:YES];
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
        
        NSData *data = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil][NSFileSize] longLongValue];
            if (fileSize < 1024 * 1024 * 1) {
                // Smaller than 1Mb
                data = [NSData dataWithContentsOfFile:url.path];
            }
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
        
        [self sendMediaItem:audioItem data:data tag:message];
    }];
}

- (void)sendImageFilePath:(NSString *)filePath asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize
{
    [self sendPhoto:[UIImage imageWithContentsOfFile:filePath] asJPEG:asJPEG shouldResize:shouldResize];
}


#pragma - mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideDropdownAnimated:YES completion:nil];
}

#pragma mark - UICollectionView DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfMessages = [self.viewHandler.mappings numberOfItemsInSection:section];
    return numberOfMessages;
}

#pragma - mark JSQMessagesCollectionViewDataSource Methods

- (NSString *)senderDisplayName
{
    NSString *senderDisplayName = @"";
    if (self.account) {
        if ([self.account.displayName length]) {
            senderDisplayName = self.account.displayName;
        } else {
            senderDisplayName = self.account.username;
        }
    }
    
    return senderDisplayName;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (id <JSQMessageData>)[self messageAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol> message = [self messageAtIndexPath:indexPath];
    JSQMessagesBubbleImage *image = nil;
    if ([message messageIncoming]) {
        image = self.incomingBubbleImage;
    }
    else {
        image = self.outgoingBubbleImage;
    }
    return image;
}

- (id <JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol> message = [self messageAtIndexPath:indexPath];
    if ([message isKindOfClass:[PushMessage class]]) {
        return nil;
    }
    
    UIImage *avatarImage = nil;
    if ([message messageError]) {
        avatarImage = [OTRImages circleWarningWithColor:[OTRColors warnColor]];
    }
    else if ([message messageIncoming]) {
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
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    
    if ([self showDateAtIndexPath:indexPath]) {
        id <OTRMessageProtocol> message = [self messageAtIndexPath:indexPath];
        NSDate *date = [message date];
        if (date != nil) {
            [text appendAttributedString: [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:date]];
        }
    }
    
    if ([self isPushMessageAtIndexPath:indexPath]) {
        JSQMessagesTimestampFormatter *formatter = [JSQMessagesTimestampFormatter sharedFormatter];
        NSString *knockString = KNOCK_SENT_STRING;
        //Add new line if there is already a date string
        if ([text length] > 0) {
            knockString = [@"\n" stringByAppendingString:knockString];
        }
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:knockString attributes:formatter.dateTextAttributes]];
    }
    
    return text;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showSenderDisplayNameAtIndexPath:indexPath]) {
        id<OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
        NSString *displayName = [message senderDisplayName];
        return [[NSAttributedString alloc] initWithString:displayName];
    }
    
    return  nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol> message = [self messageAtIndexPath:indexPath];
    
    UIFont *font = [UIFont fontWithName:kFontAwesomeFont size:12];
    if (!font) {
        font = [UIFont systemFontOfSize:12];
    }
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
    if([message isKindOfClass:[OTRMessage class]]) {
        OTRMessage *msg = (OTRMessage *)message;
        if (msg.isDelivered) {
            NSString *iconString = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheck]];
            
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:iconString attributes:iconAttributes]];
        }
        
        if([msg isMediaMessage]) {
            
            __block OTRMediaItem *mediaItem = nil;
            //Get the media item
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                mediaItem = [OTRMediaItem fetchObjectWithUniqueID:msg.mediaItemUniqueId transaction:transaction];
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
    }
    
    
    
    return attributedString;
}


#pragma - mark  JSQMessagesCollectionViewDelegateFlowLayout Methods

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0f;
    if ([self showDateAtIndexPath:indexPath]) {
        height += kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    if ([self isPushMessageAtIndexPath:indexPath]) {
        height += kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return height;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showSenderDisplayNameAtIndexPath:indexPath]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kJSQMessagesCollectionViewCellLabelHeightDefault;
    if ([self isPushMessageAtIndexPath:indexPath]) {
        height = 0.0f;
    }
    return height;
}

- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    __block id <OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:[message messageKey] inCollection:[message messageCollection]];
        //Update Last message date for sorting and grouping
        [self.buddy updateLastMessageDateWithTransaction:transaction];
        [self.buddy saveWithTransaction:transaction];
    }];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    if ([message messageError]) {
        [self showMessageError:[message messageError]];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    if ([message isMediaMessage]) {
        __block OTRMediaItem *item = nil;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
             item = [OTRImageItem fetchObjectWithUniqueID:[message messageMediaItemKey] transaction:transaction];
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

#pragma - mark database view delegate

- (void)didSetupMappings:(OTRYapViewHandler *)handler
{
    // The databse view is setup now so refresh from there
    [self updateViewWithKey:self.threadKey colleciton:self.threadCollection];
    [self.collectionView reloadData];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler key:(NSString *)key collection:(NSString *)collection
{
    [self updateViewWithKey:key colleciton:collection];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if (rowChanges.count) {
        NSUInteger collectionViewNumberOfItems = [self.collectionView numberOfItemsInSection:0];
        NSUInteger numberMappingsItems = [self.viewHandler.mappings numberOfItemsInSection:0];
        
        
        if(numberMappingsItems > collectionViewNumberOfItems && numberMappingsItems > 0) {
            //Inserted new item, probably at the end
            //Get last message and test if isIncoming
            NSIndexPath *lastMessageIndexPath = [NSIndexPath indexPathForRow:numberMappingsItems - 1 inSection:0];
            id <OTRMessageProtocol>lastMessage = [self messageAtIndexPath:lastMessageIndexPath];
            if ([lastMessage messageIncoming]) {
                [self finishReceivingMessage];
            } else {
                [self finishSendingMessage];
            }
        } else {
            //deleted a message or message updated
            [self.collectionView performBatchUpdates:^{
                
                for (YapDatabaseViewRowChange *rowChange in rowChanges)
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
