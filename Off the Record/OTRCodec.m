//
//  OTRCodec.m
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

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
    OTRKitMessageState messageState = [[OTRKit sharedInstance] messageStateForUsername:friendAccount accountName:myAccountName protocol:protocol];
    theMessage.buddy.encryptionStatus = messageState;
    
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
