//
//  OTRConversationViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;
#import "OTRThreadOwner.h"

@class OTRBuddy;
@class OTRConversationViewController;

@protocol OTRConversationViewControllerDelegate <NSObject>

- (void)conversationViewController:(OTRConversationViewController *)conversationViewController didSelectThread:(id <OTRThreadOwner>)threadOwner;
- (void)conversationViewController:(OTRConversationViewController *)conversationViewController didSelectCompose:(id)sender;

@end

/**
 The puropose of this class is to list all curent conversations (with single buddy or group chats) in a list view.
 When the user selects a conversation to enter the delegate method fires.
 */
@interface OTRConversationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <OTRConversationViewControllerDelegate> delegate;

@property (nonatomic, strong) UITableView *tableView;

@end
