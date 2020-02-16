//
//  OTRXMPPCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountHandler.h"
#import "OTRXMPPManager.h"
@import XLForm;
@import CPAProxy;
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "XMPPServerInfoCell.h"
@import XMPPFramework;
#import "OTRXMPPManager.h"
#import "OTRXMPPServerInfo.h"
#import "OTRPasswordGenerator.h"
#import "OTRTorManager.h"


@implementation OTRXMPPCreateAccountHandler

- (OTRXMPPAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account
{
    account = (OTRXMPPAccount *)[super moveValues:form intoAccount:account];
    OTRXMPPServerInfo *serverInfo = [[form formRowWithTag:kOTRXLFormXMPPServerTag] value];
    
    NSString *username = nil;
    if ([account.username containsString:@"@"]) {
        NSArray *components = [account.username componentsSeparatedByString:@"@"];
        username = components[0];
    } else {
        username = account.username;
    }
    
    NSString *domain = serverInfo.domain;
    
    //Create valid 'username' which is a bare jid (user@domain.com)
    XMPPJID *jid = [XMPPJID jidWithUser:username domain:domain resource:nil];
    
    if (jid) {
        account.username = [jid bare];
    }
    
    return account;
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account progress:(void (^)(NSInteger, NSString *))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    if (form) {
        account = (OTRXMPPAccount *)[super moveValues:form intoAccount:(OTRXMPPAccount*)account];
    }
    self.completion = completion;
    
    if (account.accountType == OTRAccountTypeXMPPTor) {
        //check tor is running
        if ([OTRTorManager sharedInstance].torManager.status == CPAStatusOpen) {
            [self finishRegisteringWithForm:form account:account];
        } else if ([OTRTorManager sharedInstance].torManager.status == CPAStatusClosed) {
            [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
                
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(account,error);
                    });
                } else {
                    [self finishRegisteringWithForm:form account:account];
                }
            } progress:progress];
        }
    } else {
        [self finishRegisteringWithForm:form account:account];
    }
}

- (void) finishRegisteringWithForm:(XLFormDescriptor *)form account:(OTRAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:(OTRXMPPAccount *)account];
    XLFormRowDescriptor *passwordRow = [form formRowWithTag:kOTRXLFormPasswordTextFieldTag];
    NSString *passwordFromForm = [passwordRow value];
    NSString *password = nil;
    if (passwordRow.sectionDescriptor.isHidden == NO &&
        passwordRow.isHidden == NO &&
        passwordFromForm.length > 0) {
        password = passwordFromForm;
    } else {
        // if no password provided, generate a strong one
        password = [OTRPasswordGenerator passwordWithLength:11];
    }
    account.password = password;
    [self.xmppManager startRegisteringNewAccount];
}

@end
