//
//  OTROutgoingMessage.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTROutgoingMessage.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTROutgoingMessage

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    __block OTROutgoingMessage *deliveredMessage = nil;
    [transaction enumerateMessagesWithId:messageId block:^(id<OTRMessageProtocol> _Nonnull message, BOOL * _Null_unspecified stop) {
        if ([message isKindOfClass:[self class]]) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            OTROutgoingMessage *msg = (OTROutgoingMessage *)message;
            if (![msg.mediaItemUniqueId length]) {
                deliveredMessage = msg;
                *stop = YES;
            }
        }
    }];
    
    if (deliveredMessage) {
        deliveredMessage = [deliveredMessage copy];
        deliveredMessage.delivered = YES;
        deliveredMessage.dateDelivered = [NSDate date];
        [deliveredMessage saveWithTransaction:transaction];
    }
}

#pragma MARK - OTRMessageProtocol 

- (BOOL)messageIncoming
{
    return NO;
}

- (OTRMessageTransportSecurity)messageSecurity
{
    OTRMessageTransportSecurity security = [super messageSecurity];
    if(security == OTRMessageTransportSecurityPlaintext) {
        return _messageSecurity;
    }
    return security;
}

- (BOOL)messageRead
{
    return YES;
}

@end
