//
//  OTRMessage.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"

@implementation OTRMessage

@synthesize sender;
@synthesize recipient;
@synthesize message;
@synthesize protocol;

-(id)initWithSender:(NSString*)theSender recipient:(NSString*)theRecipient message:(NSString*)theMessage protocol:(NSString*)theProtocol
{
    self = [super init];
    
    if(self)
    {
        if(theSender)
            sender = theSender;
        else
            sender = theRecipient;
        recipient = theRecipient;
        message = theMessage;
        protocol = theProtocol;
    }
    return self;
}

+(OTRMessage*)messageWithSender:(NSString*)sender recipient:(NSString*)recipient message:(NSString*)message protocol:(NSString*)protocol
{
    OTRMessage *newMessage = [[OTRMessage alloc] initWithSender:sender recipient:recipient message:message protocol:protocol];
    
    return newMessage;
}

+(void)printDebugMessageInfo:(OTRMessage*)messageInfo;
{
    NSLog(@"S:%@ R:%@ M:%@ P:%@",messageInfo.sender,messageInfo.recipient,messageInfo.message,messageInfo.protocol);
}

+(void)sendMessage:(OTRMessage *)message
{    
    NSDictionary *messageInfo = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    [protocol send:self];
    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageNotification" object:self userInfo:messageInfo];
}

@end
