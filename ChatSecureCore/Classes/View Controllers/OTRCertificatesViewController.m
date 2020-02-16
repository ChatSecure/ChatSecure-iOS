//
//  OTRCertificatesViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificatesViewController.h"
#import "OTRCertificatePinning.h"

@interface OTRCertificatesViewController ()

@end

@implementation OTRCertificatesViewController
{
    NSDictionary * certificatesDictionary;
    NSArray * certificateHashes;
    NSString * hostname;
}

- (id)initWithHostName:(NSString *)newHostname withCertificates:(NSArray *)certificates {
    
    if (self = [self init]) {
        self.title = newHostname;
        hostname = newHostname;
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
        newCerts = [OTRCertificatePinning storedCertificatesWithHostName:hostname];
    }
    NSMutableArray * tempHashes = [NSMutableArray array];
    NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
    [newCerts enumerateObjectsUsingBlock:^(NSData * certData, NSUInteger idx, BOOL *stop) {
        NSString * fingerPrint = [OTRCertificatePinning sha256FingerprintForCertificate:[OTRCertificatePinning certForData:certData]];
        [tempHashes addObject:fingerPrint];
        tempDict[fingerPrint] = certData;
    }];
    certificateHashes = tempHashes;
    certificatesDictionary = tempDict;
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
    return [certificateHashes count];
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
    
    cell.textLabel.text = [certificateHashes[indexPath.row] stringByReplacingOccurrencesOfString:@" " withString:@":"];
    cell.textLabel.font = [UIFont systemFontOfSize:10.0];
    cell.detailTextLabel.text = NSLocalizedString(@"SHA256", @"");
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [OTRCertificatePinning deleteCertificate:[OTRCertificatePinning certForData:certificatesDictionary[certificateHashes[indexPath.row]]] withHostName:hostname];
    }
    [self reloadCerts:nil];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
