//
//  OTRCertificateDomainViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificateDomainViewController.h"
#import "OTRCertificatePinning.h"
#import "OTRCertificatesViewController.h"
#import "Strings.h"

@interface OTRCertificateDomainViewController ()

@end

@implementation OTRCertificateDomainViewController
{
    NSDictionary * certificateDictionary;
    NSDictionary * bundledCertificatesDictioanry;
    NSArray * certificateDomains;
    NSArray * bundledCertificatesDomains;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshData];
    
    
    
    [self.tableView reloadData];
}

-(void)refreshData
{
    certificateDictionary = [OTRCertificatePinning allCertificates];
    certificateDomains = [[certificateDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    bundledCertificatesDictioanry = [OTRCertificatePinning bundledCertificates];
    bundledCertificatesDomains = [[bundledCertificatesDictioanry allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    if ([certificateDomains count]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)toggleEditing:(id)sender {
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return YES;
    }
    return NO;
}
         

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    if ([certificateDomains count]) {
        count +=1;
    }
    if ([bundledCertificatesDomains count]) {
        count +=1;
    }
    return count    ;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([bundledCertificatesDomains count] && section == 0) {
        return BUNDLED_CERTIFICATES_STRING;
    }
    else {
        return SAVED_CERTIFICATES_STRING;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([bundledCertificatesDomains count] && section == 0) {
        return [bundledCertificatesDomains count];
    }
    else {
        return [certificateDomains count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
   NSString * tableViewCellIdentifier = @"tableViewCellIdentifier";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCellIdentifier];
    }
    
    if ([bundledCertificatesDomains count] && indexPath.section == 0) {
        cell.textLabel.text = bundledCertificatesDomains[indexPath.row];
    }
    else {
        cell.textLabel.text = certificateDomains[indexPath.row];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString * hostname = nil;
    NSArray * certArray = nil;
    BOOL canEdit = YES;
    if ([bundledCertificatesDomains count] && indexPath.section == 0) {
        hostname = bundledCertificatesDomains[indexPath.row];
        certArray = bundledCertificatesDictioanry[hostname];
        canEdit = NO;
    }
    else {
        hostname = certificateDomains[indexPath.row];
        certArray = certificateDictionary[hostname];
    }
    
    
    OTRCertificatesViewController * viewController = [[OTRCertificatesViewController alloc] initWithHostName:hostname withCertificates:certArray];
    viewController.canEdit = canEdit;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [OTRCertificatePinning deleteAllCertificatesWithHostName:certificateDomains[indexPath.row]];
        
        [self refreshData];
        if ([self.tableView numberOfRowsInSection:indexPath.section] == 1) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
    }
    
}

@end
