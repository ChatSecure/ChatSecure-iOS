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
@import JSQMessagesViewController;
@import MobileCoreServices;
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
@import BButton;
#import "OTRAttachmentPicker.h"
#import "OTRImageItem.h"
#import "OTRVideoItem.h"
#import "OTRAudioItem.h"
@import JTSImageViewController;
#import "OTRAudioControlsView.h"
#import "OTRPlayPauseProgressView.h"
#import "OTRAudioPlaybackController.h"
#import "OTRMediaFileManager.h"
#import "OTRMediaServer.h"
#import "UIImage+ChatSecure.h"
#import "OTRBaseLoginViewController.h"

#import "OTRDataHandler.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRYapMessageSendAction.h"
#import "UIViewController+ChatSecure.h"
@import YapDatabase;
@import PureLayout;
@import KVOController;

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
    
    ////// TitleView //////
    OTRTitleSubtitleView *titleView = [self titleView];
    [self refreshTitleView:titleView];
    self.navigationItem.titleView = titleView;
    
    // Profile Info Button
    [self setupInfoButton];
    
    
    ////// Send Button //////
    self.sendButton = [JSQMessagesToolbarButtonFactory defaultSendButtonItem];
    
    ////// Attachment Button //////
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.cameraButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFont size:20];
    self.cameraButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cameraButton setTitle:[NSString fa_stringForFontAwesomeIcon:FACamera] forState:UIControlStateNormal];
    self.cameraButton.frame = CGRectMake(0, 0, 32, 32);
    
    ////// Microphone Button //////
    self.microphoneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.microphoneButton.frame = CGRectMake(0, 0, 32, 32);
    self.microphoneButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFont size:20];
    self.microphoneButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.microphoneButton setTitle:[NSString fa_stringForFontAwesomeIcon:FAMicrophone]
          forState:UIControlStateNormal];
    
    self.audioPlaybackController = [[OTRAudioPlaybackController alloc] init];
    
    ////// TextViewUpdates //////
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTextViewChangedNotification:) name:UITextViewTextDidChangeNotification object:self.inputToolbar.contentView.textView];
    
    /** Setup databse view handler*/
    self.viewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:[OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection databaseChangeNotificationName:[DatabaseNotificationName LongLivedTransactionChanges]];
    self.viewHandler.delegate = self;
    
    ///Custom Layout to account for no bubble cells
    OTRMessagesCollectionViewFlowLayout *layout = [[OTRMessagesCollectionViewFlowLayout alloc] init];
    layout.sizeDelegate = self;
    self.collectionView.collectionViewLayout = layout;
    
    //Subscribe to changes in encryption state
    __weak __typeof__(self) weakSelf = self;
    [self.KVOController observe:self.state keyPath:NSStringFromSelector(@selector(messageSecurity)) options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        
        __typeof__(self) strongSelf = weakSelf;
        
        if ([object isKindOfClass:[MessagesViewControllerState class]]) {
            MessagesViewControllerState *state = (MessagesViewControllerState*)object;
            NSString * placeHolderString = nil;
            switch (state.messageSecurity) {
                case OTRMessageTransportSecurityPlaintext:
                    placeHolderString = SEND_PLAINTEXT_STRING();
                    break;
                case OTRMessageTransportSecurityOTR:
                    placeHolderString = [NSString stringWithFormat:SEND_ENCRYPTED_STRING(),@"OTR"];
                    break;
                case OTRMessageTransportSecurityOMEMO:
                    placeHolderString = [NSString stringWithFormat:SEND_ENCRYPTED_STRING(),@"OMEMO"];;
                    break;
                    
                default:
                    placeHolderString = [NSBundle jsq_localizedStringForKey:@"new_message"];
                    break;
            }
            strongSelf.inputToolbar.contentView.textView.placeHolder = placeHolderString;
            [self didUpdateState];
        }
    }];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self tryToMarkAllMessagesAsRead];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    __weak typeof(self)weakSelf = self;
    
    void (^refreshGeneratingLock)(OTRAccount *) = ^void(OTRAccount * account) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        __block NSString *accountKey = nil;
        [strongSelf.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            accountKey = [strongSelf buddyWithTransaction:transaction].accountUniqueId;
        }];
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
            __block NSString *buddyKey = nil;
            [strongSelf.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                buddyKey = [strongSelf buddyWithTransaction:transaction].uniqueId;
            }];
            if ([notificationBuddy.uniqueId isEqualToString:buddyKey]) {
                [strongSelf updateEncryptionState];
            }
        }
    }];
    
    if ([self.threadKey length]) {
        [self.viewHandler.keyCollectionObserver observe:self.threadKey collection:self.threadCollection];
        [self updateViewWithKey:self.threadKey collection:self.threadCollection];
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

- (nullable id<OTRThreadOwner>)threadObjectWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction {
    id object = [transaction objectForKey:self.threadKey inCollection:self.threadCollection];
    if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
        return object;
    }
    return nil;
}

- (nullable OTRBuddy *)buddyWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction {
    id <OTRThreadOwner> object = [self threadObjectWithTransaction:transaction];
    if ([object isKindOfClass:[OTRBuddy class]]) {
        return (OTRBuddy *)object;
    }
    return nil;
}

- (nullable OTRAccount *)accountWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction {
    id <OTRThreadOwner> thread =  [self threadObjectWithTransaction:transaction];
    OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:[thread threadAccountIdentifier] transaction:transaction];
    return account;
}

- (void)setThreadKey:(NSString *)key collection:(NSString *)collection
{
    NSString *oldKey = self.threadKey;
    NSString *oldCollection = self.threadCollection;
    
    self.threadKey = key;
    self.threadCollection = collection;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        self.senderId = [[self threadObjectWithTransaction:transaction] threadAccountIdentifier];
    }];
    
    if (![oldKey isEqualToString:key] || ![oldCollection isEqualToString:collection]) {
        [self saveCurrentMessageText:self.inputToolbar.contentView.textView.text threadKey:oldKey colleciton:oldCollection];
        self.inputToolbar.contentView.textView.text = nil;
        [self receivedTextViewChanged:self.inputToolbar.contentView.textView];
    }
    
    [self.viewHandler.keyCollectionObserver stopObserving:oldKey collection:oldCollection];
    [self.viewHandler.keyCollectionObserver observe:self.threadKey collection:self.threadCollection];
    [self updateViewWithKey:self.threadKey collection:self.threadCollection];
    [self.viewHandler setup:OTRChatDatabaseViewExtensionName groups:@[self.threadKey]];
    [self moveLastComposingTextForThreadKey:self.threadKey colleciton:self.threadCollection toTextView:self.inputToolbar.contentView.textView];
    [self.collectionView reloadData];
    
    [self updateEncryptionState];
}

                           
- (YapDatabaseConnection *)readOnlyDatabaseConnection
{
    if (!_readOnlyDatabaseConnection) {
        _readOnlyDatabaseConnection = [OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection;
    }
    return _readOnlyDatabaseConnection;
}
                           
- (YapDatabaseConnection *)readWriteDatabaseConnection
{
    if (!_readWriteDatabaseConnection) {
            _readWriteDatabaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return _readWriteDatabaseConnection;
}
                        

- (nullable OTRXMPPManager *)xmppManagerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction {
    OTRAccount *account = [self accountWithTransaction:transaction];
    return (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
}

- (void)updateViewWithKey:(NSString *)key collection:(NSString *)collection
{
    if ([collection isEqualToString:[OTRBuddy collection]]) {
        __block OTRBuddy *buddy = nil;
        __block OTRAccount *account = nil;
        [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            buddy = [OTRBuddy fetchObjectWithUniqueID:key transaction:transaction];
            account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
        }];
        
        
        
        //Update UI now
        if (buddy.chatState == OTRChatStateComposing || buddy.chatState == OTRChatStatePaused) {
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
            __block BOOL canKnock = [[[OTRProtocolManager sharedInstance].pushController pushStorage] numberOfTokensForBuddy:buddy.uniqueId createdByThisAccount:NO] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (canKnock != strongSelf.state.canKnock) {
                    strongSelf.state.canKnock = canKnock;
                    [strongSelf didUpdateState];
                }
            });
            
        });
        
        [self refreshTitleView:[self titleView]];
    }
    
    [self tryToMarkAllMessagesAsRead];
}

- (void)tryToMarkAllMessagesAsRead {
    // Set all messages as read
    if ([self otr_isVisible]) {
        __weak __typeof__(self) weakSelf = self;
        __block id <OTRThreadOwner>threadOwner = nil;
        __block NSArray <id <OTRMessageProtocol>>* unreadMessages = nil;
        [self.readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            threadOwner = [weakSelf threadObjectWithTransaction:transaction];
            if (!threadOwner) { return; }
            unreadMessages = [transaction allUnreadMessagesForThread:threadOwner];
        } completionBlock:^{
            
            if ([unreadMessages count] == 0) {
                return;
            }
            
            //Mark as read
            
            NSMutableArray <id <OTRMessageProtocol>>*toBeSaved = [[NSMutableArray alloc] init];
            
            [unreadMessages enumerateObjectsUsingBlock:^(id<OTRMessageProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[OTRIncomingMessage class]]) {
                    OTRIncomingMessage *message = [((OTRIncomingMessage *)obj) copy];
                    message.read = YES;
                    [toBeSaved addObject:message];
                } else if ([obj isKindOfClass:[OTRXMPPRoomMessage class]]) {
                    OTRXMPPRoomMessage *message = [((OTRXMPPRoomMessage *)obj) copy];
                    message.read = YES;
                    [toBeSaved addObject:message];
                }
            }];
            
            [weakSelf.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                [toBeSaved enumerateObjectsUsingBlock:^(id<OTRMessageProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [transaction setObject:obj forKey:[obj messageKey] inCollection:[obj messageCollection]];
                }];
                [transaction touchObjectForKey:[threadOwner threadIdentifier] inCollection:[threadOwner threadCollection]];
            }];
        }];
    }
}

- (OTRTitleSubtitleView * __nonnull)titleView {
    UIView *titleView = self.navigationItem.titleView;
    if ([titleView isKindOfClass:[OTRTitleSubtitleView class]]) {
        return  (OTRTitleSubtitleView*)titleView;
    }
    return [[OTRTitleSubtitleView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
}
/** Updates the title view with the current thread information on this view controller*/
- (void)refreshTitleView:(OTRTitleSubtitleView *)titleView
{
    __block id<OTRThreadOwner> thread = nil;
    __block OTRAccount *account = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        thread = [self threadObjectWithTransaction:transaction];
        account =  [self accountWithTransaction:transaction];
    }];
    
    titleView.titleLabel.text = [thread threadName];
    
    UIImage *statusImage = nil;
    if ([thread isKindOfClass:[OTRBuddy class]]) {
        OTRBuddy *buddy = (OTRBuddy*)thread;
        titleView.subtitleLabel.text = buddy.username;
        UIColor *color = [buddy avatarBorderColor];
        if (color) { // only show online status
            statusImage = [OTRImages circleWithRadius:50
                                      lineWidth:0
                                      lineColor:nil
                                      fillColor:color];
        }
    } else if ([thread isGroupThread]) {
        titleView.subtitleLabel.text = GROUP_CHAT_STRING();
    } else {
        titleView.subtitleLabel.text = nil;
    }
    
    titleView.titleImageView.image = statusImage;
}

/** 
 This generates a UIAlertAction where the handler fetches the outgoing message (optionaly duplicates). Then if media message resend media message. If not update messageSecurityInfo and date and create new sending action.
 */
- (UIAlertAction *)resendOutgoingMessageActionForMessageKey:(NSString *)messageKey
                                          messageCollection:(NSString *)messageCollection
                                readWriteDatabaseConnection:(YapDatabaseConnection*)databaseConnection
                                           duplicateMessage:(BOOL)duplicateMessaage
                                                      title:(NSString *)title
{
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            OTROutgoingMessage *dbMessage = [[transaction objectForKey:messageKey inCollection:messageCollection] copy];
            if (duplicateMessaage) {
                dbMessage = [OTROutgoingMessage duplicateMessage:dbMessage];
            }
            dbMessage.error = nil;
            
            // Check if this is a media message. For now these are handled differently
            if ([dbMessage.mediaItemUniqueId length]) {
                OTRMediaItem *mediaItem = [OTRMediaItem fetchObjectWithUniqueID:dbMessage.mediaItemUniqueId transaction:transaction];
                [self sendMediaItem:mediaItem data:nil tag:dbMessage transaction:transaction];
            } else {
                dbMessage.messageSecurityInfo =[[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:self.state.messageSecurity];
                dbMessage.date = [NSDate date];
                OTRYapMessageSendAction *sendingAction = [[OTRYapMessageSendAction alloc] initWithMessageKey:dbMessage.uniqueId messageCollection:[dbMessage messageCollection] buddyKey:dbMessage.buddyUniqueId date:dbMessage.date];
                [sendingAction saveWithTransaction:transaction];
            }
            [dbMessage saveWithTransaction:transaction];
        }];
    }];
    return action;
}

- (nonnull UIAlertAction *)viewProfileAction {
    return [UIAlertAction actionWithTitle:VIEW_PROFILE_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self infoButtonPressed:action];
    }];
}

- (nonnull UIAlertAction *)cancleAction {
    return [UIAlertAction actionWithTitle:CANCEL_STRING()
                                    style:UIAlertActionStyleCancel
                                  handler:nil];
}

- (NSArray <UIAlertAction *>*)actionForMessage:(id<OTRMessageProtocol>)message {
    NSMutableArray <UIAlertAction *>*actions = [[NSMutableArray alloc] init];
    
    
    if ([message isKindOfClass:[OTROutgoingMessage class]] ) {
        OTROutgoingMessage *msg = (OTROutgoingMessage *)message;
        
        BOOL duplicate = YES;
        NSError *error = [message messageError];
        if (error != nil) {
            duplicate = NO;
        }
        // This is an outgoing message so we can offer to resend
        UIAlertAction *resendAction = [self resendOutgoingMessageActionForMessageKey:msg.uniqueId messageCollection:[OTROutgoingMessage collection] readWriteDatabaseConnection:self.readWriteDatabaseConnection duplicateMessage:duplicate title:RESEND_STRING()];
        [actions addObject:resendAction];
    }
    
    if (![message isKindOfClass:[OTRChatMessageGroup class]]) {
        [actions addObject:[self viewProfileAction]];
    }
    
    [actions addObject:[self cancleAction]];
    return actions;
}

- (void)didTapAvatar:(id<OTRMessageProtocol>)message sender:(id)sender {
    NSError *error =  [message messageError];
    NSString *title = nil;
    NSString *alertMessage = nil;
    
    NSString * sendingType = UNENCRYPTED_STRING();
    switch (self.state.messageSecurity) {
        case OTRMessageTransportSecurityOTR:
            sendingType = @"OTR";
            break;
        case OTRMessageTransportSecurityOMEMO:
            sendingType = @"OMEMO";
            break;
            
        default:
            break;
    }
    
    if ([message isKindOfClass:[OTROutgoingMessage class]]) {
        title = RESEND_MESSAGE_TITLE();
        alertMessage = [NSString stringWithFormat:RESEND_DESCRIPTION_STRING(),sendingType];
    }
    
    if (error) {
        NSUInteger otrFingerprintError = 32872;
        title = ERROR_STRING();
        alertMessage = error.localizedDescription;
        
        if (error.code == otrFingerprintError) {
            alertMessage = NO_DEVICES_BUDDY_ERROR_STRING();
        }
        
        if([message isKindOfClass:[OTROutgoingMessage class]]) {
            //If it's an outgoing message the error title should be that we were unable to send the message.
            title = UNABLE_TO_SEND_STRING();
            
            
            
            NSString *resendDescription = [NSString stringWithFormat:RESEND_DESCRIPTION_STRING(),sendingType];
            alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"\n%@",resendDescription]];
            
            //If this is an error about not having a trusted identity then we should offer to connect to the
            if (error.code == OTROMEMOErrorNoDevicesForBuddy ||
                error.code == OTROMEMOErrorNoDevices ||
                error.code == otrFingerprintError) {
                
                alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"\n%@",VIEW_PROFILE_DESCRIPTION_STRING()]];
            }
        }
    }
    
    
    if (![self isMessageTrusted:message]) {
        title = UNTRUSTED_DEVICE_STRING();
        if ([message messageIncoming]) {
            alertMessage = UNTRUSTED_DEVICE_REVEIVED_STRING();
        } else {
            alertMessage = UNTRUSTED_DEVICE_SENT_STRING();
        }
        alertMessage = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"\n%@",VIEW_PROFILE_DESCRIPTION_STRING()]];
    }
    
    NSArray <UIAlertAction*>*actions = [self actionForMessage:message];
    if ([actions count] > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:alertMessage preferredStyle:UIAlertControllerStyleActionSheet];
        [actions enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [alertController addAction:obj];
        }];
        if ([sender isKindOfClass:[UIView class]]) {
            UIView *sourceView = sender;
            alertController.popoverPresentationController.sourceView = sourceView;
            alertController.popoverPresentationController.sourceRect = sourceView.bounds;
        }
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (BOOL)isMessageTrusted:(id <OTRMessageProtocol>)message {
    BOOL trusted = YES;
    if (![message isKindOfClass:[OTRBaseMessage class]]) {
        return trusted;
    }
    
    OTRBaseMessage *baseMessage = (OTRBaseMessage *)message;
    
    
    if (baseMessage.messageSecurityInfo.messageSecurity == OTRMessageTransportSecurityOTR) {
        NSData *otrFingerprintData = baseMessage.messageSecurityInfo.otrFingerprint;
        if ([otrFingerprintData length]) {
            trusted = [[[OTRProtocolManager sharedInstance].encryptionManager otrFingerprintForKey:self.threadKey collection:self.threadCollection fingerprint:otrFingerprintData] isTrusted];
        }
    } else if (baseMessage.messageSecurityInfo.messageSecurity == OTRMessageTransportSecurityOMEMO) {
        NSString *omemoDeviceYapKey = baseMessage.messageSecurityInfo.omemoDeviceYapKey;
        NSString *omemoDeviceYapCollection = baseMessage.messageSecurityInfo.omemoDeviceYapCollection;
        __block OTROMEMODevice *device = nil;
        [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            device = [transaction objectForKey:omemoDeviceYapKey inCollection:omemoDeviceYapCollection];
        }];
        if(device != nil) {
            trusted = [device isTrusted];
        }
    }
    return trusted;
}

#pragma - mark Profile Button Methods

- (void)setupInfoButton {
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.accessibilityIdentifier = @"profileButton";
    [infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
}

- (void) infoButtonPressed:(id)sender {
    __block OTRAccount *account = nil;
    __block OTRBuddy *buddy = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [self accountWithTransaction:transaction];
        buddy = [self buddyWithTransaction:transaction];
    }];
    if (!account || !buddy) {
        return;
    }
    
    // Hack to manually re-fetch OMEMO devicelist because PEP sucks
    // TODO: Ideally this should be moved to some sort of manual refresh in the Profile view
    id manager = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
    if ([manager isKindOfClass:[OTRXMPPManager class]]) {
        XMPPJID *jid = [XMPPJID jidWithString:buddy.username];
        OTRXMPPManager *xmpp = manager;
        [xmpp.omemoSignalCoordinator.omemoModule fetchDeviceIdsForJID:jid elementId:nil];
    }
    
    XLFormDescriptor *form = [UserProfileViewController profileFormDescriptorForAccount:account buddies:@[buddy] connection:self.readOnlyDatabaseConnection];

    UserProfileViewController *verify = [[UserProfileViewController alloc] initWithAccountKey:account.uniqueId connection:self.readOnlyDatabaseConnection form:form];
    verify.completionBlock = ^{
        [self updateEncryptionState];
    };
    UINavigationController *verifyNav = [[UINavigationController alloc] initWithRootViewController:verify];
    verifyNav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:verifyNav animated:YES completion:nil];
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
    __weak __typeof__(self) weakSelf = self;
    [self.readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        __typeof__(self) strongSelf = weakSelf;
        id possibleBuddy = [transaction objectForKey:self.threadKey inCollection:self.threadCollection];
        if ([possibleBuddy isKindOfClass:[OTRBuddy class]]) {
            OTRBuddy *buddy = (OTRBuddy *)possibleBuddy;
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            
            __block OTRKitMessageState messageState = [[OTRProtocolManager sharedInstance].encryptionManager.otrKit messageStateForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (messageState == OTRKitMessageStateEncrypted) {
                    self.state.canSendMedia = YES;
                } else {
                    self.state.canSendMedia = NO;
                }
                [self didUpdateState];
            });
            
            switch (buddy.preferredSecurity) {
                case OTRSessionSecurityPlaintextOnly:
                case OTRSessionSecurityPlaintextWithOTR: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (messageState == OTRKitMessageStateEncrypted) {
                            strongSelf.state.messageSecurity = OTRMessageTransportSecurityOTR;
                        } else {
                            strongSelf.state.messageSecurity = OTRMessageTransportSecurityPlaintext;
                        }
                    });
                    break;
                }
                case OTRSessionSecurityOTR: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.state.messageSecurity = OTRMessageTransportSecurityOTR;
                    });
                    break;
                }
                case OTRSessionSecurityOMEMOandOTR:
                case OTRSessionSecurityOMEMO: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.state.messageSecurity = OTRMessageTransportSecurityOMEMO;
                    });
                    break;
                }
                case OTRSessionSecurityBestAvailable: {
                    [buddy bestTransportSecurityWithTransaction:transaction completionBlock:^(OTRMessageTransportSecurity security) {
                        strongSelf.state.messageSecurity = security;
                    } completionQueue:dispatch_get_main_queue()];
                    break;
                }
                    
            }
        }
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
    __block OTRAccount *account = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [self accountWithTransaction:transaction];
    }];
    
    if (account == nil) {
        return;
    }
    
    //If we have the password then we can login with that password otherwise show login UI to enter password
    if ([account.password length]) {
        [[OTRProtocolManager sharedInstance] loginAccount:account userInitiated:YES];
        
    } else {
        OTRBaseLoginViewController *loginViewController = [OTRBaseLoginViewController loginViewControllerForAccount:account];
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
    
    [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        id <OTRThreadOwner> thread = [[transaction objectForKey:key inCollection:collection] copy];
        [thread setCurrentMessageText:text];
        [transaction setObject:thread forKey:key inCollection:collection];
        
        //Send inactive chat State
        OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:[thread threadAccountIdentifier] transaction:transaction];
        OTRXMPPManager *xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
        if (![text length]) {
            [xmppManager sendChatState:OTRChatStateInactive withBuddyID:[thread threadIdentifier]];
        }
    }];
}

//* Takes the current value out of the thread object and sets it to the text view and nils out result*/
- (void)moveLastComposingTextForThreadKey:(NSString *)key colleciton:(NSString *)collection toTextView:(UITextView *)textView {
    if (![key length] || ![collection length] || !textView) {
        return;
    }
    __block id <OTRThreadOwner> thread = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        thread = [[transaction objectForKey:key inCollection:collection] copy];
    }];
    // Don't remove text you're already composing
    NSString *oldThreadText = [thread currentMessageText];
    if (!textView.text.length && oldThreadText.length) {
        textView.text = oldThreadText;
        [self receivedTextViewChanged:textView];
    }
    if (oldThreadText.length) {
        [thread setCurrentMessageText:nil];
        [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [transaction setObject:thread forKey:key inCollection:collection];
        }];
    }
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

- (void)sendMediaItem:(OTRMediaItem *)mediaItem data:(NSData *)data tag:(id)tag transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OTRBuddy *buddy = [self buddyWithTransaction:transaction];
    OTRAccount *account = [self accountWithTransaction:transaction];
    OTRBaseMessage *message = [mediaItem parentMessageInTransaction:transaction];
    
    if (data) {
        buddy.lastMessageId = message.uniqueId;
        [buddy saveWithTransaction:transaction];
        [[OTRProtocolManager sharedInstance].encryptionManager.dataHandler sendFileWithName:mediaItem.filename fileData:data username:buddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:tag];
        
    } else {
        NSURL *url = [[OTRMediaServer sharedInstance] urlForMediaItem:mediaItem buddyUniqueId:buddy.uniqueId];
        
        [[OTRProtocolManager sharedInstance].encryptionManager.dataHandler sendFileWithURL:url username:buddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:tag];
    }
    
    [mediaItem touchParentMessageWithTransaction:transaction];
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
        NSURL *videoURL = [[OTRMediaServer sharedInstance] urlForMediaItem:videoItem buddyUniqueId:self.threadKey];
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
        [self.audioPlaybackController playAudioItem:audioItem buddyUniqueId:self.threadKey error:&error];
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
    // Could be better to move this information to the message object to not need to do a database read.
    __block OTRAccount *account = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [self accountWithTransaction:transaction];
    }];
    if ([account isKindOfClass:[OTRXMPPTorAccount class]]) {
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
    
    //0. Clear out message text immediately
    //   This is to prevent the scenario where multiple messages get sent because the message text isn't cleared out
    //   due to aggregated touch events during UI pauses.
    //   A side effect is that sent messages may not appear in the UI immediately
    [self finishSendingMessage];
    
    //1. Create new message database object
    __block OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
    message.buddyUniqueId = self.threadKey;
    message.text = text;
    message.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:self.state.messageSecurity];
    
    //2. Create send message task
    __block OTRYapMessageSendAction *sendingAction = [[OTRYapMessageSendAction alloc] initWithMessageKey:message.uniqueId messageCollection:[OTROutgoingMessage collection] buddyKey:message.threadId date:message.date];
    
    //3. save both to database
    __weak __typeof__(self) weakSelf = self;
    [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        __typeof__(self) strongSelf = weakSelf;
        [message saveWithTransaction:transaction];
        [sendingAction saveWithTransaction:transaction];
        
        //Update buddy
        OTRBuddy *buddy = [[OTRBuddy fetchObjectWithUniqueID:strongSelf.threadKey transaction:transaction] copy];
        buddy.composingMessageString = nil;
        buddy.lastMessageId = message.uniqueId;
        [buddy saveWithTransaction:transaction];
    }];
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
            
            __block OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
            message.buddyUniqueId = self.threadKey;
            message.mediaItemUniqueId = imageItem.uniqueId;
            message.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:OTRMessageTransportSecurityOTR];
            
            [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [message saveWithTransaction:transaction];
                [imageItem saveWithTransaction:transaction];
                
            } completionBlock:^{
                [[OTRMediaFileManager sharedInstance] setData:imageData forItem:imageItem buddyUniqueId:self.threadKey completion:^(NSInteger bytesWritten, NSError *error) {
                    [imageItem touchParentMessage];
                    if (error) {
                        message.error = error;
                        [self.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                            [message saveWithTransaction:transaction];
                        }];
                    }
                    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                        [self sendMediaItem:imageItem data:imageData tag:message transaction:transaction];
                    }];
                    
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
    
    __block OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
    message.mediaItemUniqueId = videoItem.uniqueId;
    message.buddyUniqueId = self.threadKey;
    message.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:OTRMessageTransportSecurityOTR];
    
    NSString *newPath = [OTRMediaFileManager pathForMediaItem:videoItem buddyUniqueId:self.threadKey];
    [[OTRMediaFileManager sharedInstance] copyDataFromFilePath:videoURL.path toEncryptedPath:newPath completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoURL.path]) {
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:videoURL.path error:&err];
            if (err) {
                DDLogError(@"Error Removing Video File");
            }
            
        }
        
        message.error = error;
        [self.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [videoItem saveWithTransaction:transaction];
            [message saveWithTransaction:transaction];
            [self sendMediaItem:videoItem data:nil tag:message transaction:transaction];
        }];
    }];
}

- (NSArray <NSString *>*)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker preferredMediaTypesForSource:(UIImagePickerControllerSourceType)source
{
    return @[(NSString*)kUTTypeImage];
}

- (void)sendAudioFileURL:(NSURL *)url
{
    __block OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
    message.buddyUniqueId = self.threadKey;
    
    __block OTRAudioItem *audioItem = [[OTRAudioItem alloc] init];
    audioItem.isIncoming = [message messageIncoming];
    audioItem.filename = [[url absoluteString] lastPathComponent];
    
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url
                                                 options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
    
    audioItem.timeLength = CMTimeGetSeconds(audioAsset.duration);
    
    message.mediaItemUniqueId = audioItem.uniqueId;
    
    NSString *newPath = [OTRMediaFileManager pathForMediaItem:audioItem buddyUniqueId:self.threadKey];
    
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
        [self.readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [message saveWithTransaction:transaction];
            [audioItem saveWithTransaction:transaction];
            [self sendMediaItem:audioItem data:data tag:message transaction:transaction];
        }];
        
        
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
    __block OTRAccount *account = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [self accountWithTransaction:transaction];
    }];
    
    NSString *senderDisplayName = @"";
    if (account) {
        if ([account.displayName length]) {
            senderDisplayName = account.displayName;
        } else {
            senderDisplayName = account.username;
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
    if ([message messageError] || ![self isMessageTrusted:message]) {
        avatarImage = [OTRImages circleWarningWithColor:[OTRColors warnColor]];
    }
    else if ([message messageIncoming]) {
        __block OTRBuddy *buddy = nil;
        [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            buddy = [self buddyWithTransaction:transaction];
        }];
        avatarImage = [buddy avatarImage];
    }
    else {
        __block OTRAccount *account = nil;
        [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            account = [self accountWithTransaction:transaction];
        }];
        avatarImage = [account avatarImage];
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
        NSString *knockString = KNOCK_SENT_STRING();
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

/** Currently uses clock for queued, and checkmark for delivered. */
- (nullable NSString*) deliveryStatusStringForMessage:(nonnull OTROutgoingMessage*)outgoingMessage {
    if (!outgoingMessage) { return nil; }
    NSString *deliveryStatusString = nil;
    if(outgoingMessage.dateSent == nil && ![outgoingMessage isMediaMessage]) {
        // Waiting to send message. This message is in the queue.
        deliveryStatusString = [NSString fa_stringForFontAwesomeIcon:FAClockO];
    } else if (outgoingMessage.isDelivered){
        deliveryStatusString = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheck]];
    }
    return deliveryStatusString;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol> message = [self messageAtIndexPath:indexPath];
    
    UIFont *font = [UIFont fontWithName:kFontAwesomeFont size:12];
    if (!font) {
        font = [UIFont systemFontOfSize:12];
    }
    NSDictionary *iconAttributes = @{NSFontAttributeName: font};
    NSDictionary *lockAttributes = [iconAttributes copy];
    
    ////// Lock Icon //////
    NSString *lockString = nil;
    if (message.messageSecurity == OTRMessageTransportSecurityOTR) {
        lockString = [NSString stringWithFormat:@"%@ OTR ",[NSString fa_stringForFontAwesomeIcon:FALock]];
    } else if (message.messageSecurity == OTRMessageTransportSecurityOMEMO) {
        lockString = [NSString stringWithFormat:@"%@ OMEMO ",[NSString fa_stringForFontAwesomeIcon:FALock]];
    }
    else {
        lockString = [NSString fa_stringForFontAwesomeIcon:FAUnlock];
    }
    
    BOOL trusted = YES;
    if([message isKindOfClass:[OTRBaseMessage class]]) {
        trusted = [self isMessageTrusted:message];
    };
    
    if (!trusted) {
        NSMutableDictionary *mutableCopy = [lockAttributes mutableCopy];
        [mutableCopy setObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
        lockAttributes = mutableCopy;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:lockString attributes:lockAttributes];

    if ([message isKindOfClass:[OTROutgoingMessage class]]) {
        OTROutgoingMessage *outgoingMessage = (OTROutgoingMessage *)message;
        NSString *deliveryString = [self deliveryStatusStringForMessage:outgoingMessage];
        if (deliveryString) {
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:deliveryString attributes:iconAttributes]];
        }
    }
    
    if([[message messageMediaItemKey] length] > 0) {
        
        __block OTRMediaItem *mediaItem = nil;
        //Get the media item
        [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            mediaItem = [OTRMediaItem fetchObjectWithUniqueID:[message messageMediaItemKey] transaction:transaction];
        }];
        
        float percentProgress = mediaItem.transferProgress * 100;
        
        NSString *progressString = nil;
        NSUInteger insertIndex = 0;
        
        if (mediaItem.isIncoming && mediaItem.transferProgress < 1) {
            progressString = [NSString stringWithFormat:@" %@ %.0f%%",INCOMING_STRING(),percentProgress];
            insertIndex = [attributedString length];
        } else if (!mediaItem.isIncoming && mediaItem.transferProgress < 1) {
            if(percentProgress > 0) {
                progressString = [NSString stringWithFormat:@"%@ %.0f%% ",SENDING_STRING(),percentProgress];
            } else {
                progressString = [NSString stringWithFormat:@"%@ ",WAITING_STRING()];
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
    __weak __typeof__(self) weakSelf = self;
    [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        __typeof__(self) strongSelf = weakSelf;
        [transaction removeObjectForKey:[message messageKey] inCollection:[message messageCollection]];
        //Update Last message date for sorting and grouping
        OTRBuddy *buddy = [[strongSelf buddyWithTransaction:transaction] copy];
        buddy.lastMessageId = nil;
        [buddy saveWithTransaction:transaction];
    }];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    [self didTapAvatar:message sender:avatarImageView];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRMessageProtocol,JSQMessageData> message = [self messageAtIndexPath:indexPath];
    if ([message isMediaMessage]) {
        __block OTRMediaItem *item = nil;
        [self.readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
             item = [OTRMediaItem fetchObjectWithUniqueID:[message messageMediaItemKey] transaction:transaction];
        } completionBlock:^{
            if (item.transferProgress != 1 && item.isIncoming) {
                return;
            }
            
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
    [self updateViewWithKey:self.threadKey collection:self.threadCollection];
    [self.collectionView reloadData];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler key:(NSString *)key collection:(NSString *)collection
{
    [self updateViewWithKey:key collection:collection];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if (!rowChanges.count) {
        return;
    }
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
            // We can't use finishSendingMessage here because it might
            // accidentally clear out unsent message text
            [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
            [self.collectionView reloadData];
            [self scrollToBottomAnimated:YES];
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
