//
//  OTRCreateAccountChooserViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCreateAccountChooserViewController.h"
#import "OTRXMPPCreateAccountViewController.h"
#import "UIAlertView+Blocks.h"
#import "OTRXMPPAccount.h"
#import "OTRDomainCellInfo.h"

@implementation OTRCreateAccountChooserViewController

- (NSArray*)accounts
{
    return @[[OTRNewAccountViewController XMPPCellDictionary],
             [OTRNewAccountViewController XMPPTorCellDictionary]];
}

- (void)didSelectAccountType:(OTRAccountType)accountType
{
    if (accountType == OTRAccountTypeXMPPTor) {
        
        RIButtonItem *okButton = [RIButtonItem itemWithLabel:OK_STRING action:^{
            [self pushCreateAccountViewControllerWithAccountType:accountType];
        }];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:SECURITY_WARNING_STRING message:TOR_WARNING_MESSAGE_STRING cancelButtonItem:okButton otherButtonItems:nil];
        [alertView show];
        
    }
    else if (accountType == OTRAccountTypeJabber)
    {
        [self pushCreateAccountViewControllerWithAccountType:accountType];
    }
    
}

- (void)pushCreateAccountViewControllerWithAccountType:(OTRAccountType)accountType
{
    NSArray * hostnamesArray = nil;
    OTRXMPPAccount * newAccount = (OTRXMPPAccount *)[OTRAccount accountForAccountType:accountType];
    
    if(accountType == OTRAccountTypeJabber) {
        hostnamesArray = [OTRDomainCellInfo defaultDomainCellInfoArray];
    }
    else if (accountType == OTRAccountTypeXMPPTor) {
        hostnamesArray = [OTRDomainCellInfo defaultTorDomainCellInfoArray];
    }
    
    if ([hostnamesArray count]) {
        OTRXMPPCreateAccountViewController * createViewController = [OTRXMPPCreateAccountViewController createViewControllerWithHostnames:hostnamesArray];
        createViewController.account = newAccount;
        [self.navigationController pushViewController:createViewController animated:YES];
    }
}

@end
