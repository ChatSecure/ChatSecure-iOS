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

- (Class) messagesViewControllerClass {
    return [OTRMessagesHoldTalkViewController class];
}

- (Class)composeViewControllerClass {
    return [OTRComposeViewController class];
}

@end
