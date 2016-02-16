//
//  OTRXMPPLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginHandler.h"
#import "OTRXMPPManager.h"
#import "XLForm.h"
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "OTRPasswordGenerator.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "XMPPJID.h"

@interface OTRXMPPLoginHandler()
@property (nonatomic, strong) NSString *password;
@end

@implementation OTRXMPPLoginHandler

- (void)moveAccountValues:(OTRXMPPAccount *)account intoForm:(XLFormDescriptor *)form
{
    XLFormRowDescriptor *usernameRow = [form formRowWithTag:kOTRXLFormUsernameTextFieldTag];
    if (!usernameRow.value) {
        NSDictionary *username = [OTRUsernameCell createRowDictionaryValueForUsername:account.username domain:account.domain];
        usernameRow.value = username;
    }
    [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] setValue:account.password];
    [[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] setValue:@(account.rememberPassword)];
    [[form formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] setValue:@(account.autologin)];
    [[form formRowWithTag:kOTRXLFormHostnameTextFieldTag] setValue:account.domain];
    
    if (account.port != [OTRXMPPAccount defaultPort]) {
        [[form formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:@(account.port)];
    } else {
        [[form formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:nil];
    }
    
    [[form formRowWithTag:kOTRXLFormResourceTextFieldTag] setValue:account.resource];
}

- (OTRXMPPAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account
{
    NSString *nickname = [[form formRowWithTag:kOTRXLFormNicknameTextFieldTag] value];
    id usernameValue = [[form formRowWithTag:kOTRXLFormUsernameTextFieldTag] value];
    
    NSString *username = nil;
    if ([usernameValue isKindOfClass:[NSDictionary class]]) {
        username = usernameValue[OTRUsernameCell.UsernameKey];
        if (!username.length) {
            // strip whitespace and make nickname lowercase
            // TODO - replace with hexified Ed25519 identity key
            username = [nickname stringByReplacingOccurrencesOfString:@" " withString:@""];
            username = [username lowercaseString];
        }
    } else if ([usernameValue isKindOfClass:[NSString class]]) {
        NSArray *components = [usernameValue componentsSeparatedByString:@"@"];
        username = [components firstObject];
    }
    account.username = username;
    
    NSNumber *rememberPassword = [[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] value];
    if (rememberPassword) {
        account.rememberPassword = [rememberPassword boolValue];
    } else {
        account.rememberPassword = YES;
    }
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    if (password && password.length > 0) {
        self.password = password;
    } else {
        // No password in field, generate strong password for user
        self.password = [OTRPasswordGenerator passwordWithLength:20];
    }
    
    NSNumber *autologin = [[form formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] value];
    if (autologin) {
        account.autologin = [autologin boolValue];
    } else {
        account.autologin = YES;
    }
    // Don't login automatically for Tor accounts
    if (account.accountType == OTRAccountTypeXMPPTor) {
        account.autologin = NO;
    }
    
    NSString *hostname = [[form formRowWithTag:kOTRXLFormHostnameTextFieldTag] value];
    NSNumber *port = [[form formRowWithTag:kOTRXLFormPortTextFieldTag] value];
    NSString *resource = [[form formRowWithTag:kOTRXLFormResourceTextFieldTag] value];
    
    if ([hostname length]) {
        account.domain = hostname;
    }
    
    if (port) {
        account.port = [port intValue];
    }
    
    if ([resource length]) {
        account.resource = resource;
    }
    
    // Post-process values via XMPPJID for stringprep
    
    NSString *domain = account.domain;
    if (![domain length]) {
        id usernameValue = [[form formRowWithTag:kOTRXLFormUsernameTextFieldTag] value];
        if ([usernameValue isKindOfClass:[NSDictionary class]]) {
            domain = usernameValue[OTRUsernameCell.DomainKey];
        } else if ([usernameValue isKindOfClass:[NSString class]]) {
            NSArray *components = [usernameValue componentsSeparatedByString:@"@"];
            domain = [components lastObject];
        }
    }
    
    XMPPJID *jid = [XMPPJID jidWithUser:username domain:domain resource:account.resource];
    if (!jid) {
        NSParameterAssert(jid != nil);
        NSLog(@"Error creating JID from account values!");
    }
    account.username = jid.bare;
    account.resource = jid.resource;
    
    // Start generating our OTR key here so it's ready when we need it
    
    [[OTRProtocolManager sharedInstance].encryptionManager.otrKit generatePrivateKeyForAccountName:account.username protocol:kOTRProtocolTypeXMPP completion:^(NSString *fingerprint, NSError *error) {
        NSParameterAssert(fingerprint.length > 0);
        if (fingerprint.length) {
            NSLog(@"Fingerprint generated for %@: %@", jid.bare, fingerprint);
        } else {
            NSLog(@"Error generating fingerprint for %@: %@", jid.bare, error);
        }
    }];
    
    return account;
}

#pragma - mark OTRBaseLoginViewController

- (void)prepareForXMPPConnectionFrom:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account
{
    if (form) {
        account = (OTRXMPPAccount *)[self moveValues:form intoAccount:account];
    }
    
    //Reffresh protocol manager for new account settings
    [[OTRProtocolManager sharedInstance] removeProtocolForAccount:account];
    _xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:OTRXMPPLoginStatusNotificationName object:self.xmppManager];
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    self.completion = completion;
    [self prepareForXMPPConnectionFrom:form account:account];
    
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    [self.xmppManager connectWithPassword:password userInitiated:YES];
}

- (void)receivedNotification:(NSNotification *)notification
{
    OTRLoginStatus newStatus = [notification.userInfo[OTRXMPPNewLoginStatusKey] integerValue];
    NSError *error = notification.userInfo[OTRXMPPLoginErrorKey];
    OTRAccount *account = self.xmppManager.account;

    if (newStatus == OTRLoginStatusAuthenticated) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // Account has been created, so save the password
        account.password = self.password;
        
        if (self.completion) {
            self.completion(account,nil);
        }
    }
    else if (error) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (self.completion) {
            self.completion(account,error);
        }
    }
}

@end
