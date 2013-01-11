//
//  OTRManagedBuddy.m
//  Off the Record
//
//  Created by Christopher Ballinger on 1/10/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
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

#import "OTRManagedBuddy.h"
#import "OTRManagedMessage.h"
#import "OTRCodec.h"
#import "OTRProtocolManager.h"
#import "NSString+HTML.h"
#import "Strings.h"
#import "OTRConstants.h"

@implementation OTRManagedBuddy

@dynamic accountName;
@dynamic chatState;
@dynamic displayName;
@dynamic encryptionStatus;
@dynamic lastSentChatState;
@dynamic status;
@dynamic groupName;
@dynamic lastMessageDisconnected;
@dynamic messages;
@dynamic composingMessageString;

-(void)sendMessage:(NSString *)message secure:(BOOL)secure
{
    if (message) {
        self.lastMessageDisconnected = NO;
        OTRManagedBuddy* theBuddy = self;
        message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"message to be sent: %@",message);
        OTRManagedMessage *newMessage = [OTRManagedMessage newMessageWithBuddy:theBuddy message:message];
        //NSLog(@"newMessagge: %@",newMessage.message);
        OTRManagedMessage *encodedMessage;
        if(secure)
        {
            encodedMessage = [OTRCodec encodeMessage:newMessage];
        }
        else
        {
            encodedMessage = newMessage;
        }
        //NSLog(@"encoded message: %@",encodedMessage.message);
        [OTRManagedMessage sendMessage:encodedMessage];

        self.lastSentChatState=kOTRChatStateActive;
    }
}

@end
