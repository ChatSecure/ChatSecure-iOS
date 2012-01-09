//
//  OTRAccountsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(aimLoggedOff)
     name:@"OscarLogoutNotification"
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(xmppLoggedOff)
     name:@"XMPPLogoutNotification"
     object:nil ];
}

-(void)aimLoggedOff
{
    isAIMloggedIn = NO;
    [accountsTableView reloadData];
}
-(void)xmppLoggedOff
{
    isXMPPloggedIn = NO;
    [accountsTableView reloadData];
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
        cell.textLabel.text = @"Google Talk (XMPP)";
        
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
            [logoutSheet setTag:1];
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
            [logoutSheet setTag:2];
            [logoutSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    
    
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 1) // logout of AIM
    {
        if(buttonIndex == 0) //logout
        {
            /*AIMSessionManager *sessionManager = [[[OTRProtocolManager sharedInstance] oscarManager] theSession];
            [sessionManager aimSessionClosed:sessionManager.session];
            [sessionManager release];*/
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Implemented" message:@"Sorry, this hasn't been written yet. You can always close the app to logout." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            [alert release];
        }
    }
    else if(actionSheet.tag == 2) // logout of XMPP
    {
        if(buttonIndex == 0) //logout
        {
            [[[OTRProtocolManager sharedInstance] xmppManager] disconnect];
        }
    }
}

@end
