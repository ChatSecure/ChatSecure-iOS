//
//  OTRCertificatesViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificatesViewController.h"

#import "OTRCertificatePinning.h"
#import "OTRSSLCertificate.h"
#import "OTRSSLCertificateDetailViewController.h"

@interface OTRCertificatesViewController ()

@property (nonatomic, strong) NSArray * certificates;
@property (nonatomic, strong) NSString * hostname;

@end

@implementation OTRCertificatesViewController

- (id)initWithHostName:(NSString *)newHostname withCertificates:(NSArray *)certificates {
    
    if (self = [self init]) {
        self.title = newHostname;
        self.hostname = newHostname;
        self.canEdit = YES;
        [self reloadCerts:certificates];
    }
    return self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.canEdit) {
        UIBarButtonItem * editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}

- (void)reloadCerts:(NSArray *)newCerts {
    if (![newCerts count]) {
        newCerts = [OTRCertificatePinning storedCertificatesWithHostName:self.hostname];
    }
    NSMutableArray * tempCertificates = [NSMutableArray array];
    [newCerts enumerateObjectsUsingBlock:^(NSData * certData, NSUInteger idx, BOOL *stop) {
        
        OTRSSLCertificate * sslCertificate = [OTRSSLCertificate SSLCertifcateWithData:certData];
        [tempCertificates addObject:sslCertificate];
        
    }];
    self.certificates = tempCertificates;
}

- (void)toggleEditing:(id)sender
{
    UIBarButtonItem * editButton;
    
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:YES];
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
    }
    else{
        [self.tableView setEditing:YES animated:YES];
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleEditing:)];
    }
    self.navigationItem.rightBarButtonItem = editButton;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.certificates count];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.canEdit) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * tableViewCellIdentifier = @"tableViewCellIdentifier";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:tableViewCellIdentifier];
    }
    OTRSSLCertificate * sslCertificate = self.certificates[indexPath.row];
    
    cell.textLabel.text = sslCertificate.subjectCommonName;
    cell.detailTextLabel.text = [sslCertificate.SHA1fingerprint stringByReplacingOccurrencesOfString:@" " withString:@":"];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:10.0];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTRSSLCertificate * sslCertificate = self.certificates[indexPath.row];
        [OTRCertificatePinning deleteCertificate:[OTRCertificatePinning certForData:sslCertificate.data] withHostName:self.hostname];
    }
    [self reloadCerts:nil];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTRSSLCertificate * certificate = self.certificates[indexPath.row];
    
    OTRSSLCertificateDetailViewController * detailViewController = [[OTRSSLCertificateDetailViewController alloc] initWithSSLCertificate:certificate];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
