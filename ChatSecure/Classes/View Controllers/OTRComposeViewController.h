//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;
@class OTRComposeViewController;

@protocol OTRComposeViewControllerDelegate <NSObject>

/**
 This method is called when the view controller 'done' button is pressed. Sends all the selected buddies the accountId to use and an optional name for groups.
 */
- (void)controller:(nonnull OTRComposeViewController *)viewController didSelectBuddies:(nullable NSArray<NSString *> *)buddies accountId:(nullable NSString *)accountId name:(nullable NSString *)name;

@end

@interface OTRComposeViewController : UIViewController

@property (nonatomic, weak) id<OTRComposeViewControllerDelegate> delegate;

- (void)addBuddy:(NSArray *)accountsAbleToAddBuddies;

@end
