//
//  OTRCertificateDomainViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificateDomainViewController.h"
#import "OTRCertificatePinning.h"

#import "<#header#>"

@interface OTRCertificateDomainViewController ()

@end

@implementation OTRCertificateDomainViewController
{
    NSArray * domainsArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    domainsArray = [OTRCertificatePinning all
    
    UITableView * tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.view addSubview:tableView];
}

@end
