//
//  OTROutgoingMessage.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTROutgoingMessage.h"
#import "ChatSecureCoreCompat-Swift.h"
#import "OTRMessageEncryptionInfo.h"

@implementation OTROutgoingMessage

#pragma MARK - OTRMessageProtocol 

- (BOOL)isMessageIncoming
{
    return NO;
}

- (BOOL)isMessageRead
{
    return YES;
}

- (BOOL) isMessageSent {
    return self.dateSent != nil;
}

- (BOOL) isMessageDelivered {
    return self.isDelivered;
}

@end
