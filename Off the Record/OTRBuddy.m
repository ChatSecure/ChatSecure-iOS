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
#import "NSString+HTML.h"
#import "Strings.h"
#import "OTRConstants.h"

@implementation OTRBuddy

@synthesize accountName;
@synthesize displayName;
@synthesize protocol;
@synthesize groupName;
@synthesize status;
@synthesize chatHistory;
@synthesize lastMessage;
@synthesize lastMessageDisconnected;

- (void) dealloc {
    self.accountName = nil;
    self.displayName = nil;
    self.protocol = nil;
    self.groupName = nil;
    self.chatHistory = nil;
}


-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) buddyAccountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    if(self = [super init])
    {
        self.displayName = buddyName;
        self.accountName = buddyAccountName;
        self.protocol = buddyProtocol;
        self.status = buddyStatus;
        self.groupName = buddyGroupName;
        self.chatHistory = [NSMutableString string];
        self.lastMessage = @"";
        self.lastMessageDisconnected = NO;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(protocolDisconnected) name:kOTRProtocolDiconnect object:nil];
         
         
         //postNotificationName:@"XMPPDisconnectedNotification" object:nil]; 
        
    }
    return self;
}

+(OTRBuddy*)buddyWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    OTRBuddy *newBuddy = [[OTRBuddy alloc] initWithDisplayName:buddyName accountName:accountName protocol:buddyProtocol status:buddyStatus groupName:buddyGroupName];
    return newBuddy;
}


-(void)sendMessage:(NSString *)message secure:(BOOL)secure
{
    if (message) {
        lastMessageDisconnected = NO;
        OTRBuddy* theBuddy = self;
        message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"message to be sent: %@",message);
        OTRMessage *newMessage = [OTRMessage messageWithBuddy:theBuddy message:message];
        //NSLog(@"newMessagge: %@",newMessage.message);
        OTRMessage *encodedMessage;
        if(secure)
        {
            encodedMessage = [OTRCodec encodeMessage:newMessage];
        }
        else
        {
            encodedMessage = newMessage;
        }
        //NSLog(@"encoded message: %@",encodedMessage.message);
        [OTRMessage sendMessage:encodedMessage];    
        
        NSString *username = [NSString stringWithFormat:@"<p><strong style=\"color:blue\">Me:</strong>"];
        
        [chatHistory appendFormat:@"%@ %@</p>",username, message];
    }
}


-(void)receiveMessage:(NSString *)message
{
    //NSLog(@"received: %@",message);
    if (message) {
        lastMessageDisconnected = NO;
        // Strip the shit out of it, but hopefully you're talking with someone who is trusted in the first place
        // TODO: fix this so it doesn't break some cyrillic encodings
        NSString *rawMessage = [[[[message stringByStrippingHTML]stringByConvertingHTMLToPlainText]stringByEncodingHTMLEntities] stringByLinkifyingURLs];
        self.lastMessage = rawMessage;
        
        NSString *username = [NSString stringWithFormat:@"<p><strong style=\"color:red\">%@:</strong>",self.displayName];
        
        [chatHistory appendFormat:@"%@ %@</p>",username,rawMessage];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
        
        if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            // We are not active, so use a local notification instead
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = REPLY_STRING;
            localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",self.displayName,self.lastMessage];
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    }
}

-(void)receiveStatusMessage:(NSString *)message
{
    if (message) {
        NSString *username = [NSString stringWithFormat:@"<p><strong style=\"color:red\">%@ </strong>",self.displayName];
        [chatHistory appendFormat:@"%@ %@</p>",username,message];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
    }
}

-(void)setStatus:(OTRBuddyStatus)newStatus
{
    if([self.protocol.account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        if ([self.chatHistory length]!=0 && newStatus!=status)
        {
            if( newStatus == 0)
                [self receiveStatusMessage:OFFLINE_STRING];
            else if (newStatus == 1)
                [self receiveMessage:AWAY_STRING];
            else if( newStatus == 2)
                [self receiveMessage:AVAILABLE_STRING];
            
        }
    }
    status = newStatus;
}
         
-(void) protocolDisconnected
{
    if( [self.chatHistory length]!=0 && !lastMessageDisconnected)
    {
        [chatHistory appendFormat:@"<p><strong style=\"color:blue\"> You </strong> Disconnected </p>"];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
        lastMessageDisconnected = YES;
    }
             
}

@end
