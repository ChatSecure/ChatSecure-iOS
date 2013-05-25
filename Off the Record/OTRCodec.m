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

@implementation OTRCodec


+(void) decodeMessage:(OTRManagedMessage*)theMessage;
{
    NSString *message = theMessage.message;
    NSString *friendAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.account.protocol;
    NSString *myAccountName = theMessage.buddy.account.username;
    
    NSString *decodedMessageString = [[OTRKit sharedInstance] decodeMessage:message recipient:friendAccount accountName:myAccountName protocol:protocol];
    if(decodedMessageString) {
        theMessage.message = [OTRUtilities stripHTML:decodedMessageString];
        [theMessage setIsEncryptedValue:NO];
    } else {
        [theMessage setIsEncryptedValue:YES];
    }
        
    
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];

    OTRKitMessageState messageState = [[OTRKit sharedInstance] messageStateForUsername:friendAccount accountName:myAccountName protocol:protocol];
    [theMessage.buddy setNewEncryptionStatus:messageState];
}


+(OTRManagedMessage*) encodeMessage:(OTRManagedMessage*)theMessage;
{
    NSString *message = theMessage.message;
    NSString *recipientAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.account.protocol;
    NSString *sendingAccount = theMessage.buddy.account.username;
    //theMessage.isEncryptedValue = NO;
    
    NSString *encodedMessageString = [[OTRKit sharedInstance] encodeMessage:message recipient:recipientAccount accountName:sendingAccount protocol:protocol];
    
    OTRManagedMessage *newOTRMessage = [OTRManagedMessage newMessageToBuddy:theMessage.buddy message:encodedMessageString encrypted:YES];
    newOTRMessage.date = theMessage.date;
    newOTRMessage.uniqueID = theMessage.uniqueID;
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
    return newOTRMessage;
}


@end
