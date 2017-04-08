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
            deliveredMessage = (OTROutgoingMessage *)message;
            *stop = YES;
        }
    }];
    
    // OTRDATA Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
    if (deliveredMessage.mediaItemUniqueId.length > 0 &&
        deliveredMessage.text.length == 0) {
        return;
    }
    
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

- (BOOL)messageRead
{
    return YES;
}

@end
