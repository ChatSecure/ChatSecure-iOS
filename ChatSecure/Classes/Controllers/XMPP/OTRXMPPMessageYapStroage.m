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
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        if ([stream.tag isKindOfClass:[NSString class]]) {
            OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:[[xmppMessage from] bare] withAccountUniqueId:stream.tag transaction:transaction];
            
            if ([xmppMessage isErrorMessage]) {
                NSError *error = [xmppMessage errorMessage];
                DDLogCWarn(@"XMPP Error: %@",error);
            }
            else if([xmppMessage hasChatState])
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
            
            
            if ([xmppMessage hasReceiptResponse] && ![xmppMessage isErrorMessage]) {
                [OTRMessage receivedDeliveryReceiptForMessageId:[xmppMessage receiptResponseID] transaction:transaction];
            }
            
            if ([xmppMessage isMessageWithBody] && ![xmppMessage isErrorMessage])
            {
                NSString *body = [xmppMessage body];
                
                NSDate * date = [xmppMessage delayedDeliveryDate];
                
                OTRMessage *message = [[OTRMessage alloc] init];
                message.incoming = YES;
                message.text = body;
                message.buddyUniqueId = messageBuddy.uniqueId;
                if (date) {
                    message.date = date;
                }
                
                message.messageId = [xmppMessage elementID];
                
                if (messageBuddy) {
                    OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:xmppStream.tag transaction:transaction];
                    [[OTRKit sharedInstance] decodeMessage:message.text username:messageBuddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:message];
                } else {
                    // message from server
                    DDLogWarn(@"No buddy for message: %@", xmppMessage);
                }
            }
            
            if (messageBuddy) {
                [transaction setObject:messageBuddy forKey:messageBuddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
            }
        }
        
        
    }];
}

@end
