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
@import YapDatabase.YapDatabaseView;

#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRStrings.h"
#import <KVOController/FBKVOController.h>
#import "OTRAppDelegate.h"
#import "OTRTheme.h"
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import OTRAssets;
#import "OTRLanguageManager.h"
#import "OTRMessagesGroupViewController.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPRoomManager.h"

static CGFloat kOTRConversationCellHeight = 80.0;

@interface OTRConversationViewController ()

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
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [OTRBuddy resetAllBuddyStatusesWithTransaction:transaction];
        [OTRBuddy resetAllChatStatesWithTransaction:transaction];
    }];
    
   
    ///////////// Setup Navigation Bar //////////////
    
    self.title = CHATS_STRING;
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"OTRSettingsIcon" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed:)];
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
    UIStoryboard *onboardingStoryboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:[OTRAssets resourcesBundle]];

    //If there is any number of accounts launch into default conversation view otherwise onboarding time
    if (!hasAccounts) {
        UINavigationController *welcomeNavController = [onboardingStoryboard instantiateInitialViewController];
        OTRWelcomeViewController *welcomeViewController = welcomeNavController.viewControllers[0];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
        [self presentViewController:nav animated:YES completion:nil];
        self.hasPresentedOnboarding = YES;
    } else if ([PushController getPushPreference] == PushPreferenceUndefined) {
        EnablePushViewController *pushVC = [onboardingStoryboard instantiateViewControllerWithIdentifier:@"enablePush"];
        if (pushVC) {
            [self presentViewController:pushVC animated:YES completion:nil];
        }
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
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSelectCompose:)]) {
        [self.delegate conversationViewController:self didSelectCompose:sender];
    }
}

- (void)updateVisibleCells:(id)sender
{
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in indexPathsArray)
    {
        id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[OTRConversationCell class]]) {
            [(OTRConversationCell *)cell setThread:thread];
        }
    }
}

- (id <OTRThreadOwner>)threadForIndexPath:(NSIndexPath *)indexPath
{
    
    __block id thread = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        thread = [[transaction extension:OTRConversationDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    return thread;
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
        UIBarButtonItem *inboxBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"inbox" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(inboxButtonPressed:)];
        
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
        id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRMessage deleteAllMessagesForBuddyId:[thread threadIdentifier] transaction:transaction];
        }];
        
        if ([thread isKindOfClass:[OTRXMPPRoom class]]) {
            
            //Leave room
            NSString *accountKey = [thread threadAccountIdentifier];
            __block OTRAccount *account = nil;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                account = [OTRAccount fetchObjectWithUniqueID:accountKey transaction:transaction];
            }];
            OTRXMPPManager *xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
            XMPPJID *jid = [XMPPJID jidWithString:((OTRXMPPRoom *)thread).jid];
            [xmppManager.roomManager leaveRoom:jid];
            
            //Delete database items
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [((OTRXMPPRoom *)thread) removeWithTransaction:transaction];
            }];
        }
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    
    [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
    
    [cell setThread:thread];
    
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
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSelectThread:)]) {
        [self.delegate conversationViewController:self didSelectThread:thread];
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
@end
