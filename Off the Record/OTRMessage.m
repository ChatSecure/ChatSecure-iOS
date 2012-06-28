//
//  OTRMessage.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"
#import "OTRBuddy.h"
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
    [self.buddy.protocol sendMessage:self];
}

+(void)sendMessage:(OTRMessage *)message
{    
    NSDictionary *messageInfo = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    
    [message.buddy.protocol sendMessage:message];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRSendMessage object:self userInfo:messageInfo];
}

@end
