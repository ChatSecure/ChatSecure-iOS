//
//  OTRMessagesGroupViewController.h
//  ChatSecure
//
//  Created by David Chiles on 10/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesViewController.h"

@interface OTRMessagesGroupViewController : OTRMessagesViewController

- (void)setupWithGroupYapId:(NSString *)groupId;
- (void)setupWithBuddies:(NSArray<NSString *> *)buddies accountId:(NSString *)accountId name:(NSString *)name;

@end
