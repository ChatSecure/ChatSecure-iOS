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
#import "OTRAccount.h"
#import "OTRConstants.h"
#import "OTRNewAccountViewController.h"
#import "QuartzCore/QuartzCore.h"

@implementation OTRAccountsViewController
@synthesize accountsTableView, logoView, loginController;

- (void) dealloc {
    self.accountsTableView = nil;
    self.logoView = nil;
    self.loginController = nil;
}

- (id)init {
    if (self = [super init]) {
        self.title = ACCOUNTS_STRING;
        self.tabBarItem.image = [UIImage imageNamed:@"19-gear.png"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccount:)];
    }
    return self;
}

- (void) addAccount:(id)sender {
   
    OTRNewAccountViewController * newAccountView = [[OTRNewAccountViewController alloc] init];
   
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newAccountView];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentModalViewController:nav animated:YES];
    
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
    //accountsTableView.transform = CGAffineTransformMakeRotation(-1.5707);
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
     selector:@selector(protocolLoggedInSuccessfully:)
     name:kOTRProtocolLoginSuccess
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoggedOff:)
     name: kOTRProtocolLogout
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

-(void)protocolLoggedInSuccessfully:(NSNotification *)notification
{
    id <OTRProtocol> protocol = notification.object;
    protocol.account.isConnected = YES;
    [self accountLoggedIn];
}

-(void)protocolLoggedOff:(NSNotification *)notification
{
    id <OTRProtocol> protocol = notification.object;
    protocol.account.isConnected = NO;
    [[[OTRProtocolManager sharedInstance] buddyList] removeBuddiesforAccount:protocol.account];
    [accountsTableView reloadData];
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
    
    if ([[OTRProtocolManager sharedInstance].accountsManager.accountsArray count] > 2) {
        tableView.scrollEnabled = YES;
    }
    else {
        tableView.scrollEnabled = NO;
    }

    return [[OTRProtocolManager sharedInstance].accountsManager.accountsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
    
    OTRAccount *account = [[OTRProtocolManager sharedInstance].accountsManager.accountsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = account.username;
    cell.detailTextLabel.text = account.protocol;
    cell.imageView.image = [UIImage imageNamed:account.imageName];
    
    if( [[account providerName] isEqualToString:FACEBOOK_STRING])
    {
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRAccount *account = [[OTRProtocolManager sharedInstance].accountsManager.accountsArray objectAtIndex:indexPath.row];
    
    if (!account.isConnected) {
        [self showLoginControllerForAccount:account];
    } else {
        UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:LOGOUT_STRING delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:LOGOUT_STRING otherButtonTitles: nil];
        [logoutSheet setTag:indexPath.row];
        [logoutSheet showFromTabBar:self.tabBarController.tabBar];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
        OTRAccount *account = [protocolManager.accountsManager.accountsArray objectAtIndex:indexPath.row];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DELETE_ACCOUNT_TITLE_STRING message:[NSString stringWithFormat:@"%@ %@?", DELETE_ACCOUNT_MESSAGE_STRING, account.username] delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:OK_STRING, nil];
        alert.tag = indexPath.row;
        [alert show];
    }
}

- (void) showLoginControllerForAccount:(OTRAccount*)account {
    OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] initWithAccount:account];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentModalViewController:nav animated:YES];
    
    self.loginController = loginViewController;
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    OTRAccount *account = [[OTRProtocolManager sharedInstance].accountsManager.accountsArray objectAtIndex:actionSheet.tag];
    
    id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
    
    if(buttonIndex == 0) //logout
    {
        [protocol disconnect];
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
        OTRAccount *account = [protocolManager.accountsManager.accountsArray objectAtIndex:alertView.tag];
        [protocolManager.accountsManager removeAccount:account];        
        [accountsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:alertView.tag inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
