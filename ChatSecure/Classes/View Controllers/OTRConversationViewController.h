//
//  OTRConversationViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;
@class OTRConversationViewController;

@protocol OTRConversationViewControllerDelegate <NSObject>

- (void)controller:(OTRConversationViewController *)viewController didChangeNumberOfConnectedAccounts:(NSInteger)connectedAccounts;

@end

@interface OTRConversationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, weak) id<OTRConversationViewControllerDelegate> delegate;
- (void)enterConversationWithBuddy:(OTRBuddy *)buddy;

@end
