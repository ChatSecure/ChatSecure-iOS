//
//  OTRIncomingMessage.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRIncomingMessage.h"

@implementation OTRIncomingMessage

#pragma MARK - OTRMessageProtocol

- (BOOL)isMessageIncoming
{
    return YES;
}

- (OTRMessageTransportSecurity)messageSecurity
{
    OTRMessageTransportSecurity security = [super messageSecurity];
    if(security == OTRMessageTransportSecurityPlaintext) {
        return self.messageSecurityInfo.messageSecurity;
    }
    return security;
}

- (BOOL)isMessageRead
{
    return self.read;
}

@end
