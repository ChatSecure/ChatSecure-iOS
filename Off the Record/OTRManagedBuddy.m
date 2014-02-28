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
#import "OTRXMPPManager.h"
#import "OTRManagedStatus.h"
#import "OTRManagedEncryptionStatusMessage.h"
#import "OTRManagedGroup.h"

#import "OTRLog.h"

@interface OTRManagedBuddy()
@end

@implementation OTRManagedBuddy

-(BOOL)protocolIsXMPP
{
    OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
    id<OTRProtocol> protocol = [protocolManager protocolForAccount:self.account];
    if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
        return YES;
    }
    return NO;
}

-(void)sendComposingChatState
{
    if([self protocolIsXMPP])
    {
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        OTRXMPPManager * protocol = (OTRXMPPManager *)[protocolManager protocolForAccount:self.account];
        [protocol sendChatState:kOTRChatStateComposing withBuddyID:self.objectID];
    }
}

-(void)sendActiveChatState
{
    if([self protocolIsXMPP])
    {
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        OTRXMPPManager * protocol = (OTRXMPPManager *)[protocolManager protocolForAccount:self.account];
        [protocol sendChatState:kOTRChatStateActive withBuddyID:self.objectID];
    }
}
-(void)sendInactiveChatState
{
    if([self protocolIsXMPP])
    {
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        OTRXMPPManager * protocol = (OTRXMPPManager *)[protocolManager protocolForAccount:self.account];
        [protocol sendChatState:kOTRChatStateInactive withBuddyID:self.objectID];
    }
}
-(void)invalidatePausedChatStateTimer
{
    if([self protocolIsXMPP])
    {
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        OTRXMPPManager * protocol = (OTRXMPPManager *)[protocolManager protocolForAccount:self.account];
        [[protocol pausedChatStateTimerForBuddyObjectID:self.objectID] invalidate];
        
    }
    
}
-(void)invalidateInactiveChatStateTimer
{
    if([self protocolIsXMPP])
    {
        OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
        OTRXMPPManager * protocol = (OTRXMPPManager *)[protocolManager protocolForAccount:self.account];
        [[protocol inactiveChatStateTimerForBuddyObjectID:self.objectID] invalidate];
    }
}

-(void)receiveChatStateMessage:(OTRChatState) newChatState
{
    self.chatStateValue = newChatState;
}

-(void)setNewEncryptionStatus:(OTRKitMessageState)newEncryptionStatus inContext:(NSManagedObjectContext *)context
{
    OTRManagedEncryptionStatusMessage * currentEncryptionStatus = [self currentEncryptionStatusInContext:context];
    
    if(newEncryptionStatus != currentEncryptionStatus.statusValue)
    {
        __block NSString * displayName = self.displayName;
        if (!displayName.length) {
            displayName = self.accountName;
        }
        if (newEncryptionStatus != kOTRKitMessageStateEncrypted && currentEncryptionStatus.statusValue == kOTRKitMessageStateEncrypted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:SECURITY_WARNING_STRING message:[NSString stringWithFormat:CONVERSATION_NO_LONGER_SECURE_STRING, displayName] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil] show];
            });
        }
        [OTRManagedEncryptionStatusMessage newEncryptionStatus:newEncryptionStatus buddy:self inContext:context];
    }
}

- (void)newStatusMessage:(NSString *)newStatusMessage status:(OTRBuddyStatus)newStatus incoming:(BOOL)isIncoming inContext:(NSManagedObjectContext *)context
{
    OTRManagedStatus * currentManagedStatus = [self currentStatusMessage];
    
    if (!currentManagedStatus) {
        [OTRManagedStatus newStatus:newStatus withMessage:newStatusMessage withBuddy:self incoming:isIncoming inContext:context];
        self.currentStatusValue = newStatus;
        return;
    }
    
    if (![newStatusMessage length]) {
        newStatusMessage = [OTRManagedStatus statusMessageWithStatus:newStatus];
    }
    
    //Make sure the status message is unique compared to the last status message
    if (newStatus != currentManagedStatus.statusValue || ![newStatusMessage isEqualToString:currentManagedStatus.message]) {
        
        NSPredicate * messageDateFilter = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date <= %@)",currentManagedStatus.date,[NSDate date]];
        NSArray * managedMessages = [OTRManagedMessage MR_findAllWithPredicate:messageDateFilter inContext:context];
        
        //if no new messages since last status update just change the most recent status
        if (![managedMessages count]) {
            [currentManagedStatus updateStatus:newStatus withMessage:newStatusMessage incoming:isIncoming];
            self.currentStatusValue = newStatus;
        }
        else
        {
            [OTRManagedStatus newStatus:newStatus withMessage:newStatusMessage withBuddy:self incoming:isIncoming inContext:context];
        }
        self.currentStatusValue = newStatus;
    }
    else
    {
        self.currentStatusValue = currentManagedStatus.statusValue;
    }
}

-(OTRManagedStatus *)currentStatusMessage
{
    NSSortDescriptor * dateSort = [NSSortDescriptor sortDescriptorWithKey:OTRManagedMessageAndStatusAttributes.date ascending:NO];
    NSArray * sortedStatuses = [self.statuses sortedArrayUsingDescriptors:@[dateSort]];
    
    if ([sortedStatuses count]) {
        return [sortedStatuses firstObject];
    }
    return nil;    
}

- (OTRManagedEncryptionStatusMessage *)fetchLastEncryptionStatusMessage
{
    NSSortDescriptor * dateSort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSArray * sortedStatuses = [self.encryptionStatusMessages sortedArrayUsingDescriptors:@[dateSort]];
    
    if ([sortedStatuses count]) {
        return [sortedStatuses firstObject];
    }
    return nil;
}

-(OTRManagedEncryptionStatusMessage *)currentEncryptionStatusInContext:(NSManagedObjectContext *)context
{
    OTRManagedEncryptionStatusMessage * encryptionStatusMessage = [self fetchLastEncryptionStatusMessage];
    if (!encryptionStatusMessage) {
        encryptionStatusMessage = [OTRManagedEncryptionStatusMessage newEncryptionStatus:kOTRKitMessageStatePlaintext buddy:self inContext:context];
    }
    return encryptionStatusMessage;
}

- (OTRKitMessageState)currentEncryptionStatus
{
    OTRManagedEncryptionStatusMessage * encryptionStatusMessage = [self fetchLastEncryptionStatusMessage];
    if (encryptionStatusMessage) {
        return encryptionStatusMessage.statusValue;
    }
    return kOTRKitMessageStatePlaintext;
}

-(NSInteger) numberOfUnreadMessages
{
    NSPredicate * messageFilter = [NSPredicate predicateWithFormat:@"isRead == NO AND isEncrypted == NO AND isIncoming == YES"];
    NSSet * finalSet = [self.messages filteredSetUsingPredicate:messageFilter];
    return [finalSet count];
}

- (void) allMessagesRead
{
    [self.messages setValue:[NSNumber numberWithBool:YES] forKey:@"isRead"];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
            DDLogError(@"Error saving all messages read to persistent store %@", error.userInfo);
        }
    }];
}

- (void) deleteAllMessagesInContext:(NSManagedObjectContext *)context
{
    NSPredicate * messageFilter = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedMessageAndStatusRelationships.buddy,self];
    NSPredicate * notLastStatusFilter = [NSPredicate predicateWithFormat:@"self != %@",[self currentStatusMessage]];
    NSPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[messageFilter,notLastStatusFilter]];
    
    [OTRManagedMessageAndStatus MR_deleteAllMatchingPredicate:compoundPredicate inContext:context];
}

-(void)addToGroup:(NSString *)groupName inContext:(NSManagedObjectContext *)context
{
    OTRManagedGroup * managedGroup = [OTRManagedGroup fetchOrCreateWithName:groupName inContext:context];
    [self addGroupsObject:managedGroup];
}

-(NSArray *)groupNames
{
    NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:OTRManagedGroupAttributes.name ascending:YES];
    return [[self.groups sortedArrayUsingDescriptors:@[descriptor]] valueForKey:OTRManagedGroupAttributes.name];
}

+(instancetype)fetchOrCreateWithName:(NSString *)name account:(OTRManagedAccount *)account inContext:(NSManagedObjectContext *)context
{
    OTRManagedBuddy * buddy = nil;
    OTRManagedAccount * contextAccount = [account MR_inContext:context];
    buddy = [self fetchWithName:name account:account inContext:context];
    if (!buddy) {
        buddy = [self MR_createInContext:context];
        NSError *error = nil;
        [context obtainPermanentIDsForObjects:@[buddy] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for buddy: %@", error);
        }
        buddy.accountName = name;
        buddy.account = contextAccount;
    }
    return buddy;
}

+(instancetype)fetchWithName:(NSString *)name account:(OTRManagedAccount *)account inContext:(NSManagedObjectContext *)context;
{
    OTRManagedAccount * contextAccount = [account MR_inContext:context];
    NSPredicate * accountPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedBuddyRelationships.account,contextAccount];
    NSPredicate * usernamePredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedBuddyAttributes.accountName,name];
    
    NSArray * filteredArray = [self MR_findAllWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[usernamePredicate,accountPredicate]]];
    
    if([filteredArray count])
    {
        OTRManagedBuddy * buddy =  [filteredArray firstObject];
        return [buddy MR_inContext:context];
    }
    return nil;
}

@end
