//
//  OTRXMPPMessageYapStroage.m
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPMessageYapStroage.h"
@import XMPPFramework;
#import "OTRLog.h"
@import OTRKit;
#import "OTRXMPPBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRAccount.h"
#import "OTRConstants.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRThreadOwner.h"
#import "OTRBuddyCache.h"

@implementation OTRXMPPMessageYapStroage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)connection
{
    if (self = [self init]) {
        _databaseConnection = connection;
        _moduleDelegateQueue = dispatch_queue_create("OTRXMPPMessageYapStroage-delegateQueue", 0);
    }
    return self;
}


- (OTRXMPPBuddy *)buddyForUsername:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
}

- (OTRBaseMessage *)baseMessageFromXMPPMessage:(XMPPMessage *)xmppMessage buddyId:(NSString *)buddyId class:(Class)class {
    NSString *body = [xmppMessage body];
    
    NSDate * date = [xmppMessage delayedDeliveryDate];
    
    OTRBaseMessage *message = [[class alloc] init];
    message.text = body;
    message.buddyUniqueId = buddyId;
    if (date) {
        message.date = date;
    }
    
    message.messageId = [xmppMessage elementID];
    return message;
}

- (OTROutgoingMessage *)outgoingMessageFromXMPPMessage:(XMPPMessage *)xmppMessage buddyId:(NSString *)buddyId {
    OTROutgoingMessage *outgoingMessage = (OTROutgoingMessage *)[self baseMessageFromXMPPMessage:xmppMessage buddyId:buddyId class:[OTROutgoingMessage class]];
    // Fill in current data so it looks like this 'outgoing' message was really sent (but of course this is a message we received through carbons).
    outgoingMessage.dateSent = [NSDate date];
    return outgoingMessage;
}

- (OTRIncomingMessage *)incomingMessageFromXMPPMessage:(XMPPMessage *)xmppMessage buddyId:(NSString *)buddyId
{
    return (OTRIncomingMessage *)[self baseMessageFromXMPPMessage:xmppMessage buddyId:buddyId class:[OTRIncomingMessage class]];
}

- (void)xmppStream:(XMPPStream *)stream didReceiveMessage:(XMPPMessage *)xmppMessage
{
    // We don't handle incoming group chat messages here
    // Check out OTRXMPPRoomYapStorage instead
    if ([[xmppMessage type] isEqualToString:@"groupchat"] ||
        [xmppMessage elementForName:@"x" xmlns:XMPPMUCUserNamespace] ||
        [xmppMessage elementForName:@"x" xmlns:@"jabber:x:conference"]) {
        return;
    }
    
    if ([xmppMessage isMessageCarbon]) {
        return;
    }
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        if ([stream.tag isKindOfClass:[NSString class]]) {
            NSString *username = [[xmppMessage from] bare];
            
            [self handleChatState:xmppMessage username:username stream:stream transaction:transaction];
            [self handleDeliverResponse:xmppMessage transaction:transaction];
            
            OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
            if (!messageBuddy) {
                // message from server
                DDLogWarn(@"No buddy for message: %@", xmppMessage);
                return;
            }
            
            OTRIncomingMessage *message = [self incomingMessageFromXMPPMessage:xmppMessage buddyId:messageBuddy.uniqueId];
            NSString *activeThreadYapKey = [[OTRAppDelegate appDelegate] activeThreadYapKey];
            if([activeThreadYapKey isEqualToString:message.threadId]) {
                message.read = YES;
            }
            OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:xmppStream.tag transaction:transaction];
            
            
            if ([xmppMessage isErrorMessage]) {
                NSError *error = [xmppMessage errorMessage];
                message.error = error;
                NSString *errorText = [[xmppMessage elementForName:@"error"] elementForName:@"text"].stringValue;
                if (!message.text) {
                    if (errorText) {
                        message.text = errorText;
                    } else {
                        message.text = error.localizedDescription;
                    }
                }
                if ([errorText containsString:@"OTR Error"]) {
                    // automatically renegotiate a new session when there's an error
                    [[OTRProtocolManager sharedInstance].encryptionManager.otrKit initiateEncryptionWithUsername:username accountName:account.username protocol:account.protocolTypeString];
                }
                // Suppress error messages for now...
                // [message saveWithTransaction:transaction];
                return;
            }
            
            if ([self duplicateMessage:xmppMessage buddyUniqueId:messageBuddy.uniqueId transaction:transaction]) {
                DDLogWarn(@"Duplicate message received: %@", xmppMessage);
                return;
            }
            
            if (message.text) {
                [[OTRProtocolManager sharedInstance].encryptionManager.otrKit decodeMessage:message.text username:messageBuddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:message];
            }
        }
    }];
}

- (void)handleChatState:(XMPPMessage *)xmppMessage username:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    // Saves aren't needed when setting chatState or status because OTRBuddyCache is used internally

    OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
    if (!messageBuddy) { return; }
    OTRChatState chatState = OTRChatStateUnknown;
    if([xmppMessage hasChatState])
    {
        if([xmppMessage hasComposingChatState])
            chatState = OTRChatStateComposing;
        else if([xmppMessage hasPausedChatState])
            chatState = OTRChatStatePaused;
        else if([xmppMessage hasActiveChatState])
            chatState = OTRChatStateActive;
        else if([xmppMessage hasInactiveChatState])
            chatState = OTRChatStateInactive;
        else if([xmppMessage hasGoneChatState])
            chatState = OTRChatStateGone;
    }
    [[OTRBuddyCache sharedInstance] setChatState:chatState forBuddy:messageBuddy];
}

- (void)handleDeliverResponse:(XMPPMessage *)xmppMessage transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    if ([xmppMessage hasReceiptResponse] && ![xmppMessage isErrorMessage]) {
        [OTROutgoingMessage receivedDeliveryReceiptForMessageId:[xmppMessage receiptResponseID] transaction:transaction];
    }
}

- (BOOL)duplicateMessage:(XMPPMessage *)message buddyUniqueId:(NSString *)buddyUniqueId transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    __block BOOL result = NO;
    if ([message.elementID length]) {
        [transaction enumerateMessagesWithId:message.elementID block:^(id<OTRMessageProtocol> _Nonnull databaseMessage, BOOL * _Null_unspecified stop) {
            if ([[databaseMessage threadId] isEqualToString:buddyUniqueId]) {
                *stop = YES;
                result = YES;
            }
        }];
    }
    return result;
}

- (void)handleCarbonMessage:(XMPPMessage *)forwardedMessage stream:(XMPPStream *)stream outgoing:(BOOL)isOutgoing
{
    //Sent Message Carbons are sent by our account to another
    //So from is our JID and to is buddy
    BOOL incoming = !isOutgoing;
    
    
    NSString *username = nil;
    if (incoming) {
        username = [[forwardedMessage from] bare];
    } else {
        username = [[forwardedMessage to] bare];
    }
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * __nonnull transaction) {
        
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:username accountName:stream.tag transaction:transaction];
        
        if (!buddy) {
            return;
        }
        if (![self duplicateMessage:forwardedMessage buddyUniqueId:buddy.uniqueId transaction:transaction]) {
            if (incoming) {
                [self handleChatState:forwardedMessage username:username stream:stream transaction:transaction];
                [self handleDeliverResponse:forwardedMessage transaction:transaction];
            }
            
            if ([forwardedMessage isMessageWithBody] && ![forwardedMessage isErrorMessage] && ![OTRKit stringStartsWithOTRPrefix:forwardedMessage.body]) {
                if (incoming) {
                    OTRIncomingMessage *message = [self incomingMessageFromXMPPMessage:forwardedMessage buddyId:buddy.uniqueId];
                    NSString *activeThreadYapKey = [[OTRAppDelegate appDelegate] activeThreadYapKey];
                    if([activeThreadYapKey isEqualToString:message.threadId]) {
                        message.read = YES;
                    }
                    [message saveWithTransaction:transaction];
                } else {
                    OTROutgoingMessage *message = [self outgoingMessageFromXMPPMessage:forwardedMessage buddyId:buddy.uniqueId];
                    [message saveWithTransaction:transaction];
                }
            }
        }
    }];
}

#pragma - mark XMPPMessageCarbonsDelegate

- (void)xmppMessageCarbons:(XMPPMessageCarbons *)xmppMessageCarbons didReceiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing
{
    [self handleCarbonMessage:message stream:xmppMessageCarbons.xmppStream outgoing:isOutgoing];
}

@end
