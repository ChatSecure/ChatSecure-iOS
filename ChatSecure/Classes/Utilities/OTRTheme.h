//
//  OTRTheme.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;

@class OTRAccount;
@class OTRXMPPAccount;
@class OTRXMPPManager;
@class YapDatabaseConnection;
@class JSQMessagesViewController;

NS_ASSUME_NONNULL_BEGIN
@interface OTRTheme : NSObject

@property (nonatomic, strong) UIColor *mainThemeColor;
@property (nonatomic, strong) UIColor *lightThemeColor;
@property (nonatomic, strong) UIColor *buttonLabelColor;

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme;

/** Returns new instance. Override this in subclass to use a different conversation view controller class */
- (__kindof UIViewController*) conversationViewController;

/** Returns new instance. Override this in subclass to use a different message view controller class */
- (__kindof JSQMessagesViewController *) messagesViewController;

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController;

/** Returns new instance. Override this in subclass to use a different compose view controller class */
- (__kindof UIViewController *) composeViewController;

/** Returns new instance. Override this in subclass to use a different invite view controller class */
- (__kindof UIViewController* ) inviteViewControllerForAccount:(OTRAccount*)account;

/** Returns new instance. Override this in subclass to use a different account detail view controller class */
- (__kindof UIViewController* ) accountDetailViewControllerForAccount:(OTRXMPPAccount*)account xmpp:(OTRXMPPManager * _Nonnull)xmpp longLivedReadConnection:(YapDatabaseConnection * _Nonnull)longLivedReadConnection writeConnection:(YapDatabaseConnection * _Nonnull)writeConnection;

/** Override this to disable OMEMO message encryption. default: YES */
- (BOOL) enableOMEMO;

@end
NS_ASSUME_NONNULL_END
