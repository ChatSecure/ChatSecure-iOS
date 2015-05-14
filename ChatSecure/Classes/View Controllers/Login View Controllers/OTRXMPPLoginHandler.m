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

@interface OTRXMPPLoginHandler ()

@property (nonatomic, strong) OTRXMPPManager *xmppManager;

@property (nonatomic, copy) void (^completion)(NSError *error, OTRAccount *account);

@end

@implementation OTRXMPPLoginHandler

- (OTRAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account
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

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account completion:(void (^)(NSError *, OTRAccount *))completion
{
    self.completion = completion;
    OTRAccount *modifiedAccount = [self moveValues:form intoAccount:account];
    self.xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:modifiedAccount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificatoin:) name:OTRXMPPLoginStatusNotificationName object:self.xmppManager];
    
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    [self.xmppManager connectWithPassword:password userInitiated:YES];
}

- (void)receivedNotificatoin:(NSNotification *)notification
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
