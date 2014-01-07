//
//  OTRCreateAccountChooserViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCreateAccountChooserViewController.h"
#import "OTRXMPPCreateViewController.h"

@interface OTRCreateAccountChooserViewController ()

@end

@implementation OTRCreateAccountChooserViewController

- (NSArray*)accounts
{
    return @[[OTRNewAccountViewController XMPPCellDictionary],
             [OTRNewAccountViewController XMPPTorCellDictionary]];
}

- (void)didSelectAccountType:(OTRAccountType)accountType
{
    if (!(accountType == OTRAccountTypeJabber || accountType == OTRAccountTypeXMPPTor)) {
        return;
    }
    NSArray * hostnamesArray = nil;
    OTRManagedXMPPAccount * newAccount = (OTRManagedXMPPAccount *)[OTRManagedAccount accountForAccountType:accountType];
    if(accountType == OTRAccountTypeJabber)
    {
        hostnamesArray = @[@"normalXmpp.biz",@"jabber.ccc.de"];
    }
    else if (accountType == OTRAccountTypeXMPPTor)
    {
        hostnamesArray = @[@"tor+XMPP.biz",@"jabber.ccc.de"];
    }
    
    if ([hostnamesArray count]) {
        OTRXMPPCreateViewController * createViewController = [OTRXMPPCreateViewController createViewControllerWithHostnames:hostnamesArray];
        createViewController.account = newAccount;
        [self.navigationController pushViewController:createViewController animated:YES];
    }
}

@end
