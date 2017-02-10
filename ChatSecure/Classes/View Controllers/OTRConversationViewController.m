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

#import "OTRConversationCell.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRXMPPBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "UIViewController+ChatSecure.h"
#import "OTRLog.h"
@import YapDatabase;

#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
@import KVOController;
#import "OTRAppDelegate.h"
#import "OTRTheme.h"
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import OTRAssets;

#import "OTRMessagesGroupViewController.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPRoomManager.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "OTRBuddyApprovalCell.h"

static CGFloat kOTRConversationCellHeight = 80.0;

@interface OTRConversationViewController () <OTRYapViewHandlerDelegateProtocol, OTRAccountDatabaseCountDelegate >

@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) OTRYapViewHandler *conversationListViewHandler;

@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;

@property (nonatomic) BOOL hasPresentedOnboarding;

@property (nonatomic, strong) OTRAccountDatabaseCount *accountCounter;

@end

@implementation OTRConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];    
   
    ///////////// Setup Navigation Bar //////////////
    
    self.title = CHATS_STRING();
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
    [self.tableView registerClass:[OTRBuddyApprovalCell class] forCellReuseIdentifier:[OTRBuddyApprovalCell reuseIdentifier]];
    [self.tableView registerClass:[OTRBuddyInfoCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    
    ////////// Create YapDatabase View /////////////////
    
    self.conversationListViewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:[OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection databaseChangeNotificationName:[DatabaseNotificationName LongLivedTransactionChanges]];
    self.conversationListViewHandler.delegate = self;
    [self.conversationListViewHandler setup:OTRConversationDatabaseViewExtensionName groups:@[OTRAllPresenceSubscriptionRequestGroup, OTRConversationGroup]];
    
    [self.tableView reloadData];
    [self updateTitle];
    
    self.accountCounter = [[OTRAccountDatabaseCount alloc] initWithDatabaseConnection:[OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection delegate:self];
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
        welcomeNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:welcomeNavController animated:YES completion:nil];
        self.hasPresentedOnboarding = YES;
    } else if ([PushController getPushPreference] == PushPreferenceUndefined) {
        EnablePushViewController *pushVC = [onboardingStoryboard instantiateViewControllerWithIdentifier:@"enablePush"];
        pushVC.modalPresentationStyle = UIModalPresentationFormSheet;
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
    [self updateTitle];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateVisibleCells:) userInfo:nil repeats:YES];
    
    
    [self updateComposeButton:self.accountCounter.numberOfAccounts];
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
    UIViewController * settingsViewController = [[OTRAppDelegate appDelegate].theme settingsViewController];
    
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

- (id) objectAtIndexPath:(NSIndexPath*)indexPath {
    return [self.conversationListViewHandler object:indexPath];
}

- (id <OTRThreadOwner>)threadForIndexPath:(NSIndexPath *)indexPath
{
    id object = [self objectAtIndexPath:indexPath];
    
    id <OTRThreadOwner> thread = nil;
    
    // Create a fake buddy for subscription requests
    if ([object isKindOfClass:[OTRXMPPPresenceSubscriptionRequest class]]) {
        OTRXMPPPresenceSubscriptionRequest *request = object;
        OTRXMPPBuddy *buddy = [[OTRXMPPBuddy alloc] init];
        buddy.hasIncomingSubscriptionRequest = YES;
        buddy.displayName = request.displayName;
        buddy.username = request.jid;
        thread = buddy;
    } else {
        thread = object;
    }
    
    return thread;
}

- (void)updateComposeButton:(NSUInteger)numberOfaccounts
{
    self.composeBarButtonItem.enabled = numberOfaccounts > 0;
}

- (void)updateTitle
{
    __block NSUInteger numberUnreadMessages = 0;
    [self.conversationListViewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        numberUnreadMessages = [transaction numberOfUnreadMessages];
    }];
    if (numberUnreadMessages > 99) {
        self.title = [NSString stringWithFormat:@"%@ (99+)",CHATS_STRING()];
    }
    else if (numberUnreadMessages > 0)
    {
        self.title = [NSString stringWithFormat:@"%@ (%d)",CHATS_STRING(),(int)numberUnreadMessages];
    }
    else {
        self.title = CHATS_STRING();
    }
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.conversationListViewHandler.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversationListViewHandler.mappings numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRBaseMessage deleteAllMessagesForBuddyId:[thread threadIdentifier] transaction:transaction];
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

- (void) handleSubscriptionRequest:(OTRXMPPPresenceSubscriptionRequest*)request approved:(BOOL)approved {
    __block OTRXMPPAccount *account = nil;
    [self.conversationListViewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [request accountWithTransaction:transaction];
    }];
    OTRXMPPManager *manager = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
    XMPPJID *jid = [XMPPJID jidWithString:request.jid];
    if (approved) {
        // Create new buddy in database so it can be shown immediately in list
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyWithUsername:request.jid withAccountUniqueId:account.uniqueId transaction:transaction];
            if (!buddy) {
                buddy = [[OTRXMPPBuddy alloc] init];
                buddy.username = request.jid;
                buddy.accountUniqueId = account.uniqueId;
                // hack to show buddy in conversations view
                buddy.lastMessageId = @"";
            }
            buddy.displayName = request.jid;
            [buddy saveWithTransaction:transaction];
        }];
        [manager.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
        
    } else {
        [manager.xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
    }
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [request removeWithTransaction:transaction];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRBuddyImageCell *cell = nil;
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    if ([thread isKindOfClass:[OTRXMPPBuddy class]] &&
        ((OTRXMPPBuddy*)thread).hasIncomingSubscriptionRequest) {
        OTRBuddyApprovalCell *approvalCell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyApprovalCell reuseIdentifier] forIndexPath:indexPath];
        [approvalCell setActionBlock:^(OTRBuddyApprovalCell *cell, BOOL approved) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            id object = [self objectAtIndexPath:indexPath];
            if ([object isKindOfClass:[OTRXMPPPresenceSubscriptionRequest class]]) {
                OTRXMPPPresenceSubscriptionRequest *request = object;
                [self handleSubscriptionRequest:request approved:approved];
            }
        }];
        cell = approvalCell;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
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
    
    // Bail out if it's a subscription request
    if ([thread isKindOfClass:[OTRXMPPBuddy class]] &&
        ((OTRXMPPBuddy*)thread).hasIncomingSubscriptionRequest) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(conversationViewController:didSelectThread:)]) {
        [self.delegate conversationViewController:self didSelectThread:thread];
    }
}

#pragma - mark OTRAccountDatabaseCountDelegate method

- (void)accountCountChanged:(OTRAccountDatabaseCount *)counter {
    [self updateComposeButton:counter.numberOfAccounts];
}

#pragma - mark YapDatabse Methods

- (void)didSetupMappings:(OTRYapViewHandler *)handler
{
    [self.tableView reloadData];
    [self updateTitle];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if ([rowChanges count] == 0 && sectionChanges == 0) {
        return;
    }
    
    [self updateTitle];
    
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
