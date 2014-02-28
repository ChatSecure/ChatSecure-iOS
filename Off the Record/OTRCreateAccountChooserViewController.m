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

@property (nonatomic,strong) NSArray * defaultDomains;

@end

@implementation OTRCreateAccountChooserViewController

- (id)init
{
    if (self = [super init]) {
        self.defaultDomains = @[@"dukgo.com",@"jabber.ccc.de",@"jabberpl.org",@"neko.im",@"rkquery.de",@"xmpp.jp"];
    }
    return self;
}

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
        hostnamesArray = self.defaultDomains;
    }
    else if (accountType == OTRAccountTypeXMPPTor)
    {
        hostnamesArray = self.defaultDomains;
    }
    
    if ([hostnamesArray count]) {
        OTRXMPPCreateViewController * createViewController = [OTRXMPPCreateViewController createViewControllerWithHostnames:hostnamesArray];
        createViewController.account = newAccount;
        [self.navigationController pushViewController:createViewController animated:YES];
    }
}

@end
