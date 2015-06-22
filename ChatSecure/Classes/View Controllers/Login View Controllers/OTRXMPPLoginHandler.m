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
    account.username = [[form formRowWithTag:kOTRXLFormUsernameTextFieldTag] value];
    account.rememberPassword = [[[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] value] boolValue];
    account.autologin = [[[form formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] value] boolValue];
    account.password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    
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

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account completion:(void (^)(NSError *, OTRAccount *))completion
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
    
    if (newStatus == OTRLoginStatusAuthenticated) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.completion(nil,self.xmppManager.account);
    }
    else if (error) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.completion(error,self.xmppManager.account);
    }
}

@end
