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

#define kAIMImageName @"aim.png"
#define kGTalkImageName @"gtalk.png"

@implementation OTRAccount
@synthesize username, domain, protocol, password, rememberPassword, uniqueIdentifier, isConnected, imageName;

- (void) dealloc {
    self.username = nil;
    self.domain = nil;
    self.protocol = nil;
    self.password = nil;
    uniqueIdentifier = nil;
    imageName = nil;
}

- (id) initWithUsername:(NSString*)newUsername domain:(NSString*)newDomain protocol:(NSString*)newProtocol {
    if (self = [super init]) {
        self.username = newUsername;
        self.domain = newDomain;
        self.protocol = newProtocol;
        self.rememberPassword = NO;
        self.isConnected = NO;
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        NSString* uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        uniqueIdentifier = uuidString;
        
        if ([protocol isEqualToString:kOTRProtocolTypeAIM]) {
            imageName = kAIMImageName;
        } else if ([protocol isEqualToString:kOTRProtocolTypeXMPP]) {
            // TODO: check domain and show different images for custom XMPP and Facebook
            imageName = kGTalkImageName;
        }
    }
    return self;
}

- (id) initWithSettingsDictionary:(NSDictionary *)dictionary uniqueIdentifier:(NSString*) uniqueID {
    if (self = [super init]) {
        self.username = [dictionary objectForKey:kOTRAccountUsernameKey];
        self.domain = [dictionary objectForKey:kOTRAccountDomainKey];
        self.rememberPassword = [[dictionary objectForKey:kOTRAccountRememberPasswordKey] boolValue];
        imageName = [dictionary objectForKey:kOTRAccountImageKey];
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
    if (!rememberPassword) {
        username = newUsername;
        self.password = nil;
        return;
    }
    NSString *tempPassword = self.password;    
    self.password = nil;
    username = newUsername;
    self.password = tempPassword;
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
    NSMutableDictionary *accountDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    [accountDictionary setObject:self.username forKey:kOTRAccountUsernameKey];
    [accountDictionary setObject:self.domain forKey:kOTRAccountDomainKey];
    [accountDictionary setObject:self.protocol forKey:kOTRAccountProtocolKey];
    [accountDictionary setObject:[NSNumber numberWithBool:self.rememberPassword] forKey:kOTRAccountRememberPasswordKey];
    [accountDictionary setObject:self.imageName forKey:kOTRAccountImageKey];
    [accountsDictionary setObject:accountDictionary forKey:self.uniqueIdentifier];
    BOOL synchronized = [defaults synchronize];
    if (!synchronized) {
        NSLog(@"Error saving account: %@", self.username);
    }
}


@end
