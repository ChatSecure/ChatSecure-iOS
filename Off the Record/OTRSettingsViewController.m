//
//  OTRSettingsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingsViewController.h"
#import "OTRProtocolManager.h"
#import "OTRBoolSetting.h"
#import "Strings.h"
#import "OTRSettingTableViewCell.h"
#import "OTRSettingDetailViewController.h"
#import "OTRAboutViewController.h"
#import "OTRQRCodeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRNewAccountViewController.h"
#import "OTRConstants.h"
#import <Twitter/Twitter.h>

#define ACTIONSHEET_DISCONNECT_TAG 1
#define ACTIONSHEET_SHARE_TAG 2
#define ALERTVIEW_DELETE_TAG 1

@implementation OTRSettingsViewController
@synthesize settingsTableView, settingsManager, loginController, selectedAccount, selectedIndexPath;

- (void) dealloc
{
    self.settingsManager = nil;
    self.settingsTableView = nil;
    self.loginController = nil;
    self.selectedAccount = nil;
    self.selectedIndexPath = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) init
{
    if (self = [super init])
    {
        self.title = SETTINGS_STRING;
        self.tabBarItem.image = [UIImage imageNamed:@"19-gear.png"];
        self.settingsManager = [OTRProtocolManager sharedInstance].settingsManager;
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
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.settingsTableView = nil;
}

- (void)loadView
{
    [super loadView];
    self.settingsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.settingsTableView.dataSource = self;
    self.settingsTableView.delegate = self;
    self.settingsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:settingsTableView];
    
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"about_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showAboutScreen)];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:SHARE_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(shareButtonPressed:)];
    self.navigationItem.rightBarButtonItem = aboutButton;
    self.navigationItem.leftBarButtonItem = shareButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.settingsTableView.frame = self.view.bounds;
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

- (void) shareButtonPressed:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:SHARE_STRING delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSArray *buttonTitles = [self buttonTitlesForShareButton];
    for (NSString *title in buttonTitles) {
        [sheet addButtonWithTitle:title];
    }
    sheet.tag = ACTIONSHEET_SHARE_TAG;
    sheet.cancelButtonIndex = [buttonTitles count] - 1;
    
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (NSArray*) buttonTitlesForShareButton {
    NSMutableArray *titleArray = [NSMutableArray arrayWithCapacity:4];
    [titleArray addObject:@"SMS"];
    [titleArray addObject:@"E-mail"];
    [titleArray addObject:@"QR Code"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
    {
        [titleArray addObject:@"Twitter"];
    }
    [titleArray addObject:CANCEL_STRING];
    return titleArray;
}

- (NSString*) shareString {
    return [NSString stringWithFormat:@"%@: http://get.chatsecure.org", SHARE_MESSAGE_STRING];
}

- (NSString*) twitterShareString {
    return [NSString stringWithFormat:@"%@ @ChatSecure", [self shareString]];
}

#pragma mark UITableViewDataSource methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != [[OTRProtocolManager sharedInstance].accountsManager.accountsArray count])
    {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;     
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // Accounts 
        static NSString *accountCellIdentifier = @"AccountCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:accountCellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:accountCellIdentifier];
        }
        if (indexPath.row == [[OTRProtocolManager sharedInstance].accountsManager.accountsArray count]) {
            cell.textLabel.text = NEW_ACCOUNT_STRING;
            cell.imageView.image = [UIImage imageNamed:@"31-circle-plus.png"];
            cell.detailTextLabel.text = @"";
        } else {
            OTRAccount *account = [[OTRProtocolManager sharedInstance].accountsManager.accountsArray objectAtIndex:indexPath.row];
            cell.textLabel.text = account.username;
            if (account.isConnected) {
                cell.detailTextLabel.text = CONNECTED_STRING;
            } else {
                cell.detailTextLabel.text = nil;
            }
            cell.imageView.image = [UIImage imageNamed:account.imageName];
            
            if( [[account providerName] isEqualToString:FACEBOOK_STRING])
            {
                cell.imageView.layer.masksToBounds = YES;
                cell.imageView.layer.cornerRadius = 10.0;
            }
        }
        return cell;
    }
    static NSString *cellIdentifier = @"Cell";
    OTRSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[OTRSettingTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
    OTRSetting *setting = [settingsManager settingAtIndexPath:indexPath];
    setting.delegate = self;
    cell.otrSetting = setting;
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return [self.settingsManager.settingsGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0) {
        return [[OTRProtocolManager sharedInstance].accountsManager.accountsArray count]+1;
    }
    return [self.settingsManager numberOfSettingsInSection:sectionIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.settingsManager stringForGroupInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // Accounts
        if (indexPath.row == [[OTRProtocolManager sharedInstance].accountsManager.accountsArray count]) {
            [self addAccount:nil];
        } else {
            OTRAccount *account = [[OTRProtocolManager sharedInstance].accountsManager.accountsArray objectAtIndex:indexPath.row];
            
            if (!account.isConnected) {
                [self showLoginControllerForAccount:account];
            } else {
                UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:LOGOUT_STRING delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:LOGOUT_STRING otherButtonTitles: nil];
                self.selectedAccount = account;
                self.selectedIndexPath = indexPath;
                logoutSheet.tag = ACTIONSHEET_DISCONNECT_TAG;
                [logoutSheet showFromTabBar:self.tabBarController.tabBar];
            }
        }
    } else {
        OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [setting performSelector:setting.action];
#pragma clang diagnostic pop
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
        OTRAccount *account = [protocolManager.accountsManager.accountsArray objectAtIndex:indexPath.row];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DELETE_ACCOUNT_TITLE_STRING message:[NSString stringWithFormat:@"%@ %@?", DELETE_ACCOUNT_MESSAGE_STRING, account.username] delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:OK_STRING, nil];
        alert.tag = ALERTVIEW_DELETE_TAG;
        self.selectedIndexPath = indexPath;
        self.selectedAccount = account;
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

-(void)showAboutScreen
{
    OTRAboutViewController *aboutController = [[OTRAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutController animated:YES];
}

- (void) addAccount:(id)sender {
    
    OTRNewAccountViewController * newAccountView = [[OTRNewAccountViewController alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newAccountView];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentModalViewController:nav animated:YES];
    
}

#pragma mark OTRSettingDelegate method

- (void) refreshView 
{
    [self.settingsTableView reloadData];
}

#pragma mark OTRSettingViewDelegate method
- (void) otrSetting:(OTRSetting*)setting showDetailViewControllerClass:(Class)viewControllerClass
{
    UIViewController *viewController = [[viewControllerClass alloc] init];
    if ([viewController isKindOfClass:[OTRSettingDetailViewController class]]) 
    {
        OTRSettingDetailViewController *detailSettingViewController = (OTRSettingDetailViewController*)viewController;
        detailSettingViewController.otrSetting = setting;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailSettingViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.tabBarController presentModalViewController:navController animated:YES];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    if (actionSheet.tag == ACTIONSHEET_DISCONNECT_TAG) {
        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:selectedAccount];
        
        if(buttonIndex == 0) //logout
        {
            [protocol disconnect];
        }
        return;
    } else if (actionSheet.tag == ACTIONSHEET_SHARE_TAG) {
        if (buttonIndex == 0) // SMS
        {
            if (![MFMessageComposeViewController canSendText]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:[NSString stringWithFormat:@"SMS %@", NOT_AVAILABLE_STRING] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
                [alert show];
            } else {
                MFMessageComposeViewController *sms = [[MFMessageComposeViewController alloc] init];
                sms.messageComposeDelegate = self;
                sms.body = [self shareString];
                sms.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:sms animated:YES];
            }
        } 
        else if (buttonIndex == 1) // Email
        { 
            if (![MFMailComposeViewController canSendMail]) 
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:[NSString stringWithFormat:@"E-mail %@", NOT_AVAILABLE_STRING] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
                [alert show];
            }
            else 
            {
                MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
                email.mailComposeDelegate = self;
                [email setSubject:@"ChatSecure"];
                [email setMessageBody:[self shareString] isHTML:NO];
                email.modalPresentationStyle = UIModalPresentationFormSheet;
                
                [self presentModalViewController:email animated:YES];
            }
        }
        else if (buttonIndex == 2) // QR code
        {
            OTRQRCodeViewController *qrCode = [[OTRQRCodeViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrCode];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentModalViewController:nav animated:YES];
        } else if (buttonIndex == [[self buttonTitlesForShareButton] count] - 2 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
        {
            TWTweetComposeViewController *tweetSheet =
            [[TWTweetComposeViewController alloc] init];
            [tweetSheet setInitialText:[self twitterShareString]];
            [self presentModalViewController:tweetSheet animated:YES];
        }
    }
}

#pragma mark MFMessageComposeViewControllerDelegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

-(void)accountLoggedIn
{
    [settingsTableView reloadData];
    [loginController dismissModalViewControllerAnimated:YES];
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
    [settingsTableView reloadData];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERTVIEW_DELETE_TAG) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            if([selectedAccount isConnected])
            {
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:selectedAccount];
                [protocol disconnect];
            }
            OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
            
            [protocolManager.accountsManager removeAccount:selectedAccount];        
            [settingsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        self.selectedIndexPath = nil;
        self.selectedAccount = nil;
    }

}

@end
