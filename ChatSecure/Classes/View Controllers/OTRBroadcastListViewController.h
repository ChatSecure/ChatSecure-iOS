//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;
@class OTRBroadcastListViewController;

@protocol OTRBroadcastListViewController <NSObject>

- (void)controller:(OTRBroadcastListViewController *)viewController didSelectBuddies:(NSMutableArray *)buddies;

@end

@interface OTRBroadcastListViewController : UIViewController 

@property (nonatomic, weak) id<OTRBroadcastListViewController> delegate;

- (void)enterConversationWithBuddies:(NSMutableArray *)buddies;

@end
