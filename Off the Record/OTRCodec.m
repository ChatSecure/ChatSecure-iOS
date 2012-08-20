//
//  OTRCodec.m
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRCodec.h"
#import "OTRBuddyListViewController.h"
#import "OTRProtocolManager.h"

@implementation OTRCodec


+(OTRMessage*) decodeMessage:(OTRMessage*)theMessage;
{
    
    NSString *message = theMessage.message;
    NSString *friendAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.protocol.account.protocol;
    NSString *myAccountName = theMessage.buddy.protocol.account.username;
    
    NSString *decodedMessageString = [[OTRKit sharedInstance] decodeMessage:message recipient:friendAccount accountName:myAccountName protocol:protocol];
    
    OTRMessage *newOTRMessage = [OTRMessage messageWithBuddy:theMessage.buddy message:decodedMessageString];
    
    return newOTRMessage;
}


+(OTRMessage*) encodeMessage:(OTRMessage*)theMessage;
{
    NSString *message = theMessage.message;
    NSString *recipientAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.protocol.account.protocol;
    NSString *sendingAccount = theMessage.buddy.protocol.account.username;
    
    NSString *encodedMessageString = [[OTRKit sharedInstance] encodeMessage:message recipient:recipientAccount accountName:sendingAccount protocol:protocol];
    
    OTRMessage *newOTRMessage = [OTRMessage messageWithBuddy:theMessage.buddy message:encodedMessageString];
    
    return newOTRMessage;
}


@end
