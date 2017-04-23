//
//  OTROutgoingMessage.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTROutgoingMessage.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRMessageEncryptionInfo.h"

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

/** New outgoing message w/ preferred message security. Unsaved! */
+ (instancetype) messageToBuddy:(OTRBuddy *)buddy text:(NSString *)text transaction:(YapDatabaseReadTransaction *)transaction {
    NSParameterAssert(buddy);
    NSParameterAssert(text);
    NSParameterAssert(transaction);
    OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
    message.text = text;
    message.buddyUniqueId = buddy.uniqueId;
    OTRMessageTransportSecurity preferredSecurity = [buddy preferredTransportSecurityWithTransaction:transaction];
    message.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:preferredSecurity];
    return message;
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
