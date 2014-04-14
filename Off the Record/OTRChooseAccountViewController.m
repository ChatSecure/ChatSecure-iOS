//
//  OTRChooseAccountViewController.m
//  Off the Record
//
//  Created by David on 3/7/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRChooseAccountViewController.h"

#import "OTRNewBuddyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Strings.h"
#import "OTRAccountsManager.h"
#import "OTRAccount.h"

@interface OTRChooseAccountViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation OTRChooseAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = ACCOUNT_STRING;
	
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    //self.tableView.scrollEnabled =  [self tableView:self.tableView numberOfRowsInSection:0] * 50.0 > self.tableView.frame.size.height;
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    
    [self.view addSubview: self.tableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self onlineAccounts] count];
}

-(UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"cell";
    UITableViewCell * cell = [tView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRAccount *account = [[self onlineAccounts] objectAtIndex:indexPath.row];
    OTRNewBuddyViewController * buddyViewController = [[OTRNewBuddyViewController alloc] initWithAccountId:account.uniqueId];
    [self.navigationController pushViewController:buddyViewController animated:YES];
    
    
    [tView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSArray *)onlineAccounts
{
    return [OTRAccountsManager allAccountsAbleToAddBuddies];
}

-(void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OTRAccount *account = [[self onlineAccounts] objectAtIndex:indexPath.row];
    cell.textLabel.text = account.username;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = [account accountImage];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if( account.accountType == OTRAccountTypeFacebook)
    {
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
    }
}

-(void)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
