//
//  OTRMessage.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/11/11.
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

#import "OTROldMessage.h"
#import "OTRConstants.h"

@implementation OTRMessage


@synthesize message;
@synthesize buddy;


-(id)initWithBuddy:(OTRBuddy *)theBuddy message:(NSString *)theMessage
{
    self = [super init];
    
    if(self)
    {
        buddy = theBuddy;
        message = theMessage;
        
    }
    return self;
}

+(OTRMessage*)messageWithBuddy:(OTRBuddy *)theBuddy message:(NSString *)theMessage
{
    return [[OTRMessage alloc] initWithBuddy:theBuddy message:theMessage];
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"Buddy:%@\nAccount:%@\nMessage:%@",self.buddy.accountName,self.buddy.protocol.account,self.message];
}

-(void)send
{
    //[self.buddy.protocol sendMessage:self];
}

+(void)sendMessage:(OTRMessage *)message
{
    /*
    NSDictionary *messageInfo = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    [message.buddy restartInactiveChatStateTimer];
    
    [message.buddy.protocol sendMessage:message];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRSendMessage object:self userInfo:messageInfo];
     */
}

@end
