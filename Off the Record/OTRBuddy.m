//
//  OTRBuddy.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
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
@synthesize encryptionStatus;
@synthesize chatState;
@synthesize lastSentChatState;
@synthesize pausedChatStateTimer;
@synthesize inactiveChatStateTimer;
@synthesize composingMessageString;

- (void) dealloc {
    self.accountName = nil;
    self.displayName = nil;
    self.protocol = nil;
    self.groupName = nil;
    self.chatHistory = nil;
    [self.pausedChatStateTimer invalidate];
    self.pausedChatStateTimer = nil;
    [self.inactiveChatStateTimer invalidate];
    self.inactiveChatStateTimer = nil;
}


-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) buddyAccountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    if(self = [super init])
    {
        self.numberOfMessagesSent = 0;
        self.displayName = buddyName;
        self.accountName = buddyAccountName;
        self.protocol = buddyProtocol;
        self.status = buddyStatus;
        self.groupName = buddyGroupName;
        self.chatHistory = [NSMutableString string];
        self.lastMessage = @"";
        self.lastMessageDisconnected = NO;
        self.encryptionStatus = kOTRKitMessageStatePlaintext;
        self.chatState = kOTRChatStateUnknown;
        self.lastSentChatState = kOTRChatStateUnknown;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(protocolDisconnected:) name:kOTRProtocolDiconnect object:buddyProtocol];
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
        self.numberOfMessagesSent +=1;
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
        
        NSString *username = [NSString stringWithFormat:@"<p id=\"%d\"><strong style=\"color:blue\">Me:</strong>",self.numberOfMessagesSent];
        
        [chatHistory appendFormat:@"%@ %@</p>",username, message];
    }
}

-(void)sendChatState:(OTRChatState) sendingChatState
{
    if([self.protocol respondsToSelector:@selector(sendChatState:withBuddy:)])
    {
        lastSentChatState = sendingChatState;
        [self.protocol sendChatState:sendingChatState withBuddy:self];
    }
    
}

-(void)sendComposingChatState
{
    if(self.lastSentChatState != kOTRChatStateComposing)
    {
        [self sendChatState:kOTRChatStateComposing];
    }
    [self restartPausedChatStateTimer];
    [self.inactiveChatStateTimer invalidate];
}
-(void)sendPausedChatState
{
    [self sendChatState:kOTRChatStatePaused];
    [self.inactiveChatStateTimer invalidate];
}

-(void)sendActiveChatState
{
    [pausedChatStateTimer invalidate];
    [self restartInactiveChatStateTimer];
    [self sendChatState:kOTRChatStateActive];
}
-(void)sendInactiveChatState
{
    [self.inactiveChatStateTimer invalidate];
    if(self.lastSentChatState != kOTRChatStateInactive)
        [self sendChatState:kOTRChatStateInactive];
}

-(void)restartPausedChatStateTimer
{
    [pausedChatStateTimer invalidate];
    pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState) userInfo:nil repeats:NO];
}
-(void)restartInactiveChatStateTimer
{
    [inactiveChatStateTimer invalidate];
    inactiveChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStateInactiveTimeout target:self selector:@selector(sendInactiveChatState) userInfo:nil repeats:NO];
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
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",self.displayName,self.lastMessage];
          
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
            [userInfo setObject:accountName forKey:kOTRNotificationUserNameKey];
            [userInfo setObject:protocol.account.username forKey:kOTRNotificationAccountNameKey];
            [userInfo setObject:protocol.account.protocol forKey:kOTRNotificationProtocolKey];
            localNotification.userInfo = userInfo;
            
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

-(void)receiveChatStateMessage:(OTRChatState) newChatState
{
    self.chatState = newChatState;
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
}

-(void)receiveReceiptResonse:(NSString *)responseID
{
    NSLog(@"Receipt Resonse: %@",responseID);
    
    NSString * ReceiptResonseScript = [NSString stringWithFormat:@"<script>x=document.getElementById('%@');x.innerHTML = x.innerHTML+\" (delivered)\";</script>",responseID];
    
    [chatHistory appendString:ReceiptResonseScript];
    
    
    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
    
    
    
}

-(void)setStatus:(OTRBuddyStatus)newStatus
{
    if([self.protocol.account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        if ([self.chatHistory length]!=0 && newStatus!=status)
        {
            if( newStatus == 0)
                [self receiveStatusMessage:OFFLINE_MESSAGE_STRING];
            else if (newStatus == 1)
                [self receiveStatusMessage:AWAY_MESSAGE_STRING];
            else if( newStatus == 2)
                [self receiveStatusMessage:AVAILABLE_MESSAGE_STRING];
            
        }
    }
    status = newStatus;
}
         
-(void) protocolDisconnected:(id)sender
{
    if( [self.chatHistory length]!=0 && !lastMessageDisconnected)
    {
        [chatHistory appendFormat:@"<p><strong style=\"color:blue\"> You </strong> Disconnected </p>"];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
        lastMessageDisconnected = YES;
        self.status = kOTRBuddyStatusOffline;
    }
}

-(void)receiveEncryptionMessage:(NSString *)message
{
    [chatHistory appendFormat:@"<p><strong>%@</strong></p>",message];
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
    
}

-(void)setEncryptionStatus:(OTRKitMessageState)newEncryptionStatus
{
    if(![self.chatHistory length] && newEncryptionStatus != kOTRKitMessageStateEncrypted)
    {
        [self receiveEncryptionMessage:CONVERSATION_NOT_SECURE_WARNING_STRING];
    }
    else if(newEncryptionStatus != self.encryptionStatus)
    {
        if (newEncryptionStatus != kOTRKitMessageStateEncrypted && encryptionStatus == kOTRKitMessageStateEncrypted) {
            [[[UIAlertView alloc] initWithTitle:SECURITY_WARNING_STRING message:[NSString stringWithFormat:CONVERSATION_NO_LONGER_SECURE_STRING, self.displayName] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil] show];
        }
        switch (newEncryptionStatus) {
            case kOTRKitMessageStatePlaintext:
                [self receiveEncryptionMessage:CONVERSATION_NOT_SECURE_WARNING_STRING];
                break;
            case kOTRKitMessageStateEncrypted:
                [self receiveEncryptionMessage:CONVERSATION_SECURE_WARNING_STRING];
                break;
            case kOTRKitMessageStateFinished:
                [self receiveEncryptionMessage:CONVERSATION_NOT_SECURE_WARNING_STRING];
                break;
            default:
                NSLog(@"Unknown Encryption State");
                break;
        }
        
    }
    encryptionStatus = newEncryptionStatus;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTREncryptionStateNotification object:self];
}

@end
