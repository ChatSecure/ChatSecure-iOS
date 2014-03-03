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
#import "OTRUtilities.h"
#import "NSString+HTML.h"
#import "Strings.h"
#import "OTRLog.h"


@implementation OTRManagedMessage



+(OTRManagedMessage*)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context {
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isIncoming = NO;
    return message;
}

+(OTRManagedMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context {
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isIncomingValue = YES;
    return message;
}

+(OTRManagedMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus inContext:(NSManagedObjectContext *)context
{
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isEncryptedValue = encryptionStatus;
    message.isIncomingValue = YES;
    return message;
}

+(OTRManagedMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus delayedDate:(NSDate *)date inContext:(NSManagedObjectContext *)context
{
    OTRManagedMessage * message = [self newMessageFromBuddy:theBuddy message:theMessage encrypted:encryptionStatus inContext:context];
    if (date) {
        message.date = date;
    }
    return message;
}

+ (void) showLocalNotificationForMessage:(OTRManagedMessage*)message {
    OTRManagedMessage *localMessage = [message MR_inThreadContext];
    if (localMessage.isEncryptedValue) {
        DDLogWarn(@"Message was unable to be decrypted, not showing local notification");
        return;
    }
    localMessage.buddy.lastMessageDisconnected = NO;
    NSString * rawMessage = [localMessage.message stringByConvertingHTMLToPlainText];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = REPLY_STRING;
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
        
        NSString * displayName = localMessage.buddy.displayName;
        if (!displayName.length) {
            displayName = localMessage.buddy.accountName;
        }
        localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",displayName,rawMessage];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        [userInfo setObject:localMessage.buddy.accountName forKey:kOTRNotificationUserNameKey];
        [userInfo setObject:localMessage.buddy.account.username forKey:kOTRNotificationAccountNameKey];
        [userInfo setObject:localMessage.buddy.account.protocol forKey:kOTRNotificationProtocolKey];
        localNotification.userInfo = userInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    }
}

+(OTRManagedMessage *)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus inContext:(NSManagedObjectContext *)context
{
    OTRManagedMessage *message = [OTRManagedMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isIncomingValue = NO;
    message.isReadValue = YES;
    message.isEncryptedValue = encryptionStatus;
    return message;
}

+(OTRManagedMessage*)newMessageWithBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context
{
    OTRManagedBuddy *localBuddy = [theBuddy MR_inContext:context];
    OTRManagedMessage *managedMessage = [OTRManagedMessage MR_createInContext:context];
    NSError *error = nil;
    [context obtainPermanentIDsForObjects:@[managedMessage] error:&error];
    if (error) {
        DDLogError(@"Error obtaining permanent ID for message: %@", error);
    }
    managedMessage.uniqueID = [OTRUtilities uniqueString];
    managedMessage.buddy = localBuddy;
    managedMessage.messagebuddy = localBuddy;
    managedMessage.message = [OTRUtilities stripHTML:theMessage];
    managedMessage.date = [NSDate date];
    managedMessage.isDeliveredValue = NO;
    theBuddy.lastMessageDate = managedMessage.date;

    return managedMessage;
}

+(void)receivedDeliveryReceiptForMessageID:(NSString *)objectIDString
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
    NSArray * messages = [OTRManagedMessage MR_findByAttribute:OTRManagedMessageAttributes.uniqueID withValue:objectIDString inContext:context];
    [messages enumerateObjectsUsingBlock:^(OTRManagedMessage * message, NSUInteger idx, BOOL *stop) {
        message.isDeliveredValue = YES;
    }];
    
    [context MR_saveToPersistentStoreAndWait];
}

@end
