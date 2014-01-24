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
    NSManagedObjectID *messageObjectID = theMessage.objectID;
    
    [[OTRKit sharedInstance] decodeMessage:message recipient:friendAccount accountName:myAccountName protocol:protocol completionBlock:^(NSString *decodedMessageString) {
        NSError *error = nil;
        OTRManagedMessage *localMessage = (OTRManagedMessage*)[[NSManagedObjectContext MR_contextForCurrentThread] existingObjectWithID:messageObjectID error:&error];
        if (error) {
            DDLogError(@"Error fetching message: %@", error);
            error = nil;
        }
        if([decodedMessageString length]) {
            localMessage.message = [OTRUtilities stripHTML:decodedMessageString];
            [localMessage setIsEncryptedValue:NO];
        } else {
            [localMessage setIsEncryptedValue:YES];
        }
        
        OTRKitMessageState messageState = [[OTRKit sharedInstance] messageStateForUsername:friendAccount accountName:myAccountName protocol:protocol];
        [localMessage.buddy setNewEncryptionStatus:messageState];
        
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        
        if (completionBlock) {
            completionBlock(localMessage);
        }
    }];
}

+(void)encodeMessage:(OTRManagedChatMessage *)theMessage completionBlock:(void (^)(OTRManagedChatMessage *))completionBlock
{
    NSString *message = theMessage.message;
    NSString *recipientAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.account.protocol;
    NSString *sendingAccount = theMessage.buddy.account.username;
    
    [[OTRKit sharedInstance] encodeMessage:message recipient:recipientAccount accountName:sendingAccount protocol:protocol completionBlock:^(NSString *message) {
        OTRManagedBuddy *localBuddy = [theMessage.buddy MR_inThreadContext];
        OTRManagedChatMessage *localMessage = [theMessage MR_inThreadContext];
        
        OTRManagedChatMessage *newOTRMessage = [OTRManagedChatMessage newMessageToBuddy:localBuddy message:message encrypted:YES];
        newOTRMessage.date = localMessage.date;
        newOTRMessage.uniqueID = localMessage.uniqueID;
        
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        
        //return newOTRMessage;
        if (completionBlock) {
            completionBlock(newOTRMessage);
        }

    }];
}

+ (void)generateOtrInitiateOrRefreshMessageTobuddy:(OTRManagedBuddy *)buddy completionBlock:(void (^)(OTRManagedChatMessage *))completionBlock {
    
    [[OTRKit sharedInstance] generateInitiateOrRefreshMessageToRecipient:buddy.accountName accountName:buddy.account.username protocol:[buddy.account protocol] completionBlock:^(NSString *message) {
        
        OTRManagedChatMessage *newOTRMessage = [OTRManagedChatMessage newMessageToBuddy:buddy message:message encrypted:YES];
        
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        
        //return newOTRMessage;
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
