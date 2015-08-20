//
//  OTRXMPPMessageCarbonsDelegate.m
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPMessageCarbonsDelegate.h"
#import "XMPPStream.h"
#import "OTRXMPPMessageYapStroage.h"

@implementation OTRXMPPMessageCarbonsDelegate

- (void)xmppMessageCarbons:(XMPPMessageCarbons *)xmppMessageCarbons willReceiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing
{
    
}

- (void)xmppMessageCarbons:(XMPPMessageCarbons *)xmppMessageCarbons didReceiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing
{
    [multicastDelegate storeMessage:message stream:xmppMessageCarbons.xmppStream incoming:!isOutgoing];
}



@end
