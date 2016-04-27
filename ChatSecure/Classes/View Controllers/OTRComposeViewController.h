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
@class OTRAccount;

@protocol OTRComposeViewControllerDelegate <NSObject>

@required
/**
 This method is called when the view controller 'done' button is pressed. Sends all the selected buddies the accountId to use and an optional name for groups.
 */
- (void)controller:(nonnull OTRComposeViewController *)viewController didSelectBuddies:(nullable NSArray<NSString *> *)buddies accountId:(nullable NSString *)accountId name:(nullable NSString *)name;

/**
 This method is called when the view controller's cacnel button is pressed and should be dismissed and no action taken.
 */
- (void)controllerDidCancel:(nonnull OTRComposeViewController *)viewController;

@end

@interface OTRComposeViewController : UIViewController

@property (nonatomic, weak, nullable) id<OTRComposeViewControllerDelegate> delegate;

- (void)addBuddy:(nullable NSArray <OTRAccount *>*)accountsAbleToAddBuddies;

@end
