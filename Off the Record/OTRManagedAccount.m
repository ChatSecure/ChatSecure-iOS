//
//  OTRManagedAccount.m
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

#import "OTRManagedAccount.h"
#import "OTRSettingsManager.h"
#import "SSKeychain.h"
#import "OTRProtocol.h"
#import "OTRXMPPManager.h"
#import "OTROscarManager.h"
#import "OTRConstants.h"
#import "Strings.h"
#import "OTRProtocolManager.h"
#import "OTRUtilities.h"

#define kOTRServiceName @"org.chatsecure.ChatSecure"

@interface OTRManagedAccount()
@end

@implementation OTRManagedAccount

- (void) setDefaultsWithProtocol:(NSString*)newProtocol {
    self.username = @"";
    self.protocol = newProtocol;
    self.rememberPassword = NO;
    self.isConnected = NO;
    self.uniqueIdentifier = [OTRUtilities uniqueString];
}

// Default, this will be overridden in subclasses
- (NSString *) imageName {
    return kXMPPImageName;
}

- (void) setPassword:(NSString *)newPassword {
    if (!newPassword || [newPassword isEqualToString:@""] || !self.rememberPassword) {
        NSError *error = nil;
        [SSKeychain deletePasswordForService:kOTRServiceName account:self.username error:&error];
        if (error) {
            NSLog(@"Error deleting password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        return;
    }
    NSError *error = nil;
    [SSKeychain setPassword:newPassword forService:kOTRServiceName account:self.username error:&error];
    if (error) {
        NSLog(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
}

- (NSString*) password {
    if (!self.rememberPassword) {
        return nil;
    }
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kOTRServiceName account:self.username error:&error];
    if (error) {
        NSLog(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    return password;
}
-(void)setNewUsername:(NSString *)newUsername
{
    NSString *oldUsername = [self.username copy];
    
    self.username = newUsername;
    
    if ([self.username isEqualToString:oldUsername]) {
        return;
    }
    if (!self.rememberPassword) {
        self.username = newUsername;
        self.password = nil;
        return;
    }
    if (oldUsername && ![oldUsername isEqualToString:newUsername]) {
        NSString *tempPassword = self.password;
        NSError *error = nil;
        [SSKeychain deletePasswordForService:oldUsername account:kOTRServiceName error:&error];
        if (error) {
            NSLog(@"Error deleting old password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        self.password = tempPassword;
    }
    
}

- (void) setRememberPasswordValue:(BOOL)remember {
    [super setRememberPasswordValue: remember];
    if (!self.rememberPassword) {
        self.password = nil;
    }
}

- (void) save {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}


// Overridden by subclasses
- (Class)protocolClass {
    return nil;
}

// Overridden by subclasses
- (NSString *)providerName
{
    return @"";
}

-(NSNumber *)isConnected
{
    
    
    return [NSNumber numberWithBool:[[OTRProtocolManager sharedInstance] isAccountConnected:self]];
}

-(void)setAllBuddiesStatuts:(OTRBuddyStatus)status
{
    for (OTRManagedBuddy * buddy in self.buddies)
    {
        [buddy newStatusMessage:nil status:status incoming:NO];
        if (status == kOTRBuddyStatusOffline) {
            [buddy setNewEncryptionStatus:kOTRKitMessageStatePlaintext];
            buddy.chatStateValue = kOTRChatStateActive;
        }
    }
    [self save];
}

-(void)deleteAllConversationsForAccount
{
    for (OTRManagedBuddy * buddy in self.buddies)
    {
        [buddy deleteAllMessages];
    }
    [self save];
}

-(void)prepareBuddiesandMessagesForDeletion
{
    NSSet *buddySet = [self.buddies copy];
    for(OTRManagedBuddy * buddy in buddySet)
    {
        NSPredicate * messageFilter = [NSPredicate predicateWithFormat:@"buddy == %@",self];
        [OTRManagedMessageAndStatus MR_deleteAllMatchingPredicate:messageFilter];
        [buddy MR_deleteEntity];
    }
    
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

+(void)resetAccountsConnectionStatus
{
    NSArray * allAccountsArray = [OTRManagedAccount MR_findAll];
    
    for (OTRManagedAccount * managedAccount in allAccountsArray)
    {
        managedAccount.isConnectedValue = [[OTRProtocolManager sharedInstance] isAccountConnected:managedAccount];
        if (!managedAccount.isConnectedValue) {
            [managedAccount setAllBuddiesStatuts:kOTRBuddyStatusOffline];
        }
        
    }
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
}

@end
