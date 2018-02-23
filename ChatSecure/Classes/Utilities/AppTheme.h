//
//  AppTheme.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;

@class OTRAccount;
@class OTRXMPPAccount;
@class OTRXMPPBuddy;
@class OTRXMPPManager;

NS_ASSUME_NONNULL_BEGIN

@protocol ViewControllerFactory
@required
/** Returns new instance. Override this in subclass to use a different conversation view controller class */
- (__kindof UIViewController*) conversationViewController;

/** Returns new instance. Override this in subclass to use a different message view controller class */
- (__kindof UIViewController *) messagesViewController;

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController;

/** Returns new instance. Override this in subclass to use a different compose view controller class */
- (__kindof UIViewController *) composeViewController;

/** Returns new instance. Override this in subclass to use a different invite view controller class */
- (__kindof UIViewController* ) inviteViewControllerForAccount:(OTRAccount*)account;

/** Returns new instance. Override this in subclass to use a different profile view controller class */
- (__kindof UIViewController* ) keyManagementViewControllerForAccount:(OTRXMPPAccount*)account buddies:(NSArray<OTRXMPPBuddy*>*)buddies;

/** Returns new instance. Override this in subclass to use a different account detail view controller class */
- (__kindof UIViewController* ) accountDetailViewControllerForAccount:(OTRXMPPAccount*)account xmpp:(OTRXMPPManager * _Nonnull)xmpp;

@end

@protocol AppAppearance
@required
/** Set global app appearance via UIAppearance */
- (void) setupAppearance;
@end

@protocol AppColors
@required
@property (nonatomic, strong, readonly) UIColor *mainThemeColor;
@property (nonatomic, strong, readonly) UIColor *lightThemeColor;
@property (nonatomic, strong, readonly) UIColor *buttonLabelColor;
@end

@protocol AppTheme<AppAppearance, ViewControllerFactory, AppColors>
@required
@end

NS_ASSUME_NONNULL_END
