//
//  OTRMessagesGroupViewController.h
//  ChatSecure
//
//  Created by David Chiles on 10/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesViewController.h"
#import "OTRMessagesHoldTalkViewController.h"

@interface OTRMessagesGroupViewController : OTRMessagesHoldTalkViewController

- (void)setupWithBuddies:(NSArray<NSString *> *)buddies accountId:(NSString *)accountId name:(NSString *)name;

@end
