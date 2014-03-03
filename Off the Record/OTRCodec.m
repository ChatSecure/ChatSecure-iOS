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
#import "OTRBuddyListViewController.h"
#import "OTRProtocolManager.h"
#import "OTRManagedBuddy.h"
#import "OTRUtilities.h"

#import "OTRLog.h"

@implementation OTRCodec


+(void) decodeMessage:(OTRManagedMessage*)theMessage completionBlock:(void (^)(OTRManagedMessage *))completionBlock
{
    NSString *message = theMessage.message;
    NSString *friendAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.account.protocol;
    NSString *myAccountName = theMessage.buddy.account.username;
    
    [[OTRKit sharedInstance] decodeMessage:message recipient:friendAccount accountName:myAccountName protocol:protocol completionBlock:^(NSString *decodedMessageString) {
        NSManagedObjectContext * localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        OTRManagedMessage *localMessage = [theMessage MR_inContext:localContext];
        if([decodedMessageString length]) {
            localMessage.message = [OTRUtilities stripHTML:decodedMessageString];
            [localMessage setIsEncryptedValue:NO];
        } else {
            [localMessage setIsEncryptedValue:YES];
        }
        
        OTRKitMessageState messageState = [[OTRKit sharedInstance] messageStateForUsername:friendAccount accountName:myAccountName protocol:protocol];
        [localMessage.buddy setNewEncryptionStatus:messageState inContext:localContext];
        
        [localContext MR_saveToPersistentStoreAndWait];
        
        if (completionBlock) {
            completionBlock(localMessage);
        }
    }];
}

+(void)encodeMessage:(OTRManagedMessage *)theMessage completionBlock:(void (^)(OTRManagedMessage *))completionBlock
{
    NSString *unencryptedMessage = theMessage.message;
    NSString *recipientAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.account.protocol;
    NSString *sendingAccount = theMessage.buddy.account.username;

    [[OTRKit sharedInstance] encodeMessage:unencryptedMessage recipient:recipientAccount accountName:sendingAccount protocol:protocol completionBlock:^(NSString *message) {
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        OTRManagedMessage *localMessage = [theMessage MR_inContext:localContext ];
        OTRManagedMessage *newOTRMessage = [OTRManagedMessage newMessageToBuddy:localMessage.buddy message:message encrypted:YES inContext:localContext];
        newOTRMessage.date = localMessage.date;
        newOTRMessage.uniqueID = localMessage.uniqueID;
        [localContext MR_saveToPersistentStoreAndWait];
        if (completionBlock) {
            completionBlock(newOTRMessage);
        }
    }];
}

+ (void)generateOtrInitiateOrRefreshMessageTobuddy:(OTRManagedBuddy *)buddy completionBlock:(void (^)(OTRManagedMessage *))completionBlock {
    
    [[OTRKit sharedInstance] generateInitiateOrRefreshMessageToRecipient:buddy.accountName accountName:buddy.account.username protocol:[buddy.account protocol] completionBlock:^(NSString *message) {
        
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        OTRManagedMessage *newOTRMessage = [OTRManagedMessage newMessageToBuddy:buddy message:message encrypted:YES inContext:context];
        
        [context MR_saveToPersistentStoreAndWait];
        
        if (completionBlock) {
            completionBlock(newOTRMessage);
        }
    }];
}

+ (void)isGeneratingKeyForBuddy:(OTRManagedBuddy *)buddy completion:(void (^)(BOOL isGeneratingKey))completion;
{
    if(buddy)
    {
        [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:buddy.account.username protocol:buddy.account.protocol completion:completion];
    }
    else if (completion){
        completion(NO);
    }
    
}

+ (void)generatePrivateKeyFor:(OTRManagedAccount *)account completionBlock:(void (^)(BOOL))completionBlock
{
    [[OTRKit sharedInstance] generatePrivateKeyForAccountName:account.username protocol:[account protocol] completionBock:completionBlock];
}

+ (void)hasGeneratedKeyForAccount:(OTRManagedAccount *)account completionBlock:(void (^)(BOOL))completionBlock {
    
    [[OTRKit sharedInstance] hasPrivateKeyForAccountName:account.username protocol:[account protocol] completionBock:completionBlock];
}

@end
