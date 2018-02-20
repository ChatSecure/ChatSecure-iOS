//
//  OTRTheme.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRTheme.h"
#import "OTRConversationViewController.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "OTRComposeViewController.h"
#import "OTRInviteViewController.h"
#import "OTRSettingsViewController.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTRTheme

- (instancetype) init {
    if (self = [super init]) {
        _lightThemeColor = [UIColor whiteColor];
        _mainThemeColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _buttonLabelColor = [UIColor darkGrayColor];
    }
    return self;
}

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme {
}


- (__kindof UIViewController*) conversationViewController {
    return [[OTRConversationViewController alloc] init];
}

/** Override this in subclass to use a different group message view controller class */
- (JSQMessagesViewController *) messagesViewController{
    return [OTRMessagesHoldTalkViewController messagesViewController];
}

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController {
    return [[OTRSettingsViewController alloc] init];
}

- (__kindof UIViewController *) composeViewController {
    return [[OTRComposeViewController alloc] init];
}

- (__kindof UIViewController* ) inviteViewControllerForAccount:(OTRAccount*)account {
    return [[OTRInviteViewController alloc] initWithAccount:account];
}

/** Returns new instance. Override this in subclass to use a different profile view controller class */
- (__kindof UIViewController* ) userProfileViewControllerForAccount:(OTRXMPPAccount*)account buddies:(NSArray<OTRXMPPBuddy*>*)buddies readConnection:(YapDatabaseConnection*)readConnection writeConnection:(YapDatabaseConnection*)writeConnection {
    XLFormDescriptor *form = [UserProfileViewController profileFormDescriptorForAccount:account buddies:buddies connection:readConnection];
    
    UserProfileViewController *verify = [[UserProfileViewController alloc] initWithAccountKey:account.uniqueId readConnection:readConnection writeConnection:writeConnection form:form];
    return verify;
}

- (__kindof UIViewController* ) accountDetailViewControllerForAccount:(OTRXMPPAccount*)account xmpp:(OTRXMPPManager * _Nonnull)xmpp longLivedReadConnection:(YapDatabaseConnection * _Nonnull)longLivedReadConnection readConnection:(YapDatabaseConnection * _Nonnull)readConnection  writeConnection:(YapDatabaseConnection * _Nonnull)writeConnection {
    return [[OTRAccountDetailViewController alloc] initWithAccount:account xmpp:xmpp longLivedReadConnection:longLivedReadConnection readConnection:readConnection  writeConnection:writeConnection];
}

@end
