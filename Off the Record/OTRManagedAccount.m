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

#import "OTRManagedFacebookAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "OTRManagedOscarAccount.h"
#import "OTRLog.h"

@interface OTRManagedAccount()
@end

@implementation OTRManagedAccount

- (void) setDefaultsWithProtocol:(NSString*)newProtocol {
    self.username = @"";
    self.protocol = newProtocol;
    self.rememberPasswordValue = NO;
    self.uniqueIdentifier = [OTRUtilities uniqueString];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    NSArray * attributes = [self.entity.attributesByName allKeys];
    
    dictionary[kClassKey] = NSStringFromClass([self class]);
    
    [attributes enumerateObjectsUsingBlock:^(NSString * attributeName, NSUInteger idx, BOOL *stop) {
        
        NSObject* attributeValue = [self valueForKey:attributeName];
        if (attributeValue) {
            dictionary[attributeName] = attributeValue;
        }
    }];
    
    return dictionary;
}

// Default, this will be overridden in subclasses
- (NSString *) imageName {
    return kXMPPImageName;
}

- (void) setPassword:(NSString *)newPassword {
    if (!newPassword || [newPassword isEqualToString:@""] || !self.rememberPasswordValue) {
        NSError *error = nil;
        [SSKeychain deletePasswordForService:kOTRServiceName account:self.uniqueIdentifier error:&error];
        if (error) {
            DDLogError(@"Error deleting password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        return;
    }
    NSError *error = nil;
    [SSKeychain setPassword:newPassword forService:kOTRServiceName account:self.uniqueIdentifier error:&error];
    if (error) {
        DDLogError(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
}

- (NSString*) password {
    if (!self.rememberPassword) {
        return nil;
    }
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kOTRServiceName account:self.uniqueIdentifier error:&error];
    if (error) {
        DDLogError(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    return password;
}

- (void) setRememberPasswordValue:(BOOL)remember {
    [super setRememberPasswordValue: remember];
    if (!self.rememberPasswordValue) {
        self.password = nil;
    }
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

- (BOOL)isConnected
{
    return [[OTRProtocolManager sharedInstance] isAccountConnected:self];
}

-(void)setAllBuddiesStatuts:(OTRBuddyStatus)status inContext:(NSManagedObjectContext *)context
{
    OTRManagedAccount * localAccount = [self MR_inContext:context];
    for (OTRManagedBuddy * buddy in localAccount.buddies)
    {
        if(buddy.currentStatusValue != status) {
            [buddy newStatusMessage:nil status:status incoming:NO inContext:context];
            if (status == OTRBuddyStatusOffline) {
                [buddy setNewEncryptionStatus:kOTRKitMessageStatePlaintext inContext:context];
                buddy.chatStateValue = kOTRChatStateActive;
            }
        }
        [context MR_saveToPersistentStoreAndWait];
    }
}

-(void)deleteAllAccountMessagesInContext:(NSManagedObjectContext *)context
{
    for (OTRManagedBuddy * buddy in self.buddies)
    {
        [buddy deleteAllMessagesInContext:context];
    }
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

-(OTRAccountType)accountType
{
    return OTRAccountTypeNone;
}

+(void)resetAccountsConnectionStatus
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    NSArray * allAccountsArray = [OTRManagedAccount MR_findAllInContext:context];
    
    for (OTRManagedAccount * managedAccount in allAccountsArray)
    {
        if (!managedAccount.isConnected) {
            [managedAccount setAllBuddiesStatuts:OTRBuddyStatusOffline inContext:context];
        }
    }
    
    [context MR_saveToPersistentStoreAndWait];
    
}

+ (instancetype)createWithDictionary:(NSDictionary *)dictionary forContext:(NSManagedObjectContext *)context
{
    NSString * className = dictionary[kClassKey];
    OTRManagedAccount * account = nil;
    if (className) {
        account = [NSClassFromString(className) insertInManagedObjectContext:context];
        
        NSMutableDictionary * attributesDict = [dictionary mutableCopy];
        [attributesDict removeObjectForKey:kClassKey];
        [attributesDict enumerateKeysAndObjectsUsingBlock:^(NSString * key, id obj, BOOL *stop) {
            @try {
                [account setValue:obj forKey:key];
            }
            @catch (NSException *exception) {
                DDLogWarn(@"Could not set Key: %@ Value: %@ on Account",key,obj);
            }
            
        }];
    }
    return account;
}

+(OTRManagedAccount *)accountForAccountType:(OTRAccountType)accountType
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedAccount * newAccount = nil;
    if(accountType == OTRAccountTypeFacebook)
    {
        //Facebook
        OTRManagedFacebookAccount * facebookAccount = [OTRManagedFacebookAccount MR_createInContext:localContext];
        [facebookAccount setDefaultsWithDomain:kOTRFacebookDomain];
        newAccount = facebookAccount;
    }
    else if(accountType == OTRAccountTypeGoogleTalk)
    {
        //Google Chat
        OTRManagedGoogleAccount * googleAccount = [OTRManagedGoogleAccount MR_createInContext:localContext];
        [googleAccount setDefaultsWithDomain:kOTRGoogleTalkDomain];
        newAccount = googleAccount;
    }
    else if(accountType == OTRAccountTypeJabber)
    {
        //Jabber
        OTRManagedXMPPAccount * jabberAccount = [OTRManagedXMPPAccount MR_createInContext:localContext];
        [jabberAccount setDefaultsWithDomain:@""];
        newAccount = jabberAccount;
    }
    else if(accountType == OTRAccountTypeAIM)
    {
        //Aim
        OTRManagedOscarAccount * aimAccount = [OTRManagedOscarAccount MR_createInContext:localContext];
        [aimAccount setDefaultsWithProtocol:kOTRProtocolTypeAIM];
        newAccount = aimAccount;
    }
    [localContext MR_saveToPersistentStoreAndWait];
    return newAccount;
}

@end
