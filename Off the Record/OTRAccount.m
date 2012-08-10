//
//  OTRAccount.m
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
#import "OTRSettingsManager.h"
#import "SFHFKeychainUtils.h"
#define kOTRServiceName @"org.chatsecure.ChatSecure"
#import "OTRProtocol.h"
#import "OTRXMPPManager.h"
#import "OTROscarManager.h"
#import "OTRConstants.h"
#import "Strings.h"

@implementation OTRAccount
@synthesize username, protocol, password, rememberPassword, uniqueIdentifier, isConnected;

- (void) dealloc {
    self.username = nil;
    self.protocol = nil;
    self.password = nil;
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
        password = nil;
        return nil;
    }
    NSError *error = nil;
    password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:kOTRServiceName error:&error];
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
        [defaults setObject:accountsDictionary forKey:kOTRSettingAccountsKey];
    NSDictionary *accountDictionary = [self accountDictionary];
    [accountsDictionary setObject:accountDictionary forKey:self.uniqueIdentifier];
    BOOL synchronized = [defaults synchronize];
    if (!synchronized) {
        NSLog(@"Error saving account: %@", self.username);
    }
}

- (NSMutableDictionary*) accountDictionary {
    NSMutableDictionary *accountDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    [accountDictionary setObject:self.username forKey:kOTRAccountUsernameKey];
    [accountDictionary setObject:self.protocol forKey:kOTRAccountProtocolKey];
    [accountDictionary setObject:[NSNumber numberWithBool:self.rememberPassword] forKey:kOTRAccountRememberPasswordKey];
    [accountDictionary setObject:self.imageName forKey:kOTRAccountImageKey];
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
