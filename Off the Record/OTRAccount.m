//
//  OTRAccount.m
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

#import "OTRAccount.h"
#import "OTRSettingsManager.h"
#import "SFHFKeychainUtils.h"
#import "OTRProtocol.h"
#import "OTRXMPPManager.h"
#import "OTROscarManager.h"
#import "OTRConstants.h"
#import "Strings.h"

#define kOTRServiceName @"org.chatsecure.ChatSecure"


@implementation OTRAccount
@synthesize username, protocol, rememberPassword, uniqueIdentifier, isConnected;

- (void) dealloc {
    self.username = nil;
    self.protocol = nil;
    uniqueIdentifier = nil;
}

- (id) initWithProtocol:(NSString*)newProtocol {
    if (self = [super init]) {
        self.username = @"";
        self.protocol = newProtocol;
        self.rememberPassword = NO;
        self.isConnected = NO;
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        NSString* uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        uniqueIdentifier = uuidString;
        
        
    }
    return self;
}

// Default, this will be overridden in subclasses
- (NSString *) imageName {
    return kXMPPImageName;
}

- (id) initWithSettingsDictionary:(NSDictionary *)dictionary uniqueIdentifier:(NSString*) uniqueID {
    if (self = [super init]) {
        self.rememberPassword = [[dictionary objectForKey:kOTRAccountRememberPasswordKey] boolValue];
        self.username = [dictionary objectForKey:kOTRAccountUsernameKey];
        self.protocol = [dictionary objectForKey:kOTRAccountProtocolKey];
        uniqueIdentifier = uniqueID;
        self.isConnected = NO;
    }
    return self;
}

- (void) setPassword:(NSString *)newPassword {
    if (!newPassword || [newPassword isEqualToString:@""] || !rememberPassword) {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:kOTRServiceName error:&error];
        if (error) {
            NSLog(@"Error deleting password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        return;
    }
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:self.username andPassword:newPassword forServiceName:kOTRServiceName updateExisting:YES error:&error];
    if (error) {
        NSLog(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
}

- (NSString*) password {
    if (!rememberPassword) {
        return nil;
    }
    NSError *error = nil;
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:kOTRServiceName error:&error];
    if (error) {
        NSLog(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    return password;
}

- (void) setUsername:(NSString *)newUsername {
    NSString *oldUsername = [username copy];
    username = newUsername;
    if ([username isEqualToString:newUsername]) {
        return;
    }
    if (!rememberPassword) {
        username = newUsername;
        self.password = nil;
        return;
    }
    if (oldUsername && ![oldUsername isEqualToString:newUsername]) {
        NSString *tempPassword = self.password;    
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:oldUsername andServiceName:kOTRServiceName error:&error];
        if (error) {
            NSLog(@"Error deleting old password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        self.password = tempPassword;
    }
}

- (void) setRememberPassword:(BOOL)remember {
    rememberPassword = remember;
    if (!rememberPassword) {
        self.password = nil;
    }
}

- (void) save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *accountsDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kOTRSettingAccountsKey]];
    NSDictionary *accountDictionary = [self accountDictionary];
    [accountsDictionary setObject:accountDictionary forKey:self.uniqueIdentifier];
    [defaults setObject:accountsDictionary forKey:kOTRSettingAccountsKey];
    BOOL synchronized = [defaults synchronize];
    if (!synchronized) {
        NSLog(@"Error saving account: %@", self.username);
    }
}

- (NSMutableDictionary*) accountDictionary {
    NSMutableDictionary *accountDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    [accountDictionary setObject:self.username forKey:kOTRAccountUsernameKey];
    [accountDictionary setObject:self.protocol forKey:kOTRAccountProtocolKey];
    [accountDictionary setObject:[NSNumber numberWithBool:self.rememberPassword] forKey:kOTRAccountRememberPasswordKey];
    return accountDictionary;
}


- (Class)protocolClass {
    return nil;
}

// Overridden by subclasses
- (NSString *)providerName
{
    return @"";
}


@end
