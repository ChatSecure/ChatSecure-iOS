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

@interface OTRXMPPLoginHandler()
@property (nonatomic, strong) NSString *password;
@end

@implementation OTRXMPPLoginHandler

- (void)moveAccountValues:(OTRXMPPAccount *)account intoForm:(XLFormDescriptor *)form
{
    [[form formRowWithTag:kOTRXLFormUsernameTextFieldTag] setValue:account.username];
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
    NSString *username = [[form formRowWithTag:kOTRXLFormUsernameTextFieldTag] value];
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
    
    return account;
}

#pragma - mark OTRBaseLoginViewController

- (void)prepareForXMPPConnectionFrom:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account
{
    if (form) {
        account = (OTRXMPPAccount *)[self moveValues:form intoAccount:account];
    }
    
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
