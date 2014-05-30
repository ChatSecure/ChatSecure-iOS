//
//  OTRCodec.m
//  Off the Record
//
//  Created by Chris on 8/17/11.
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

#import "OTRCodec.h"
#import "OTRProtocolManager.h"
#import "OTRUtilities.h"
#import "OTRMessage.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "YapDatabaseTransaction.h"

#import "OTRLog.h"

@implementation OTRCodec

/*
+(void) decodeMessage:(OTRMessage*)message completionBlock:(void (^)(OTRMessage *))completionBlock
{
    __block OTRBuddy *messageBuddy = nil;
    __block OTRAccount *messageAccount = nil;
    OTRMessage *localMessage = [message copy];
    [[[OTRDatabaseManager sharedInstance] newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        messageBuddy = [localMessage buddyWithTransaction:transaction];
        messageAccount = [messageBuddy accountWithTransaction:transaction];
    }];
    
    NSString *text = localMessage.text;
    NSString *friendAccount = messageBuddy.username;
    NSString *protocol = [messageAccount protocolTypeString];
    NSString *myAccountName = messageAccount.username;
    
    [[OTRKit sharedInstance] decodeMessage:text recipient:friendAccount accountName:myAccountName protocol:protocol completionBlock:^(NSString *decodedMessageString) {
        if([decodedMessageString length]) {
            localMessage.text = [OTRUtilities stripHTML:decodedMessageString];
        }
        
        OTRKitMessageState messageState = [[OTRKit sharedInstance] messageStateForUsername:friendAccount accountName:myAccountName protocol:protocol];
        [[[OTRDatabaseManager sharedInstance] readWriteDatabaseConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:messageBuddy.uniqueId transaction:transaction];
            buddy.encryptionStatus = messageState;
            [buddy saveWithTransaction:transaction];
        }];
        
        
        if (completionBlock) {
            if ([decodedMessageString length])
            {
                completionBlock(localMessage);
            }
            else {
                completionBlock(nil);
            }
            
        }
    }];
}

+(void)encodeMessage:(OTRMessage *)message completionBlock:(void (^)(OTRMessage *))completionBlock
{
    __block OTRBuddy *messageBuddy = nil;
    __block OTRAccount *messageAccount = nil;
    [[[OTRDatabaseManager sharedInstance] newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        messageBuddy = [message buddyWithTransaction:transaction];
        messageAccount = [messageBuddy accountWithTransaction:transaction];
    }];

    
    NSString *unencryptedMessage = message.text;
    NSString *recipientAccount = messageBuddy.username;
    NSString *protocol = [messageAccount protocolTypeString];
    NSString *sendingAccount = messageAccount.username;

    [[OTRKit sharedInstance] encodeMessage:unencryptedMessage recipient:recipientAccount accountName:sendingAccount protocol:protocol completionBlock:^(NSString *text) {
        
        OTRMessage *newEncryptedMessage = [message copy];
        newEncryptedMessage.text = text;
        
        if (completionBlock) {
            completionBlock(newEncryptedMessage);
        }
    }];
}

+ (void)generateOtrInitiateOrRefreshMessageTobuddy:(OTRBuddy *)buddy completionBlock:(void (^)(OTRMessage *))completionBlock {
    
    __block OTRAccount *account = nil;
    [[[OTRDatabaseManager sharedInstance] newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [buddy accountWithTransaction:transaction];
    }];
    
    [[OTRKit sharedInstance] generateInitiateOrRefreshMessageToRecipient:buddy.username accountName:account.username protocol:[account protocolTypeString] completionBlock:^(NSString *text) {
        
        OTRMessage *newEncryptedMessage = [[OTRMessage alloc] init];
        newEncryptedMessage.text = text;
        newEncryptedMessage.buddyUniqueId = buddy.uniqueId;
        
        
        
        if (completionBlock) {
            completionBlock(newEncryptedMessage);
        }
    }];
}

+ (void)isGeneratingKeyForBuddy:(OTRBuddy *)buddy completion:(void (^)(BOOL isGeneratingKey))completion;
{
    __block OTRAccount *account = nil;
    [[[OTRDatabaseManager sharedInstance] newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [buddy accountWithTransaction:transaction];
    }];
    
    if(buddy)
    {
        [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:account.username protocol:[account protocolTypeString] completion:completion];
    }
    else if (completion){
        completion(NO);
    }
    
}

+ (void)generatePrivateKeyFor:(OTRAccount *)account completionBlock:(void (^)(BOOL))completionBlock
{
    [[OTRKit sharedInstance] generatePrivateKeyForAccountName:account.username protocol:[account protocolTypeString] completionBock:completionBlock];
}

+ (void)hasGeneratedKeyForAccount:(OTRAccount *)account completionBlock:(void (^)(BOOL))completionBlock {
    
    [[OTRKit sharedInstance] hasPrivateKeyForAccountName:account.username protocol:[account protocolTypeString] completionBock:completionBlock];
}
*/
@end
