//
//  OTRXMPPLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPManager.h"
#import "OTRXMPPLoginHandler.h"
@import XLForm;
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "OTRPasswordGenerator.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import XMPPFramework;
#import "OTRAccount.h"
#import "OTRXMPPServerInfo.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRTorManager.h"

@interface OTRXMPPLoginHandler()
@end

@implementation OTRXMPPLoginHandler

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)moveAccountValues:(OTRXMPPAccount *)account intoForm:(XLFormDescriptor *)form
{
    if (!account) {
        return;
    }
    XLFormRowDescriptor *usernameRow = [form formRowWithTag:kOTRXLFormUsernameTextFieldTag];
    if (!usernameRow.value) {
        usernameRow.value = account.username;
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
    if (!account) {
         BOOL useTor = [[form formRowWithTag:kOTRXLFormUseTorTag].value boolValue];
        if (useTor) {
            account = [[OTRXMPPTorAccount alloc] initWithAccountType:OTRAccountTypeXMPPTor];
        } else {
            account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
        }
    }
    NSString *nickname = [[form formRowWithTag:kOTRXLFormNicknameTextFieldTag] value];
    
    XLFormRowDescriptor *usernameRow = [form formRowWithTag:kOTRXLFormUsernameTextFieldTag];
    
    NSString *jidNode = nil; // aka 'username' from username@example.com
    NSString *jidDomain = nil;

    if (![usernameRow isHidden]) {
        NSArray *components = [usernameRow.value componentsSeparatedByString:@"@"];
        if (components.count == 2) {
            jidNode = [components firstObject];
            jidDomain = [components lastObject];
        } else {
            jidNode = usernameRow.value;
        }
    }

    if (!jidNode.length) {
        // strip whitespace and make nickname lowercase
        jidNode = [nickname stringByReplacingOccurrencesOfString:@" " withString:@""];
        jidNode = [jidNode lowercaseString];
    }
    
    NSNumber *rememberPassword = [[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] value];
    if (rememberPassword) {
        account.rememberPassword = [rememberPassword boolValue];
    } else {
        account.rememberPassword = YES;
    }
    
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    
    if (password && password.length > 0) {
        account.password = password;
    } else if (account.password.length == 0) {
        // No password in field, generate strong password for user
        account.password = [OTRPasswordGenerator passwordWithLength:20];
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
    
    if (![hostname length]) {
        XLFormRowDescriptor *serverRow = [form formRowWithTag:kOTRXLFormXMPPServerTag];
        if (serverRow) {
            OTRXMPPServerInfo *serverInfo = serverRow.value;
            hostname = serverInfo.domain;
        }
    }
    account.domain = hostname;

    
    if (port) {
        account.port = [port intValue];
    }
    
    if ([resource length]) {
        account.resource = resource;
    }
    
    // Post-process values via XMPPJID for stringprep
    
    if (!jidDomain.length) {
        jidDomain = account.domain;
    }
    
    XMPPJID *jid = [XMPPJID jidWithUser:jidNode domain:jidDomain resource:account.resource];
    if (!jid) {
        NSParameterAssert(jid != nil);
        NSLog(@"Error creating JID from account values!");
    }
    account.username = jid.bare;
    account.resource = jid.resource;
    account.displayName = nickname;
    
    // Use server's .onion if possible, else use FQDN
    if (account.accountType == OTRAccountTypeXMPPTor) {
        OTRXMPPServerInfo *serverInfo = [[form formRowWithTag:kOTRXLFormXMPPServerTag] value];
        OTRXMPPTorAccount *torAccount = (OTRXMPPTorAccount*)account;
        torAccount.onion = serverInfo.onion;
        if (torAccount.onion.length) {
            torAccount.domain = torAccount.onion;
        } else if (serverInfo.server.length) {
            torAccount.domain = serverInfo.server;
        }
    }
    
    // Start generating our OTR key here so it's ready when we need it
    
    [[OTRProtocolManager sharedInstance].encryptionManager.otrKit generatePrivateKeyForAccountName:account.username protocol:kOTRProtocolTypeXMPP completion:^(OTRFingerprint *fingerprint, NSError *error) {
        NSParameterAssert(fingerprint.fingerprint.length > 0);
        if (fingerprint.fingerprint.length > 0) {
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

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account progress:(void (^)(NSInteger progress, NSString *summaryString))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    if (form) {
        account = (OTRXMPPAccount *)[self moveValues:form intoAccount:(OTRXMPPAccount*)account];
    }
    self.completion = completion;
    
    if (account.accountType == OTRAccountTypeXMPPTor) {
        //check tor is running
        if ([OTRTorManager sharedInstance].torManager.status == CPAStatusOpen) {
            [self finishConnectingWithForm:form account:account];
        } else if ([OTRTorManager sharedInstance].torManager.status == CPAStatusClosed) {
            [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
                
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(account,error);
                    });
                } else {
                    [self finishConnectingWithForm:form account:account];
                }
            } progress:progress];
        }
    } else {
        [self finishConnectingWithForm:form account:account];
    }
}

- (void) finishConnectingWithForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:account];
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    if (password.length > 0) {
        account.password = password;
    }
    [self.xmppManager connectUserInitiated:YES];
}

- (void)receivedNotification:(NSNotification *)notification
{
    OTRLoginStatus newStatus = [notification.userInfo[OTRXMPPNewLoginStatusKey] integerValue];
    NSError *error = notification.userInfo[OTRXMPPLoginErrorKey];
    OTRAccount *account = self.xmppManager.account;

    if (newStatus == OTRLoginStatusAuthenticated) {
        if (self.completion) {
            self.completion(account,nil);
        }
    }
    else if (error) {
        if (self.completion) {
            self.completion(account,error);
        }
    }
}

@end
