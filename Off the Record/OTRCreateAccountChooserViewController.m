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
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    OTRManagedXMPPAccount * newAccount = (OTRManagedXMPPAccount *)[OTRManagedAccount accountForAccountType:accountType inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    if(accountType == OTRAccountTypeJabber)
    {
        hostnamesArray = self.defaultDomains;
    }
    else if (accountType == OTRAccountTypeXMPPTor)
    {
        hostnamesArray = self.defaultDomains;
    }
    
    if ([hostnamesArray count]) {
        OTRXMPPCreateAccountViewController * createViewController = [OTRXMPPCreateAccountViewController createViewControllerWithHostnames:hostnamesArray];
        createViewController.account = newAccount;
        [self.navigationController pushViewController:createViewController animated:YES];
    }
}

@end
