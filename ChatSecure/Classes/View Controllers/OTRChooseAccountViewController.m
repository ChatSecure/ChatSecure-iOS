//
//  OTRChooseAccountViewController.m
//  Off the Record
//
//  Created by David on 3/7/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRChooseAccountViewController.h"

#import "OTRNewBuddyViewController.h"
@import QuartzCore;
@import OTRAssets;
#import "OTRAccountsManager.h"
#import "OTRAccount.h"
@import PureLayout;
#import "ChatSecureCoreCompat-Swift.h"


@interface OTRChooseAccountViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<OTRAccount*> *accounts;

@end

@implementation OTRChooseAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = ACCOUNT_STRING();
    self.accounts = [OTRAccountsManager allAccounts];
	
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.tableView autoPinEdgesToSuperviewEdges];
    
    NSBundle *bundle = [OTRAssets resourcesBundle];
    UINib *nib = [UINib nibWithNibName:[XMPPAccountCell cellIdentifier] bundle:bundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:[XMPPAccountCell cellIdentifier]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [XMPPAccountCell cellHeight];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.accounts.count;
}

-(UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [XMPPAccountCell cellIdentifier];
    XMPPAccountCell * cell = [tView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRAccount *account = [self.accounts objectAtIndex:indexPath.row];
    
    if (self.selectionBlock) {
        self.selectionBlock(self, account);
    }
    
    [tView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) configureCell:(XMPPAccountCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OTRXMPPAccount *account = (OTRXMPPAccount*)[self.accounts objectAtIndex:indexPath.row];
    [cell setAppearanceWithAccount:account];
    cell.infoButton.hidden = YES;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

-(void)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
