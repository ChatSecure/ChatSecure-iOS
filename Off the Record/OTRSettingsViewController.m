//
//  OTRSettingsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
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
#import "OTRAppDelegate.h"
#import "UserVoice.h"
#import "OTRAccountTableViewCell.h"
#import "OTRCreateAccountChooserViewController.h"

#define ACTIONSHEET_DISCONNECT_TAG 1
#define ACTIONSHEET_ACCOUNT_PICK_TYPE_TAG 2
#define ALERTVIEW_DELETE_TAG 1

@interface OTRSettingsViewController(Private)
- (void) addAccount:(id)sender;
- (void) showLoginControllerForAccount:(OTRManagedAccount*)account;
@end

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
        self.settingsManager = [[OTRSettingsManager alloc] init];;
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(protocolLoggedInSuccessfully:)
         name:kOTRProtocolLoginSuccess
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

    self.navigationItem.rightBarButtonItem = aboutButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.settingsTableView.frame = self.view.bounds;
    [settingsTableView reloadData];
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



#pragma mark UITableViewDataSource methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != [self.accountsFetchedResultsController.sections[0] numberOfObjects])
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
        static NSString *accountCellIdentifier = @"accountCellIdentifier";
        static NSString *addAccountCellIdentifier = @"addAccountCellIdentifier";
        UITableViewCell * cell = nil;
        if (indexPath.row == [self.accountsFetchedResultsController.sections[0] numberOfObjects]) {
            cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addAccountCellIdentifier];
                cell.textLabel.text = NEW_ACCOUNT_STRING;
                cell.imageView.image = [UIImage imageNamed:@"31-circle-plus-large.png"];
                cell.detailTextLabel.text = nil;
            }
        }
        else {
            OTRManagedAccount *account = [self.accountsFetchedResultsController objectAtIndexPath:indexPath];
            OTRAccountTableViewCell *accountCell = (OTRAccountTableViewCell*)[tableView dequeueReusableCellWithIdentifier:accountCellIdentifier];
            if (accountCell == nil) {
                accountCell = [[OTRAccountTableViewCell alloc] initWithAccount:account reuseIdentifier:accountCellIdentifier];
            }
            else {
                [accountCell setAccount:account];
            }
            cell = accountCell;
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
        return [self.accountsFetchedResultsController.sections[0] numberOfObjects]+1;
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
        if (indexPath.row == [self.accountsFetchedResultsController.sections[0] numberOfObjects]) {
            [self addAccount:[tableView cellForRowAtIndexPath:indexPath]];
        } else {
            OTRManagedAccount *account = [self.accountsFetchedResultsController objectAtIndexPath:indexPath];
            
            if (!account.isConnected) {
                [self showLoginControllerForAccount:account];
            } else {
                UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:LOGOUT_STRING delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:LOGOUT_STRING otherButtonTitles: nil];
                self.selectedAccount = account;
                self.selectedIndexPath = indexPath;
                logoutSheet.tag = ACTIONSHEET_DISCONNECT_TAG;
                [OTR_APP_DELEGATE presentActionSheet:logoutSheet inView:self.view];
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
        OTRManagedAccount *account = [self.accountsFetchedResultsController objectAtIndexPath:indexPath];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DELETE_ACCOUNT_TITLE_STRING message:[NSString stringWithFormat:@"%@ %@?", DELETE_ACCOUNT_MESSAGE_STRING, account.username] delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:OK_STRING, nil];
        alert.tag = ALERTVIEW_DELETE_TAG;
        self.selectedIndexPath = indexPath;
        self.selectedAccount = account;
        [alert show];
    }
}

- (void) showLoginControllerForAccount:(OTRManagedAccount*)account {
    OTRLoginViewController *loginViewController = [OTRLoginViewController loginViewControllerWithAcccountID:account.objectID];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
    
    self.loginController = loginViewController;
}

-(void)showAboutScreen
{
    OTRAboutViewController *aboutController = [[OTRAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutController animated:YES];
}

- (void) addAccount:(id)sender {
    
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"New or Create Account" delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:@"Create New Account",@"Login to Existing Account", nil];
    actionSheet.tag = ACTIONSHEET_ACCOUNT_PICK_TYPE_TAG;
    [actionSheet showInView:self.view];
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
    viewController.title = setting.title;
    if ([viewController isKindOfClass:[OTRSettingDetailViewController class]]) 
    {
        OTRSettingDetailViewController *detailSettingViewController = (OTRSettingDetailViewController*)viewController;
        detailSettingViewController.otrSetting = setting;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailSettingViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark OTRFeedbackSettingDelegate method

- (void) presentUserVoiceWithConfig:(UVConfig*)config {
    [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
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
    }
    else if (actionSheet.tag == ACTIONSHEET_ACCOUNT_PICK_TYPE_TAG)
    {
        if (buttonIndex == 0) {
            OTRCreateAccountChooserViewController * createAccountChooser = [[OTRCreateAccountChooserViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:createAccountChooser];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nav animated:YES completion:nil];
        }
        else if (buttonIndex == 1)
        {
            OTRNewAccountViewController * newAccountView = [[OTRNewAccountViewController alloc] init];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newAccountView];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nav animated:YES completion:nil];
        }
        
    }
}

-(void)accountLoggedIn
{
    [settingsTableView reloadData];
    [loginController dismissViewControllerAnimated:YES completion:nil];
}

-(void)protocolLoggedInSuccessfully:(NSNotification *)notification
{
    [self accountLoggedIn];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERTVIEW_DELETE_TAG) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            if([selectedAccount isConnected])
            {
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:selectedAccount];
                [protocol disconnect];
            }
            [OTRAccountsManager removeAccount:selectedAccount];
            
            
        }
        self.selectedIndexPath = nil;
        self.selectedAccount = nil;
    }

}

-(NSFetchedResultsController *)accountsFetchedResultsController
{
    if (_accountsFetchedResultsController) {
        return _accountsFetchedResultsController;
    }
    
    _accountsFetchedResultsController = [OTRManagedAccount MR_fetchAllSortedBy:@"username" ascending:YES withPredicate:nil groupBy:nil delegate:self];
    
    return _accountsFetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.settingsTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView* tableView = self.settingsTableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            OTRManagedAccount *account = [self.accountsFetchedResultsController objectAtIndexPath:indexPath];
            [((OTRAccountTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]) setAccount:account];
            break;
        }
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.settingsTableView endUpdates];
}

@end
