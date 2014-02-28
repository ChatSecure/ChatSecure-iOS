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
#import "OTRManagedXMPPTorAccount.h"

#import "OTRLog.h"

NSString *const OTRAccountProtocolKey         = @"kOTRAccountProtocolKey";
NSString *const OTRAccountRememberPasswordKey = @"kOTRAccountRememberPasswordKey";

NSString *const OTRAimImageName               = @"aim.png";
NSString *const OTRGoogleTalkImageName        = @"gtalk.png";
NSString *const OTRFacebookImageName          = @"facebook.png";
NSString *const OTRXMPPImageName              = @"xmpp.png";
NSString *const OTRXMPPTorImageName           = @"xmpp_tor.png";

NSString *const kOTRClassKey                     = @"classKey";

@interface OTRManagedAccount()
@end

@implementation OTRManagedAccount

- (UIImage*) accountImage {
    return nil;
}

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
    
    dictionary[kOTRClassKey] = NSStringFromClass([self class]);
    
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
    return OTRXMPPImageName;
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

- (void)prepareBuddiesandMessagesForDeletionInContext:(NSManagedObjectContext*)context
{
    NSSet *buddySet = [self.buddies copy];
    for(OTRManagedBuddy * buddy in buddySet)
    {
        OTRManagedBuddy *localBuddy = [buddy MR_inContext:context];
        NSPredicate * messageFilter = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedMessageRelationships.buddy,self];
        [OTRManagedMessage MR_deleteAllMatchingPredicate:messageFilter inContext:context];
        [localBuddy MR_deleteInContext:context];
    }
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
    NSString * className = dictionary[kOTRClassKey];
    OTRManagedAccount * account = nil;
    if (className) {
        account = [NSClassFromString(className) insertInManagedObjectContext:context];
        
        NSMutableDictionary * attributesDict = [dictionary mutableCopy];
        [attributesDict removeObjectForKey:kOTRClassKey];
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

+(OTRManagedAccount *)accountForAccountType:(OTRAccountType)accountType inContext:(NSManagedObjectContext *)context
{
    
    OTRManagedAccount * newAccount = nil;
    if(accountType == OTRAccountTypeFacebook)
    {
        //Facebook
        OTRManagedFacebookAccount * facebookAccount = [OTRManagedFacebookAccount MR_createInContext:context];
        [facebookAccount setDefaultsWithDomain:kOTRFacebookDomain];
        newAccount = facebookAccount;
    }
    else if(accountType == OTRAccountTypeGoogleTalk)
    {
        //Google Chat
        OTRManagedGoogleAccount * googleAccount = [OTRManagedGoogleAccount MR_createInContext:context];
        [googleAccount setDefaultsWithDomain:kOTRGoogleTalkDomain];
        newAccount = googleAccount;
    }
    else if(accountType == OTRAccountTypeJabber)
    {
        //Jabber
        OTRManagedXMPPAccount * jabberAccount = [OTRManagedXMPPAccount MR_createInContext:context];
        [jabberAccount setDefaultsWithDomain:@""];
        newAccount = jabberAccount;
    }
    else if(accountType == OTRAccountTypeAIM)
    {
        //Aim
        OTRManagedOscarAccount * aimAccount = [OTRManagedOscarAccount MR_createInContext:context];
        [aimAccount setDefaultsWithProtocol:kOTRProtocolTypeAIM];
        newAccount = aimAccount;
    }
    else if (accountType == OTRAccountTypeXMPPTor)
    {
        //TOR + XMPP
        OTRManagedXMPPTorAccount * torAccount = [OTRManagedXMPPTorAccount MR_createEntity];
        [torAccount setDefaultsWithDomain:@""];
        newAccount = torAccount;
    }
    if(newAccount)
    {
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    }
    return newAccount;
}

@end
