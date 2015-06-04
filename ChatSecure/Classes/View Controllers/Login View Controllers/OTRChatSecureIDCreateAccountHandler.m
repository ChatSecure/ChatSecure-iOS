//
//  OTRChatSecureIDCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRChatSecureIDCreateAccountHandler.h"
#import "OTRXMPPServerInfo.h"

@implementation OTRChatSecureIDCreateAccountHandler

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(NSError *, OTRAccount *))completion
{
    NSArray *serverList = [OTRXMPPServerInfo defaultServerListIncludeTor:NO];
}

- (void)receivedNotification:(NSNotification *)notification
{
    //If not able to create account move on to another domain
}

@end
