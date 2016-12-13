//
//  OTRMessagesGroupViewController.m
//  ChatSecure
//
//  Created by David Chiles on 10/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
#import "OTRMessagesGroupViewController.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPRoomManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import <ChatSecureUIKit/ChatSecureUIKit-Swift.h>
@import OTRAssets;

@interface OTRMessagesGroupViewController ()

@property (nonatomic, strong) NSString *accountUniqueId;

@end

@implementation OTRMessagesGroupViewController

- (void)setupWithBuddies:(NSArray<NSString *> *)buddies accountId:(NSString *)accountId name:(NSString *)name
{
    self.accountUniqueId = accountId;
    __block OTRAccount *account = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [OTRAccount fetchObjectWithUniqueID:accountId transaction:transaction];
    }];
    [self setupGroupChat:buddies account:account name:name];
    
}

- (void)setupGroupChat:(NSArray <NSString *>*)buddies account:(OTRAccount *)account name:(NSString *)name {
    __block OTRXMPPManager *xmppManager = nil;
    [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        xmppManager = [self xmppManagerWithTransaction:transaction];
    }];
    
    NSString *service = [xmppManager.roomManager.conferenceServicesJID firstObject];
    NSString *roomName = [NSUUID UUID].UUIDString;
    XMPPJID *roomJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",roomName,service]];
    self.threadKey = [xmppManager.roomManager startGroupChatWithBuddies:buddies roomJID:roomJID nickname:account.username subject:name];
    [self setThreadKey:self.threadKey collection:[OTRXMPPRoom collection]];
}

- (OTRAccount *)accountWithTransaction:(YapDatabaseReadTransaction *)transaction {
    OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
    return account;
}

// Override superclass
- (void)setupInfoButton {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"112-group" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(didSelectOccupantsButton:)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
}

#pragma - mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma - mark Button Actions

- (void)didSelectOccupantsButton:(id)sender {
    OTRRoomOccupantsViewController *occupantsViewController = [[OTRRoomOccupantsViewController alloc] initWithDatabaseConnection:[self.readWriteDatabaseConnection.database newConnection] roomKey:self.threadKey];
    [self.navigationController pushViewController:occupantsViewController animated:YES];
}

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    if(![text length]) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [self.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        __typeof__(self) strongSelf = weakSelf;
        
        OTRXMPPRoomMessage *databaseMessage = [[OTRXMPPRoomMessage alloc] init];
        databaseMessage.messageText = text;
        databaseMessage.messageDate = [NSDate date];
        databaseMessage.roomUniqueId = self.threadKey;
        OTRXMPPRoom *room = (OTRXMPPRoom *)[strongSelf threadObjectWithTransaction:transaction];
        databaseMessage.roomJID = room.jid;
        databaseMessage.roomUniqueId = room.uniqueId;
        databaseMessage.senderJID = room.ownJID;
        databaseMessage.state = RoomMessageStateNeedsSending;

        [databaseMessage saveWithTransaction:transaction];
    }];
    
}

#pragma - mark JSQMessagesCollectionViewDataSource Methods

- (id <JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JSQMessageAvatarImageDataSource> imageDataSource = [super collectionView:collectionView avatarImageDataForItemAtIndexPath:indexPath];
    if (!imageDataSource) {
        
        id <OTRMessageProtocol, JSQMessageData> message = [self messageAtIndexPath:indexPath];
        if ([message isKindOfClass:[OTRXMPPRoomMessage class]]) {
            OTRXMPPRoomMessage *roomMessage = (OTRXMPPRoomMessage *)message;
            __block OTRXMPPRoomOccupant *roomOccupant = nil;
            [self.readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                [transaction enumerateRoomOccupantsWithJid:roomMessage.senderJID block:^(OTRXMPPRoomOccupant * _Nonnull occupant, BOOL * _Null_unspecified stop) {
                    roomOccupant = occupant;
                    *stop = YES;
                }];
            }];
            UIImage *avatarImage = [roomOccupant avatarImage];
            if (avatarImage) {
                NSUInteger diameter = MIN(avatarImage.size.width, avatarImage.size.height);
                imageDataSource = [JSQMessagesAvatarImageFactory avatarImageWithImage:avatarImage diameter:diameter];
            }
        }
        
    }
    return imageDataSource;
}

@end
