//
//  OTRMessagesGroupViewController.m
//  ChatSecure
//
//  Created by David Chiles on 10/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesGroupViewController.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPRoomManager.h"
@import OTRAssets;

@interface OTRMessagesGroupViewController ()

@property (nonatomic, strong) NSString *threadID;
@property (nonatomic, strong) NSString *accountUniqueId;

@end

@implementation OTRMessagesGroupViewController

- (void)setupWithGroupYapId:(NSString *)groupId
{
    self.threadID = groupId;
    self.accountUniqueId = [[self threadObject] threadAccountIdentifier];
}

- (void)setupWithBuddies:(NSArray<NSString *> *)buddies accountId:(NSString *)accountId
{
    self.accountUniqueId = accountId;
    [self setupGroupChat:buddies account:[self account]];
    
}

- (void)setupGroupChat:(NSArray <NSString *>*)buddies account:(OTRAccount *)account {
    NSString *service = [self.xmppManager.roomManager.conferenceServicesJID firstObject];
    NSString *roomName = [NSUUID UUID].UUIDString;
    XMPPJID *roomJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",roomName,service]];
    self.threadID = [self.xmppManager.roomManager startGroupChatWithBuddies:buddies roomJID:roomJID nickname:account.username];
    [self setThreadKey:self.threadID collection:[OTRXMPPRoom collection]];
}

- (OTRAccount *)account {
    __block OTRAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
    }];
    return account;
}

- (UIBarButtonItem *)rightBarButtonItem {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"112-group" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(didSelectOccupantsButton:)];
    return barButtonItem;
}

#pragma - mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma - mark Button Actions

- (void)didSelectOccupantsButton:(id)sender {
    
}

@end
