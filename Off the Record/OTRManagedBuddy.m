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

@interface OTRManagedBuddy()
@property (nonatomic) OTRBuddyStatus status;
@property (nonatomic) OTRKitMessageState encryptionStatus;
@end

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
@dynamic account;

-(void)sendMessage:(NSString *)message secure:(BOOL)secure
{
    if (message) {
        self.lastMessageDisconnected = NO;
        OTRManagedBuddy* theBuddy = self;
        message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"message to be sent: %@",message);
        OTRManagedMessage *newMessage = [OTRManagedMessage newMessageToBuddy:theBuddy message:message];
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

-(void)setupWithDisplayName:(NSString*)buddyName accountName:(NSString*) buddyAccountName status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    self.displayName = buddyName;
    self.accountName = buddyAccountName;
    self.status = buddyStatus;
    self.groupName = buddyGroupName;
    self.lastMessageDisconnected = NO;
    self.encryptionStatus = kOTRKitMessageStatePlaintext;
    self.chatState = kOTRChatStateUnknown;
    self.lastSentChatState = kOTRChatStateUnknown;
}

-(void)sendChatState:(OTRChatState) sendingChatState
{
    /*
    if([self.protocol respondsToSelector:@selector(sendChatState:withBuddy:)])
    {
        lastSentChatState = sendingChatState;
        [self.protocol sendChatState:sendingChatState withBuddy:self];
    }
    */
}

-(void)sendComposingChatState
{
    if(self.lastSentChatState != kOTRChatStateComposing)
    {
        [self sendChatState:kOTRChatStateComposing];
    }
    [self restartPausedChatStateTimer];
    //[self.inactiveChatStateTimer invalidate];
}
-(void)sendPausedChatState
{
    [self sendChatState:kOTRChatStatePaused];
    //[self.inactiveChatStateTimer invalidate];
}

-(void)sendActiveChatState
{
    //[pausedChatStateTimer invalidate];
    [self restartInactiveChatStateTimer];
    [self sendChatState:kOTRChatStateActive];
}
-(void)sendInactiveChatState
{
    //[self.inactiveChatStateTimer invalidate];
    if(self.lastSentChatState != kOTRChatStateInactive)
        [self sendChatState:kOTRChatStateInactive];
}

-(void)restartPausedChatStateTimer
{
    /*
    [pausedChatStateTimer invalidate];
    pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState) userInfo:nil repeats:NO];
     */
}
-(void)restartInactiveChatStateTimer
{
    /*
    [inactiveChatStateTimer invalidate];
    inactiveChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStateInactiveTimeout target:self selector:@selector(sendInactiveChatState) userInfo:nil repeats:NO];
     */
}

-(void)receiveMessage:(NSString *)message
{
    //NSLog(@"received: %@",message);
    if (message) {
        self.lastMessageDisconnected = NO;
        // Strip the shit out of it, but hopefully you're talking with someone who is trusted in the first place
        // TODO: fix this so it doesn't break some cyrillic encodings
        NSString *rawMessage = [[[message stringByConvertingHTMLToPlainText]stringByEncodingHTMLEntities] stringByLinkifyingURLs];
                
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
        
        if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            // We are not active, so use a local notification instead
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = REPLY_STRING;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",self.displayName,rawMessage];
            
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
            [userInfo setObject:self.accountName forKey:kOTRNotificationUserNameKey];
            [userInfo setObject:self.account.username forKey:kOTRNotificationAccountNameKey];
            [userInfo setObject:self.account.protocol forKey:kOTRNotificationProtocolKey];
            localNotification.userInfo = userInfo;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    }
}

-(void)receiveStatusMessage:(NSString *)message
{
    if (message) {
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
    
    //NSString * ReceiptResonseScript = [NSString stringWithFormat:@"<script>x=document.getElementById('%@');x.innerHTML = x.innerHTML+\" (delivered)\";</script>",responseID];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
}

- (void) setNewStatus:(OTRBuddyStatus)newStatus {
    if([self.account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        if ([self.messages count]!=0 && newStatus!=self.status)
        {
            if( newStatus == 0)
                [self receiveStatusMessage:OFFLINE_MESSAGE_STRING];
            else if (newStatus == 1)
                [self receiveStatusMessage:AWAY_MESSAGE_STRING];
            else if( newStatus == 2)
                [self receiveStatusMessage:AVAILABLE_MESSAGE_STRING];
            
        }
    }
    self.status = (int16_t)newStatus;
}

-(void) protocolDisconnected:(id)sender
{
    if([self.messages count]!=0 && !self.lastMessageDisconnected)
    {
        //[chatHistory appendFormat:@"<p><strong style=\"color:blue\"> You </strong> Disconnected </p>"];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
        self.lastMessageDisconnected = YES;
        self.status = kOTRBuddyStatusOffline;
    }
}

-(void)receiveEncryptionMessage:(NSString *)message
{
    //[chatHistory appendFormat:@"<p><strong>%@</strong></p>",message];
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_PROCESSED_NOTIFICATION object:self];
    
}

-(void)setNewEncryptionStatus:(OTRKitMessageState)newEncryptionStatus
{
    if([self.messages count] > 0 && newEncryptionStatus != kOTRKitMessageStateEncrypted)
    {
        [self receiveEncryptionMessage:CONVERSATION_NOT_SECURE_WARNING_STRING];
    }
    else if(newEncryptionStatus != self.encryptionStatus)
    {
        if (newEncryptionStatus != kOTRKitMessageStateEncrypted && self.encryptionStatus == kOTRKitMessageStateEncrypted) {
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
    self.encryptionStatus = newEncryptionStatus;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTREncryptionStateNotification object:self];
}

@end
