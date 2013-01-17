//
//  OTRNewAccountViewController.m
//  Off the Record
//
//  Created by David Chiles on 7/12/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRNewAccountViewController.h"
#import "Strings.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "OTRLoginViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedOscarAccount.h"

#define rowHeight 70

@interface OTRNewAccountViewController ()

@end

@implementation OTRNewAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = NEW_ACCOUNT_STRING;
    UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    
    //Facebook
    OTRManagedXMPPAccount * facebookAccount = [OTRManagedXMPPAccount MR_createEntity];
    [facebookAccount setDefaultsWithDomain:kOTRFacebookDomain];
    
    //Google Chat
    OTRManagedXMPPAccount * googleAccount = [OTRManagedXMPPAccount MR_createEntity];
    [googleAccount setDefaultsWithDomain:kOTRGoogleTalkDomain];
    
    //Jabber
    OTRManagedXMPPAccount * jabberAccount = [OTRManagedXMPPAccount MR_createEntity];
    [jabberAccount setDefaultsWithDomain:@""];
    
    //Aim
    OTRManagedOscarAccount * aimAccount = [OTRManagedOscarAccount MR_createEntity];
    [aimAccount setDefaultsWithProtocol:kOTRProtocolTypeAIM];
    
    accounts = [NSMutableArray arrayWithObjects:facebookAccount,googleAccount,jabberAccount,aimAccount, nil];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [context MR_save];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [accounts count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return rowHeight;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    OTRManagedAccount * cellAccount = [accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = [cellAccount providerName];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:19];
    cell.imageView.image = [UIImage imageNamed:cellAccount.imageName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if( [[cellAccount providerName] isEqualToString:FACEBOOK_STRING])
    {
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRManagedAccount * cellAccount = [accounts objectAtIndex:indexPath.row];
    [accounts removeObject:cellAccount];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    for (OTRManagedAccount *account in accounts) {
        [context deleteObject:[context objectWithID:account.objectID]];
    }
    [context MR_save];
    
    OTRLoginViewController *loginViewController = [OTRLoginViewController loginViewControllerWithAcccount:cellAccount];
    loginViewController.isNewAccount = YES;
    [self.navigationController pushViewController:loginViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

- (void)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

@end
