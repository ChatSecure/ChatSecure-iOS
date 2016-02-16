//
//  OTRXMPPCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountHandler.h"
#import "OTRXMPPManager.h"
#import "XLForm.h"
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "XMPPServerInfoCell.h"
#import "XMPPJID.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPServerInfo.h"
#import "OTRPasswordGenerator.h"

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

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    self.completion = completion;
    [self prepareForXMPPConnectionFrom:form account:(OTRXMPPAccount *)account];
    
    XLFormRowDescriptor *passwordRow = [form formRowWithTag:kOTRXLFormPasswordTextFieldTag];
    NSString *passwordFromForm = [passwordRow value];
    if (passwordRow.sectionDescriptor.isHidden == NO &&
        passwordRow.isHidden == NO &&
        passwordFromForm.length > 0) {
        _password = passwordFromForm;
    } else {
        // if no password provided, generate a strong one
        _password = [OTRPasswordGenerator passwordWithLength:11];
    }
    
    [self.xmppManager registerNewAccountWithPassword:self.password];
}

@end
