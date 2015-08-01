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
#import "OTRConstants.h"
#import "UserVoice.h"
#import "OTRAccountTableViewCell.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+ChatSecure.h"
#import "UIActionSheet+Blocks.h"
#import "OTRSecrets.h"
#import "YAPDatabaseViewMappings.h"
#import "YAPDatabaseConnection.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "YapDatabase.h"
#import "YapDatabaseView.h"
#import "OTRAccount.h"
#import "OTRAppDelegate.h"
#import "OTRUtilities.h"
#import "OTRShareSetting.h"
#import "OTRActivityItemProvider.h"
#import "OTRQRCodeActivity.h"
#import "XMPPURI.h"
#import "OTRWelcomeViewController.h"
#import "OTRBaseLoginViewController.h"
#import "OTRXLFormCreator.h"
#import <KVOController/FBKVOController.h>
#import "OTRInviteViewController.h"

static NSString *const circleImageName = @"31-circle-plus-large.png";

@interface OTRSettingsViewController () <UITableViewDataSource, UITableViewDelegate, OTRShareSettingDelegate>

@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation OTRSettingsViewController

- (id) init
{
    if (self = [super init])
    {
        self.title = SETTINGS_STRING;
        self.settingsManager = [[OTRSettingsManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Make sure allAccountsDatabaseView is registered
    [OTRDatabaseView registerAllAccountsDatabaseView];
    
    //User main thread database connection
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    //Create mappings from allAccountsDatabaseView
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllAccountGroup] view:OTRAllAccountDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.mappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.accessibilityIdentifier = @"settingsTableView";
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"OTRInfoIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAboutScreen)];

    self.navigationItem.rightBarButtonItem = aboutButton;
    
    ////// KVO //////
    __weak typeof(self)weakSelf = self;
    [self.KVOController observe:[OTRProtocolManager sharedInstance] keyPaths:@[NSStringFromSelector(@selector(numberOfConnectedProtocols)),NSStringFromSelector(@selector(numberOfConnectingProtocols))] options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        });
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.frame = self.view.bounds;
    [self.tableView reloadData];
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

- (OTRAccount *)accountAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        account = [[transaction extension:OTRAllAccountDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    return account;
}

#pragma mark UITableViewDataSource methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != [self.mappings numberOfItemsInSection:0])
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
        if (indexPath.row == [self.mappings numberOfItemsInSection:indexPath.section]) {
            cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addAccountCellIdentifier];
                cell.textLabel.text = NEW_ACCOUNT_STRING;
                cell.imageView.image = [UIImage imageNamed:circleImageName];
                cell.detailTextLabel.text = nil;
            }
        }
        else {
            OTRAccount *account = [self accountAtIndexPath:indexPath];
            OTRAccountTableViewCell *accountCell = (OTRAccountTableViewCell*)[tableView dequeueReusableCellWithIdentifier:accountCellIdentifier];
            if (accountCell == nil) {
                accountCell = [[OTRAccountTableViewCell alloc] initWithReuseIdentifier:accountCellIdentifier];
            }
            
            [accountCell setAccount:account];
            
            if ([[OTRProtocolManager sharedInstance] existsProtocolForAccount:account]) {
                id <OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                if (protocol) {
                    [accountCell setConnectedText:[protocol connectionStatus]];
                }
            }
            else {
                [accountCell setConnectedText:OTRProtocolConnectionStatusDisconnected];
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
    OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];
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
        return [self.mappings numberOfItemsInSection:0]+1;
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
        if (indexPath.row == [self.mappings numberOfItemsInSection:0]) {
            [self addAccount:[tableView cellForRowAtIndexPath:indexPath]];
        } else {
            OTRAccount *account = [self accountAtIndexPath:indexPath];
            
            BOOL connected = [[OTRProtocolManager sharedInstance] isAccountConnected:account];
            if (!connected) {
                OTRBaseLoginViewController *baseLoginViewController = [OTRBaseLoginViewController loginViewControllerForAccount:account];
                baseLoginViewController.showsCancelButton = YES;
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:baseLoginViewController];
                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:navigationController animated:YES completion:nil];
            } else {
                [self logoutAccount:account sender:[tableView cellForRowAtIndexPath:indexPath]];
            }
        }
    } else {
        OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];
        OTRSettingActionBlock actionBlock = setting.actionBlock;
        if (actionBlock) {
            actionBlock();
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        OTRAccount *account = [self accountAtIndexPath:indexPath];
        
        RIButtonItem * cancelButtonItem = [RIButtonItem itemWithLabel:CANCEL_STRING];
        RIButtonItem * okButtonItem = [RIButtonItem itemWithLabel:OK_STRING action:^{
            
            if( [[OTRProtocolManager sharedInstance] isAccountConnected:account])
            {
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                [protocol disconnect];
            }
            [OTRAccountsManager removeAccount:account];
        }];
        
        NSString * message = [NSString stringWithFormat:@"%@ %@?", DELETE_ACCOUNT_MESSAGE_STRING, account.username];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:DELETE_ACCOUNT_TITLE_STRING message:message cancelButtonItem:cancelButtonItem otherButtonItems:okButtonItem, nil];
        
        [alertView show];
    }
}

#pragma - mark Other Methods

-(void)showAboutScreen
{
    OTRAboutViewController *aboutController = [[OTRAboutViewController alloc] init];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:aboutController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    else {
       [self.navigationController pushViewController:aboutController animated:YES];
    }
    
}

- (void)logoutAccount:(OTRAccount *)account sender:(id)sender
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *logoutAlertAction = [UIAlertAction actionWithTitle:LOGOUT_STRING style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
            [protocol disconnect];
        }];
        
        UIAlertAction *shareAction = [UIAlertAction actionWithTitle:SHARE_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self shareAccount:account sender:sender];
        }];
        
        [alertController addAction:shareAction];
        [alertController addAction:logoutAlertAction];
        [alertController addAction:cancelAlertAction];
        
        if ([sender isKindOfClass:[UIView class]]) {
            UIView *senderView = (UIView *)sender;
            alertController.popoverPresentationController.sourceRect = senderView.bounds;
            alertController.popoverPresentationController.sourceView = senderView;
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        RIButtonItem * cancelButtonItem = [RIButtonItem itemWithLabel:CANCEL_STRING];
        RIButtonItem * logoutButtonItem = [RIButtonItem itemWithLabel:LOGOUT_STRING action:^{
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
            [protocol disconnect];
        }];
        RIButtonItem *shareButtonItem = [RIButtonItem itemWithLabel:SHARE_STRING action:^{
            [self shareAccount:account sender:sender];
        }];
        
        UIActionSheet * logoutActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelButtonItem destructiveButtonItem:logoutButtonItem otherButtonItems:shareButtonItem, nil];
        
        [logoutActionSheet otr_presentInView:self.view];
    }
}

- (void) addAccount:(id)sender {
    OTRWelcomeViewController *welcomeViewController = [[OTRWelcomeViewController alloc] init];
    __weak id welcomeVC = welcomeViewController;
    welcomeViewController.showNavigationBar = NO;
    [welcomeViewController setCompletionBlock:^(OTRAccount *account, NSError *error) {
        if (account) {
            [OTRInviteViewController showInviteFromVC:welcomeVC withAccount:account];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (NSIndexPath *)indexPathForSetting:(OTRSetting *)setting
{
    return [self.settingsManager indexPathForSetting:setting];
}

#pragma mark OTRSettingDelegate method

- (void)refreshView
{
    [self.tableView reloadData];
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

- (void) donateSettingPressed:(OTRDonateSetting *)setting {
    
    NSURL *paypalURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6YFSLLQGDZFXY"];
    NSURL *bitcoinURL = [NSURL URLWithString:@"https://coinbase.com/checkouts/0a35048913df24e0ec3d586734d456d7"];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DONATE_MESSAGE_STRING message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *paypalAlertAction = [UIAlertAction actionWithTitle:@"PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:paypalURL];
        }];
        
        UIAlertAction *bitcoinAlertAction = [UIAlertAction actionWithTitle:@"Bitcoin" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:bitcoinURL];
        }];
        
        UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
        
        [alertController addAction:paypalAlertAction];
        [alertController addAction:bitcoinAlertAction];
        [alertController addAction:cancelAlertAction];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self indexPathForSetting:setting]];
        
        alertController.popoverPresentationController.sourceView = cell;
        alertController.popoverPresentationController.sourceRect = cell.bounds;
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        RIButtonItem *paypalItem = [RIButtonItem itemWithLabel:@"PayPal" action:^{
            [[UIApplication sharedApplication] openURL:paypalURL];
        }];
        RIButtonItem *bitcoinItem = [RIButtonItem itemWithLabel:@"Bitcoin" action:^{
            [[UIApplication sharedApplication] openURL:bitcoinURL];
        }];
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:CANCEL_STRING];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:DONATE_MESSAGE_STRING cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:paypalItem, bitcoinItem, nil];
        [actionSheet otr_presentInView:self.view];
    }
}

#pragma - mark OTRShareSettingDelegate Method

- (void)didSelectShareSetting:(OTRShareSetting *)shareSetting
{
    OTRActivityItemProvider * itemProvider = [[OTRActivityItemProvider alloc] init];
    OTRQRCodeActivity * qrCodeActivity = [[OTRQRCodeActivity alloc] init];
    
    UIActivityViewController * activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[itemProvider] applicationActivities:@[qrCodeActivity]];
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self indexPathForSetting:shareSetting]];
    
    if( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityViewController.popoverPresentationController.sourceView = cell;
        activityViewController.popoverPresentationController.sourceRect = cell.bounds;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void) shareAccount:(OTRAccount*)account sender:(id)sender {
    XMPPJID *jid = [XMPPJID jidWithString:account.username];
    XMPPURI *uri = [[XMPPURI alloc] initWithJID:jid queryAction:@"subscribe" queryParameters:nil];
    NSURL *url = [NSURL URLWithString:uri.uriString];
    
    OTRQRCodeActivity * qrCodeActivity = [[OTRQRCodeActivity alloc] init];
    
    UIActivityViewController * activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:@[qrCodeActivity]];
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList];
    
    UITableViewCell *cell = sender;
    
    if( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityViewController.popoverPresentationController.sourceView = cell;
        activityViewController.popoverPresentationController.sourceRect = cell.bounds;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}


#pragma mark OTRFeedbackSettingDelegate method

- (void) presentUserVoiceViewForSetting:(OTRSetting *)setting {
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:SHOW_USERVOICE_STRING message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *showUserVoiceAlertAction = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UVConfig *config = [UVConfig configWithSite:@"chatsecure.uservoice.com"];
            [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
        }];
        
        [alertController addAction:cancelAlertAction];
        [alertController addAction:showUserVoiceAlertAction];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self indexPathForSetting:setting]];
        
        alertController.popoverPresentationController.sourceView = cell;
        alertController.popoverPresentationController.sourceRect = cell.bounds;
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:CANCEL_STRING];
        RIButtonItem *showUVItem = [RIButtonItem itemWithLabel:OK_STRING action:^{
            UVConfig *config = [UVConfig configWithSite:@"chatsecure.uservoice.com"];
            [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
        }];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:SHOW_USERVOICE_STRING cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:showUVItem, nil];
        [actionSheet otr_presentInView:self.view];
    }
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRAllAccountDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                                 rowChanges:&rowChanges
                                                                           forNotifications:notifications
                                                                               withMappings:self.mappings];
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}


@end
