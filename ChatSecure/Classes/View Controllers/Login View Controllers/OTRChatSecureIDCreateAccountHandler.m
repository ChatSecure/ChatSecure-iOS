//
//  OTRChatSecureIDCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRChatSecureIDCreateAccountHandler.h"
#import "OTRXMPPServerInfo.h"
#import "OTRXMPPManager.h"
#import "OTRPasswordGenerator.h"
#import "OTRProtocolManager.h"

@interface OTRChatSecureIDCreateAccountHandler ()

@property (nonatomic, strong) NSMutableArray *serverList;
@property (nonatomic, strong) OTRXMPPAccount *account;

@end

@implementation OTRChatSecureIDCreateAccountHandler

- (instancetype)init
{
    if (self = [super init]) {
        self.serverList = [[OTRXMPPServerInfo defaultServerList] mutableCopy];
    }
    return self;
}

- (void)prepareForXMPPConnectionFrom:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account
{
    [super prepareForXMPPConnectionFrom:form account:account];
    [self moveServerInfo:[self.serverList firstObject] intoAccount:account];
    account.rememberPassword = YES;
    account.autologin = YES;
    self.account = account;
}

- (void)moveServerInfo:(OTRXMPPServerInfo *)serverInfo intoAccount:(OTRXMPPAccount *)account
{
    NSString *user = [XMPPJID jidWithString:account.username].user;
    if (![user length]) {
        user = account.username;
    }
    account.username = [XMPPJID jidWithUser:user domain:serverInfo.domain resource:nil].bare;
    account.domain = serverInfo.domain;
}

- (void)attemptToCreateAccount
{
    OTRXMPPServerInfo *serverInfo = [self.serverList firstObject];
    if (!serverInfo) {
        //error no more servers to find
    } else {
        [self performActionWithValidForm:nil account:self.account completion:self.completion];
    }
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    self.password = [OTRPasswordGenerator passwordWithLength:25];//Create random password
    [super performActionWithValidForm:form account:account completion:completion];
}
- (void)receivedNotification:(NSNotification *)notification
{
    OTRLoginStatus newStatus = [notification.userInfo[OTRXMPPNewLoginStatusKey] integerValue];
    NSError *error = notification.userInfo[OTRXMPPLoginErrorKey];
    
    if(error && [self.serverList count]) {
        //Unable to create account but there are more servers to try with
        [self.serverList removeObjectAtIndex:0];
        
        //remove old xmpp manager that is not needed anymore
        [[OTRProtocolManager sharedInstance] removeProtocolForAccount:self.account];
        
        [self attemptToCreateAccount];
    } else {
        //successfully created account
        //need to save password
        if (newStatus == OTRLoginStatusAuthenticated) {
            self.account.password = self.password;
        }
        [super receivedNotification:notification];
    }
}

@end
