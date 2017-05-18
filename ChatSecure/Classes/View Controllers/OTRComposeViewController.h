//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;
@import YapDatabase;

@class OTRBuddy;
@class OTRComposeViewController;
@class OTRAccount;

NS_ASSUME_NONNULL_BEGIN
@protocol OTRComposeViewControllerDelegate <NSObject>

@required
/**
 This method is called when the view controller 'done' button is pressed or a single buddy is selected. Sends all the selected buddies the accountId to use and an optional name for groups.
 */
- (void)controller:(nonnull OTRComposeViewController *)viewController didSelectBuddies:(nullable NSArray<NSString *> *)buddies accountId:(nullable NSString *)accountId name:(nullable NSString *)name;

/**
 This method is called when the view controller's cacnel button is pressed and should be dismissed and no action taken.
 */
- (void)controllerDidCancel:(nonnull OTRComposeViewController *)viewController;

@end

@interface OTRComposeViewController : UIViewController

@property (nonatomic, weak, nullable) id<OTRComposeViewControllerDelegate> delegate;

/** 
 * The current state of the compose view controller. In single selection mode if a user taps a on buddy it enters the conversation immediately.
 * If not in single selection mode than the user can slect multiple 'buddies' at once
*/
@property (nonatomic, readonly) BOOL selectionModeIsSingle;

- (void)addBuddy:(NSArray <OTRAccount *>*)accountsAbleToAddBuddies;

/**
 * This changes the selection mode therefore changing the behevour of selecting a buddy and the right navigation bar button item.
 */
- (void)switchSelectionMode;

/** If user has more than one account, more information needs to be shown to distinguish contacts from each account. By default will show account if numAccounts > 0*/
- (BOOL) shouldShowAccountLabelWithTransaction:(YapDatabaseReadTransaction*)transaction;

@end
NS_ASSUME_NONNULL_END
