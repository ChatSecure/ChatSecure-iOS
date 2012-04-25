//
//  OTRAccountsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRAccountsViewController.h"
#import "OTRProtocolManager.h"
#import "Strings.h"

@implementation OTRAccountsViewController
@synthesize accountsTableView, logoView;

- (id)init {
    if (self = [super init]) {
        self.title = ACCOUNTS_STRING;
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

- (void) loadView 
{
    [super loadView];
    self.accountsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    accountsTableView.dataSource = self;
    accountsTableView.delegate = self;
    accountsTableView.scrollEnabled = NO;
    [self.view addSubview:accountsTableView];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    [self.view addSubview:logoView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    accountsTableView.backgroundView = nil;
    accountsTableView.backgroundColor = [UIColor clearColor];
    
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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat logoViewFrameWidth = self.logoView.image.size.width;
    logoView.frame = CGRectMake(self.view.frame.size.width/2 - logoViewFrameWidth/2, 20, logoViewFrameWidth, self.logoView.image.size.height);
    logoView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat accountsTableViewYOrigin = logoView.frame.origin.y + logoView.frame.size.height + 10;
    accountsTableView.frame = CGRectMake(0, accountsTableViewYOrigin, self.view.frame.size.width, self.view.frame.size.height-accountsTableViewYOrigin);
    accountsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
}

-(void)aimLoggedOff
{
    [OTRProtocolManager sharedInstance].oscarManager.loggedIn = NO;
    //[[[OTRProtocolManager sharedInstance] buddyList] removeOscarBuddies];
    [accountsTableView reloadData];
}

-(void)xmppLoggedOff
{
    [OTRProtocolManager sharedInstance].xmppManager.isXmppConnected = NO;
    [[[OTRProtocolManager sharedInstance] buddyList] removeXmppBuddies];
    [accountsTableView reloadData];
    
}

                                                                           
-(void)oscarLoggedInSuccessfully
{
    [OTRProtocolManager sharedInstance].oscarManager.loggedIn = YES;
    [self accountLoggedIn];
}

-(void)xmppLoggedInSuccessfully
{
    [OTRProtocolManager sharedInstance].xmppManager.isXmppConnected = YES;
    [self accountLoggedIn];
}

-(void)accountLoggedIn
{
    [accountsTableView reloadData];
    [loginController dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.accountsTableView = nil;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return ACCOUNTS_STRING;
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
        cell.textLabel.text = AIM_STRING;
        
        if([OTRProtocolManager sharedInstance].oscarManager.loggedIn)
        {
            cell.detailTextLabel.text = LOGOUT_STRING;
        }
        else
        {
            cell.detailTextLabel.text = LOGIN_STRING;
        }

        cell.imageView.image = [UIImage imageNamed:@"aim.png"];
    }
    else if(indexPath.row == 1)
    {
        cell.textLabel.text = XMPP_STRING;
        
        if([OTRProtocolManager sharedInstance].xmppManager.isXmppConnected)
        {
            cell.detailTextLabel.text = LOGOUT_STRING;
        }
        else
        {
            cell.detailTextLabel.text = LOGIN_STRING;
        }
        
        cell.imageView.image = [UIImage imageNamed:@"gtalk.png"];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) // AIM
    {
        if(![OTRProtocolManager sharedInstance].oscarManager.loggedIn)
        {
            OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] init];
            
            OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
            
            loginViewController.useXMPP = NO;
            loginViewController.protocolManager = protocolManager;
            loginViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.tabBarController presentModalViewController:loginViewController animated:YES];

            
            
            loginController = loginViewController;
        }
        else
        {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:LOGOUT_FROM_AIM_STRING delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:LOGOUT_STRING otherButtonTitles: nil];
            [logoutSheet setTag:1];
            [logoutSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    else
    {
        if(![OTRProtocolManager sharedInstance].xmppManager.isXmppConnected)
        {
            OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] init];
            
            OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
            loginViewController.useXMPP = YES;
            loginViewController.protocolManager = protocolManager;
            loginViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.tabBarController presentModalViewController:loginViewController animated:YES];


            
            loginController = loginViewController;

        }
        else
        {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:LOGOUT_FROM_XMPP_STRING delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:LOGOUT_STRING otherButtonTitles: nil];
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
            AIMSessionManager *sessionManager = [[[OTRProtocolManager sharedInstance] oscarManager] theSession];
            [sessionManager.session closeConnection];
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
