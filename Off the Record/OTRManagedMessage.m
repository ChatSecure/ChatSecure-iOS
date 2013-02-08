//
//  OTRManagedMessage.m
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

#import "OTRManagedMessage.h"
#import "OTRManagedBuddy.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"

@implementation OTRManagedMessage

@dynamic date;
@dynamic message;
@dynamic buddy;
@dynamic isEncrypted;
@dynamic isIncoming;

+(OTRManagedMessage*)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage {
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage];
    message.isIncoming = NO;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [context MR_save];
    return message;
}
+(OTRManagedMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage {
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage];
    message.isIncoming = YES;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [context MR_save];
    return message;
}

+(OTRManagedMessage*)newMessageWithBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage
{
    OTRManagedMessage *managedMessage = [OTRManagedMessage MR_createEntity];
    managedMessage.buddy = theBuddy;
    managedMessage.message = theMessage;
    managedMessage.date = [NSDate date];
    managedMessage.isEncrypted = NO;

    return managedMessage;
}

-(void)send
{
    OTRProtocolManager * protocolManager =[OTRProtocolManager sharedInstance];
    id<OTRProtocol> protocol = [protocolManager protocolForAccount:self.buddy.account];
    [protocol sendMessage:self];
}

+(void)sendMessage:(OTRManagedMessage *)message
{
    NSDictionary *messageInfo = [NSDictionary dictionaryWithObject:message.objectID forKey:@"message"];
    
    [message.buddy invalidatePausedChatStateTimer];
    
    
    OTRProtocolManager * protocolManager =[OTRProtocolManager sharedInstance];
    id<OTRProtocol> protocol = [protocolManager protocolForAccount:message.buddy.account];
    [protocol sendMessage:message];
    
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kOTRSendMessage object:self userInfo:messageInfo];
}

@end
