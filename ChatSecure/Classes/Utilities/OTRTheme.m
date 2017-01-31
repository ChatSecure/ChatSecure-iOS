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
#import "OTRMessagesGroupViewController.h"
#import "OTRInviteViewController.h"
#import "OTRSettingsViewController.h"

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


- (Class) conversationViewControllerClass {
    return [OTRConversationViewController class];
}

- (Class) groupMessagesViewControllerClass {
    return [OTRMessagesGroupViewController class];
}

/** Override this in subclass to use a different message view controller class */
- (JSQMessagesViewController *) groupMessagesViewController
{
    return [[self groupMessagesViewControllerClass] messagesViewController];
}

- (Class) messagesViewControllerClass {
    return [OTRMessagesHoldTalkViewController class];
}

/** Override this in subclass to use a different group message view controller class */
- (JSQMessagesViewController *) messagesViewController{
    return [[self messagesViewControllerClass] messagesViewController];
}

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController {
    return [[OTRSettingsViewController alloc] init];
}

- (Class)composeViewControllerClass {
    return [OTRComposeViewController class];
}

- (Class)inviteViewControllerClass {
    return [OTRInviteViewController class];
}

@end
