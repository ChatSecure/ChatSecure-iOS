//
//  OTRXMPPMessageYapStroage.m
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPMessageYapStroage.h"
#import "XMPPStream.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+XEP_0280.h"
#import "NSXMLElement+XEP_0203.h"
#import "OTRLog.h"
#import "OTRKit.h"
#import "OTRXMPPBuddy.h"
#import "OTRMessage.h"
#import "OTRAccount.h"
#import "OTRConstants.h"

@implementation OTRXMPPMessageYapStroage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)connection
{
    if (self = [self init]) {
        self.databaseConnection = connection;
    }
    return self;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)xmppMessage
{
    [self storeMessage:xmppMessage stream:sender incoming:YES];
}

- (void)storeMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream incoming:(BOOL)incoming
{
    if ([xmppMessage isMessageCarbon]) {
        [self handleCarbonMessage:xmppMessage stream:stream];
    } else {
        [self handleMessage:xmppMessage stream:stream incoming:incoming];
    }
}

- (OTRXMPPBuddy *)buddyForUsername:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
}

- (OTRMessage *)messageFromXMPPMessage:(XMPPMessage *)xmppMessage buddyId:(NSString *)buddyId
{
    NSString *body = [xmppMessage body];
    
    NSDate * date = [xmppMessage delayedDeliveryDate];
    
    OTRMessage *message = [[OTRMessage alloc] init];
    message.incoming = YES;
    message.text = body;
    message.buddyUniqueId = buddyId;
    if (date) {
        message.date = date;
    }
    
    message.messageId = [xmppMessage elementID];
    return message;
}

- (void)handleMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream incoming:(BOOL)incoming;
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        if ([stream.tag isKindOfClass:[NSString class]]) {
            NSString *username = [[xmppMessage from] bare];
            
            if ([xmppMessage isErrorMessage]) {
                NSError *error = [xmppMessage errorMessage];
                DDLogCWarn(@"XMPP Error: %@",error);
            }
            
            [self handleChatState:xmppMessage username:username stream:stream transaction:transaction];
            [self handleDeliverResponse:xmppMessage transaction:transaction];
            
            if ([xmppMessage isMessageWithBody] && ![xmppMessage isErrorMessage])
            {
                OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
                if (messageBuddy && ![self duplicateMessage:xmppMessage buddyUniqueId:messageBuddy.uniqueId transaction:transaction]) {
                    OTRMessage *message = [self messageFromXMPPMessage:xmppMessage buddyId:messageBuddy.uniqueId];
                    message.incoming = YES;
                    
                    if (messageBuddy) {
                        OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:xmppStream.tag transaction:transaction];
                        [[OTRKit sharedInstance] decodeMessage:message.text username:messageBuddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:message];
                    } else {
                        // message from server
                        DDLogWarn(@"No buddy for message: %@", xmppMessage);
                    }
                }
            }
        }
    }];
}

- (void)handleChatState:(XMPPMessage *)xmppMessage username:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
    if([xmppMessage hasChatState])
    {
        if([xmppMessage hasComposingChatState])
            messageBuddy.chatState = kOTRChatStateComposing;
        else if([xmppMessage hasPausedChatState])
            messageBuddy.chatState = kOTRChatStatePaused;
        else if([xmppMessage hasActiveChatState])
            messageBuddy.chatState = kOTRChatStateActive;
        else if([xmppMessage hasInactiveChatState])
            messageBuddy.chatState = kOTRChatStateInactive;
        else if([xmppMessage hasGoneChatState])
            messageBuddy.chatState = kOTRChatStateGone;
        [messageBuddy saveWithTransaction:transaction];
    }
}

- (void)handleDeliverResponse:(XMPPMessage *)xmppMessage transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    if ([xmppMessage hasReceiptResponse] && ![xmppMessage isErrorMessage]) {
        [OTRMessage receivedDeliveryReceiptForMessageId:[xmppMessage receiptResponseID] transaction:transaction];
    }
}

- (BOOL)duplicateMessage:(XMPPMessage *)message buddyUniqueId:(NSString *)buddyUniqueId transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    __block BOOL result = NO;
    if ([message.elementID length]) {
        [OTRMessage enumerateMessagesWithMessageId:message.elementID transaction:transaction usingBlock:^(OTRMessage *message, BOOL *stop) {
            if ([message.buddyUniqueId isEqualToString:buddyUniqueId]) {
                *stop = YES;
                result = YES;
            }
        }];
    }
    return result;
}

- (void)handleCarbonMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream
{
    //Sent Message Carbons are sent by our account to another
    //So from is our JID and to is buddy
    BOOL incoming = NO;
    XMPPMessage *forwardedMessage = [xmppMessage messageCarbonForwardedMessage];
    
    NSString *username = nil;
    if ([xmppMessage isReceivedMessageCarbon]) {
        username = [[forwardedMessage from] bare];
        incoming = YES;
    } else {
        username = [[forwardedMessage to] bare];
    }
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * __nonnull transaction) {
        
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:username accountName:stream.tag transaction:transaction];
        
        if (buddy) {
            if (![self duplicateMessage:forwardedMessage buddyUniqueId:buddy.uniqueId transaction:transaction]) {
                if (incoming) {
                    [self handleChatState:forwardedMessage username:username stream:stream transaction:transaction];
                    [self handleDeliverResponse:forwardedMessage transaction:transaction];
                }
                
                
                
                if ([forwardedMessage isMessageWithBody] && ![forwardedMessage isErrorMessage] && ![OTRKit stringStartsWithOTRPrefix:forwardedMessage.body]) {
                    OTRMessage *message = [self messageFromXMPPMessage:forwardedMessage buddyId:buddy.uniqueId];
                    message.incoming = incoming;
                    [message saveWithTransaction:transaction];
                }
            }
        }
    }];
}

@end
