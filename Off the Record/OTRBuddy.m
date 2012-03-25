//
//  OTRBuddy.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRMessage.h"
#import "OTRCodec.h"
#import "OTRProtocolManager.h"

@implementation OTRBuddy

@synthesize accountName;
@synthesize displayName;
@synthesize protocol;
@synthesize groupName;
@synthesize status;
@synthesize chatHistory;
@synthesize lastMessage;

- (void) dealloc {
    self.accountName = nil;
    self.displayName = nil;
    self.protocol = nil;
    self.groupName = nil;
    self.chatHistory = nil;
}


-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) buddyAccountName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    if(self = [super init])
    {
        self.displayName = buddyName;
        self.accountName = buddyAccountName;
        self.protocol = buddyProtocol;
        self.status = buddyStatus;
        self.groupName = buddyGroupName;
        self.chatHistory = [NSMutableString string];
    }
    return self;
}

+(OTRBuddy*)buddyWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    OTRBuddy *newBuddy = [[OTRBuddy alloc] initWithDisplayName:buddyName accountName:accountName protocol:buddyProtocol status:buddyStatus groupName:buddyGroupName];
    return newBuddy;
}

- (int) fontSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 7.0;
    } else {
        return 5.0;
    }
}

-(NSString *) stringByStrippingHTML:(NSString*)string {
    NSRange r;
    NSString *s = [string copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s; 
}


-(void)sendMessage:(NSString *)message secure:(BOOL)secure
{
    OTRBuddy* theBuddy = self;
    message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"message to be sent: %@",message);
    OTRMessage *newMessage = [OTRMessage messageWithSender:[[OTRProtocolManager sharedInstance] accountNameForProtocol:protocol] recipient:theBuddy.accountName message:message protocol:protocol];
    NSLog(@"newMessagge: %@",newMessage.message);
    OTRMessage *encodedMessage;
    if(secure)
    {
        encodedMessage = [OTRCodec encodeMessage:newMessage];
    }
    else
    {
        encodedMessage = newMessage;
    }
    
    
    
    NSLog(@"encoded message: %@",encodedMessage.message);
    [OTRMessage sendMessage:encodedMessage];    
    
    NSString *username = [NSString stringWithFormat:@"<FONT SIZE=%d COLOR=\"#0000ff\"><b>Me:</b></FONT>",[self fontSize]];
    
    [chatHistory appendFormat:@"%@ <FONT SIZE=%d>%@</FONT><br>",username,[self fontSize], message];
}



-(void)receiveMessage:(NSString *)message
{
    self.lastMessage = message;
    NSLog(@"received: %@",message);
    
    NSString *rawMessage = [self stringByStrippingHTML:message];
    
    NSString *username = [NSString stringWithFormat:@"<FONT SIZE=%d COLOR=\"#ff0000\"><b>%@:</b></FONT>",[self fontSize],self.displayName];
    
    [chatHistory appendFormat:@"%@ <FONT SIZE=%d>%@</FONT><br>",username,[self fontSize],rawMessage];
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_RECEIVED_NOTIFICATION object:self];
}

@end
