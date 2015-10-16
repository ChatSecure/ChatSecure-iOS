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

@interface OTRMessagesGroupViewController ()

@property (nonatomic, strong) NSString *threadID;

@end

@implementation OTRMessagesGroupViewController

- (instancetype)initWithGroupYapId:(NSString *)groupId
{
    if (self = [self init]) {
        self.threadID = groupId;
    }
    return self;
}

- (instancetype)initWithBuddies:(NSArray<NSString *> *)buddies account:(OTRAccount *)account
{
    if (self = [self init]) {
        [self setupGroupChat:buddies];
    }
    return self;
}

- (void)setupGroupChat:(NSArray <NSString *>*)buddies {
    NSString *service = [self.xmppManager.roomManager.conferenceServicesJID firstObject];
    NSString *roomName = [NSUUID UUID].UUIDString;
    XMPPJID *roomJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",roomName,service]];
    self.threadID = [self.xmppManager.roomManager startGroupChatWithBuddies:buddies roomJID:roomJID nickname:self.account.username];
}

- (void)setupYapViewsWithGroupID:(NSString *)groupId {
    
}

#pragma - mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
