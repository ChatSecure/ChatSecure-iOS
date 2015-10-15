//
//  OTRMessagesGroupViewController.h
//  ChatSecure
//
//  Created by David Chiles on 10/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesViewController.h"

@interface OTRMessagesGroupViewController : OTRMessagesViewController

- (instancetype)initWithGroupYapId:(NSString *)groupId;
- (instancetype)initWithBuddies:(NSArray <NSString *>*)buddies account:(OTRAccount *)account;

@end
