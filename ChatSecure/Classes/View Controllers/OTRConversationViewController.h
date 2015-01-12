//
//  OTRConversationViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy, OTRMessage;

@interface OTRConversationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

- (void)enterConversationWithBuddy:(OTRBuddy *)buddy;
- (void)enterConversationWithBuddy:(OTRBuddy *)buddy andMessage:(OTRMessage *)message;

@end
