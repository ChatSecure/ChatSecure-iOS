//
//  OTRAccountsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRAccountsViewController.h"
#import "OTRProtocolManager.h"
#import "OTRAboutViewController.h"

@implementation OTRAccountsViewController
@synthesize accountsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Accounts";
        self.tabBarItem.image = [UIImage imageNamed:@"19-gear.png"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    accountsTableView.backgroundColor = [UIColor clearColor];
    aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"about_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showAboutScreen)];
    self.navigationItem.rightBarButtonItem = aboutButton;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(oscarLoggedInSuccessfully)
     name:@"OscarLoginNotification"
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(xmppLoggedInSuccessfully)
     name:@"XMPPLoginNotification"
     object:nil ];
}

-(void)showAboutScreen
{
    OTRAboutViewController *aboutController = [[OTRAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutController animated:YES];
    [aboutController release];
}

                                                                           
-(void)oscarLoggedInSuccessfully
{
    isAIMloggedIn = YES;
    [self accountLoggedIn];
}

-(void)xmppLoggedInSuccessfully
{
    isXMPPloggedIn = YES;
    [self accountLoggedIn];
}

-(void)accountLoggedIn
{
    [accountsTableView reloadData];
    [loginController dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [self setAccountsTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [accountsTableView release];
    [aboutButton release];
    [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Accounts";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}

    if(indexPath.row == 0)
    {
        cell.textLabel.text = @"AOL Instant Messenger";
        
        if(isAIMloggedIn)
        {
            cell.detailTextLabel.text = @"Log Out";
        }
        else
        {
            cell.detailTextLabel.text = @"Log In";
        }

        cell.imageView.image = [UIImage imageNamed:@"aim.png"];
    }
    else if(indexPath.row == 1)
    {
        cell.textLabel.text = @"XMPP (Google Talk / Jabber)";
        
        if(isXMPPloggedIn)
        {
            cell.detailTextLabel.text = @"Log Out";
        }
        else
        {
            cell.detailTextLabel.text = @"Log In";
        }
        
        cell.imageView.image = [UIImage imageNamed:@"gtalk.png"];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) // AIM
    {
        if(!isAIMloggedIn)
        {
            OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] init];
            
            OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
            
            loginViewController.protocolManager = protocolManager;
            [self.tabBarController presentModalViewController:loginViewController animated:YES];
            loginViewController.xmppButton.hidden = YES;
            
            loginController = loginViewController;
        }
        else
        {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:@"Logout from AIM?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles: nil];
            [logoutSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    else
    {
        if(!isXMPPloggedIn)
        {
            OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] init];
            
            OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
            
            loginViewController.protocolManager = protocolManager;
            [self.tabBarController presentModalViewController:loginViewController animated:YES];
            loginViewController.aimButton.hidden = YES;

            
            loginController = loginViewController;

        }
        else
        {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:@"Logout from XMPP?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles: nil];
            [logoutSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    
    
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // TODO implement logging out
}

@end
