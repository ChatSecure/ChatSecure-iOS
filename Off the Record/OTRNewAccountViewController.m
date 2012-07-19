//
//  OTRNewAccountViewController.m
//  Off the Record
//
//  Created by David Chiles on 7/12/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRNewAccountViewController.h"
#import "Strings.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"
#import "OTRLoginViewController.h"
#import "QuartzCore/QuartzCore.h"

#define rowHeight 70

@interface OTRNewAccountViewController ()

@end

@implementation OTRNewAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = NEW_ACCOUNT_STIRNG;
    UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    CGFloat headerHeight = (tableView.frame.size.height - 4*rowHeight)  / 4;
    
    tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, headerHeight)];
    
    tableView.scrollEnabled = NO;
    [self.view addSubview:tableView];
    
    //Facebook
    OTRAccount * facebookAccount = [[OTRAccount alloc] initWithUsername:@"" domain:kOTRFacebookDomain protocol:kOTRProtocolTypeXMPP];
    
    //Google Chat
    OTRAccount * googleAccount = [[OTRAccount alloc] initWithUsername:@"" domain:kOTRGoogleTalkDomain protocol:kOTRProtocolTypeXMPP];
    
    //Jabber
     OTRAccount * jabberAccount = [[OTRAccount alloc] initWithUsername:@"" domain:@"" protocol:kOTRProtocolTypeXMPP];
    
    //Aim
    OTRAccount * aimAccount = [[OTRAccount alloc] initWithUsername:@"" domain:@"" protocol:kOTRProtocolTypeAIM];
    
    accounts = [NSArray arrayWithObjects:facebookAccount,googleAccount,jabberAccount,aimAccount, nil];
    
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
    OTRAccount * cellAccount = [accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = [cellAccount providerName];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:19];
    cell.imageView.image = [UIImage imageNamed:cellAccount.imageName];
    
    if( [[cellAccount providerName] isEqualToString:FACEBOOK_STRING])
    {
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRAccount * cellAccount = [accounts objectAtIndex:indexPath.row];
    OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] initWithAccount:cellAccount];
    [self.navigationController pushViewController:loginViewController animated:YES];
    
    
}

- (void)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
