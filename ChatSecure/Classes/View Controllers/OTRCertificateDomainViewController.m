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
@import OTRAssets;


@interface OTRCertificateDomainViewController ()

@property (nonatomic, strong) NSDictionary * certificateDictionary;
@property (nonatomic, strong) NSArray * certificateDomains;

@end

@implementation OTRCertificateDomainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshData];
    
    [self.tableView reloadData];
}

-(void)refreshData
{
    self.certificateDictionary = [OTRCertificatePinning allCertificates];
    self.certificateDomains = [[self.certificateDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    if ([self.certificateDomains count]) {
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
    
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return YES;
    }
    return NO;
}
         

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    if ([self.certificateDomains count]) {
        count +=1;
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return SAVED_CERTIFICATES_STRING();
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.certificateDomains count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
   NSString * tableViewCellIdentifier = @"tableViewCellIdentifier";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCellIdentifier];
    }
    
    cell.textLabel.text = self.certificateDomains[indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString * hostname = nil;
    NSArray * certArray = nil;
    BOOL canEdit = YES;
    
    hostname = self.certificateDomains[indexPath.row];
    certArray = self.certificateDictionary[hostname];
    
    OTRCertificatesViewController * viewController = [[OTRCertificatesViewController alloc] initWithHostName:hostname withCertificates:certArray];
    viewController.canEdit = canEdit;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [OTRCertificatePinning deleteAllCertificatesWithHostName:self.certificateDomains[indexPath.row]];
        
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
