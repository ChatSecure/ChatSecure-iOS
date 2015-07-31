//
//  OTRConversationViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationViewController.h"

#import "OTRSettingsViewController.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "OTRComposeViewController.h"
#import "OTRSubscriptionRequestsViewController.h"

#import "OTRConversationCell.h"
#import "OTRNotificationPermissions.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRMessage.h"
#import "UIViewController+ChatSecure.h"
#import "OTRLog.h"
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseView.h"
#import "YapDatabaseViewMappings.h"
#import "Strings.h"
#import <KVOController/FBKVOController.h>
#import "OTRAppDelegate.h"
#import "OTRProtocolManager.h"
#import "OTRWelcomeViewController.h"
#import "OTRInviteViewController.h"


static CGFloat kOTRConversationCellHeight = 80.0;

@interface OTRConversationViewController () <OTRComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *subscriptionRequestsMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *unreadMessagesMappings;

@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;

@property (nonatomic) BOOL hasPresentedOnboarding;
@end

@implementation OTRConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ////// Reset buddy status //////
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [OTRBuddy resetAllBuddyStatusesWithTransaction:transaction];
        [OTRBuddy resetAllChatStatesWithTransaction:transaction];
    }];
    
   
    ///////////// Setup Navigation Bar //////////////
    
    self.title = CHATS_STRING;
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"OTRSettingsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed:)];
    self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
    
    self.composeBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonPressed:)];
    self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem];
    
    ////////// Create TableView /////////////////
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.accessibilityIdentifier = @"conversationTableView";
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = kOTRConversationCellHeight;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRConversationCell class] forCellReuseIdentifier:[OTRConversationCell reuseIdentifier]];
    
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    
    ////////// Create YapDatabase View /////////////////
    
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRConversationGroup]
                                                               view:OTRConversationDatabaseViewExtensionName];
    
    self.subscriptionRequestsMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllPresenceSubscriptionRequestGroup]
                                                                                   view:OTRAllSubscriptionRequestsViewExtensionName];
    self.unreadMessagesMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return NSOrderedSame;
    } view:OTRUnreadMessagesViewExtensionName];
    
    
        
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.subscriptionRequestsMappings updateWithTransaction:transaction];
        [self.unreadMessagesMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    ////// KVO //////
    __weak typeof(self)weakSelf = self;
    [self.KVOController observe:[OTRProtocolManager sharedInstance] keyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols)) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            NSUInteger numberConnectedAccounts = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
            if (numberConnectedAccounts) {
                [strongSelf enableComposeButton];
            }
            else {
                [strongSelf disableComposeButton];
            }
        });
    }];
}

- (void) showOnboardingIfNeeded {
    if (self.hasPresentedOnboarding) {
        return;
    }
    __block BOOL hasAccounts = NO;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSUInteger count = [transaction numberOfKeysInCollection:[OTRAccount collection]];
        if (count > 0) {
            hasAccounts = YES;
        }
    }];
    //If there is any number of accounts launch into default conversation view otherwise onboarding time
    if (!hasAccounts) {
        OTRWelcomeViewController *welcomeViewController = [[OTRWelcomeViewController alloc] init];
        __weak OTRWelcomeViewController *weakVC = welcomeViewController;
        [welcomeViewController setCompletionBlock:^(OTRAccount *account, NSError *error) {
            if (account) {
                [OTRInviteViewController showInviteFromVC:weakVC withAccount:account];
            }
        }];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:NO completion:nil];
        self.hasPresentedOnboarding = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.cellUpdateTimer invalidate];
    [self.tableView reloadData];
    [self updateInbox];
    [self updateTitle];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateVisibleCells:) userInfo:nil repeats:YES];
    
    if([OTRProtocolManager sharedInstance].numberOfConnectedProtocols){
        [self enableComposeButton];
    }
    else {
        [self disableComposeButton];
    }
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [OTRNotificationPermissions checkPermissions];
    [self showOnboardingIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
}

- (void)settingsButtonPressed:(id)sender
{
    OTRSettingsViewController * settingsViewController = [[OTRSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)composeButtonPressed:(id)sender
{
    OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] init];
    composeViewController.delegate = self;
    UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
    modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:modalNavigationController animated:YES completion:nil];
}

- (void)enterConversationWithBuddy:(OTRBuddy *)buddy
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    OTRMessagesHoldTalkViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesViewController;
    messagesViewController.buddy = buddy;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && ![messagesViewController otr_isVisible]) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    }
    
}

- (void)updateVisibleCells:(id)sender
{
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in indexPathsArray)
    {
        OTRBuddy *buddy = [self buddyForIndexPath:indexPath];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[OTRConversationCell class]]) {
            [(OTRConversationCell *)cell setBuddy:buddy];
        }
    }
}

- (OTRBuddy *)buddyForIndexPath:(NSIndexPath *)indexPath
{
    
    __block OTRBuddy *buddy = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        buddy = [[transaction extension:OTRConversationDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    return buddy;
}

- (void)enableComposeButton
{
    self.composeBarButtonItem.enabled = YES;
}

- (void)disableComposeButton
{
    self.composeBarButtonItem.enabled = NO;
}

#pragma - mark Inbox Methods

- (void)showInbox
{
    if ([self.navigationItem.leftBarButtonItems count] != 2) {
        UIBarButtonItem *inboxBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"inbox"] style:UIBarButtonItemStylePlain target:self action:@selector(inboxButtonPressed:)];
        
        self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem,inboxBarButtonItem];
    }
}

- (void)hideInbox
{
    if ([self.navigationItem.leftBarButtonItems count] > 1) {
        self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem];
    }
    
}

- (void)inboxButtonPressed:(id)sender
{
    OTRSubscriptionRequestsViewController *viewController = [[OTRSubscriptionRequestsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)updateInbox
{
    if ([self.subscriptionRequestsMappings numberOfItemsInAllGroups] > 0) {
        [self showInbox];
    }
    else {
        [self hideInbox];
    }
}

- (void)updateTitle
{
    NSUInteger numberUnreadMessages = [self.unreadMessagesMappings numberOfItemsInAllGroups];
    if (numberUnreadMessages > 99) {
        self.title = [NSString stringWithFormat:@"%@ (99+)",CHATS_STRING];
    }
    else if (numberUnreadMessages > 0)
    {
        self.title = [NSString stringWithFormat:@"%@ (%d)",CHATS_STRING,(int)numberUnreadMessages];
    }
    else {
        self.title = CHATS_STRING;
    }
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.mappings numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBuddy *cellBuddy = [[self buddyForIndexPath:indexPath] copy];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRMessage deleteAllMessagesForBuddyId:cellBuddy.uniqueId transaction:transaction];
        }];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
    OTRBuddy * buddy = [self buddyForIndexPath:indexPath];
    
    [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
    
    [cell setBuddy:buddy];
    
    return cell;
}

#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kOTRConversationCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kOTRConversationCellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRBuddy *buddy = [self buddyForIndexPath:indexPath];
    [self enterConversationWithBuddy:buddy];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRConversationDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                                   rowChanges:&rowChanges
                                                                             forNotifications:notifications
                                                                                 withMappings:self.mappings];
    
    NSArray *subscriptionSectionChanges = nil;
    NSArray *subscriptionRowChanges = nil;
    [[self.databaseConnection ext:OTRAllSubscriptionRequestsViewExtensionName] getSectionChanges:&subscriptionSectionChanges
                                                                                      rowChanges:&subscriptionRowChanges
                                                                                forNotifications:notifications
                                                                                    withMappings:self.subscriptionRequestsMappings];
    
    if ([subscriptionSectionChanges count] || [subscriptionRowChanges count]) {
        [self updateInbox];
    }
    
    NSArray *unreadMessagesSectionChanges = nil;
    NSArray *unreadMessagesRowChanges = nil;
    
    [[self.databaseConnection ext:OTRUnreadMessagesViewExtensionName] getSectionChanges:&unreadMessagesSectionChanges
                                                                             rowChanges:&unreadMessagesRowChanges
                                                                       forNotifications:notifications
                                                                           withMappings:self.unreadMessagesMappings];
    
    if ([unreadMessagesSectionChanges count] || [unreadMessagesRowChanges count]) {
        [self updateTitle];
    }
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 && [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate:
            case YapDatabaseViewChangeMove:
                break;
        }
    }
    
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

#pragma - mark OTRComposeViewController Method

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddy:(OTRBuddy *)buddy
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self enterConversationWithBuddy:buddy];
    }];
}



@end
