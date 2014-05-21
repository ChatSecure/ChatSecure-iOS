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

static NSTimeInterval const kOTRMessageSentDateShowTimeInterval = 5 * 60;

@interface OTRMessagesViewController ()

@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *buddyMappings;

@property (nonatomic, strong) UIImageView *outgoingBubbleImageView;
@property (nonatomic, strong) UIImageView *incomingBubbleImageView;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end

@implementation OTRMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
     ////// bubbles //////
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory outgoingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory incomingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
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

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MMM dd, YYYY h:mm a"];
    }
    return _dateFormatter;
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    if (![self.buddy.uniqueId isEqualToString:buddy.uniqueId]) {
        [self saveCurrentMessageText];
    }
    
    _buddy = buddy;
    
    if (self.buddy) {
        self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRChatDatabaseViewExtensionName];
        self.buddyMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRBuddyDatabaseViewExtensionName];
        
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            self.account = [self.buddy accountWithTransaction:transaction];
            [self.messageMappings updateWithTransaction:transaction];
            [self.buddyMappings updateWithTransaction:transaction];
        }];
    }
    else {
        self.messageMappings = nil;
        self.buddyMappings = nil;
        self.account = nil;
    }
    
    //refresh other parts of the view
    
}

- (void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.inputToolbar.contentView.textView.text;
    if(![self.buddy.composingMessageString length])
    {
        //[[self xmppManager] sendChatState:kOTRChatStateInactive withBuddyID:self.buddy.uniqueId];
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

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text sender:(NSString *)sender date:(NSDate *)date
{
    OTRMessage *message = [[OTRMessage alloc] init];
    message.buddyUniqueId = self.buddy.uniqueId;
    message.text = text;
    message.transportedSecurely = NO;
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [message saveWithTransaction:transaction];
    }];
    
    [[OTRProtocolManager sharedInstance] sendMessage:message];
    [self finishSendingMessage];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    
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
    
    return cell;
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
        NSString *dateString = [self.dateFormatter stringFromDate:[self messageAtIndexPath:indexPath].date];
        return [[NSAttributedString alloc] initWithString:dateString];
    }
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
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
/*
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    
}


- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
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
            
            if (self.buddy.chatState != updatedBuddy.chatState || self.buddy.encryptionStatus != updatedBuddy.encryptionStatus) {
                self.buddy = updatedBuddy;
            }
            
            
        }
    }
    
    if ([rowChanges count]) {
        [self finishReceivingMessage];
    }
    
}

@end
