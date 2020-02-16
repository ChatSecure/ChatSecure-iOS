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
#import "UITableView+ChatSecure.h"
@import YapDatabase;

#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
@import KVOController;
#import "OTRAppDelegate.h"
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"
#import "ChatSecureCoreCompat-Swift.h"
@import OTRAssets;

#import "OTRXMPPManager.h"
#import "OTRXMPPRoomManager.h"
#import "OTRBuddyApprovalCell.h"
#import "OTRStrings.h"
#import "OTRvCard.h"
#import "XMPPvCardTemp.h"

static CGFloat kOTRConversationCellHeight = 80.0;

@interface OTRConversationViewController () <OTRYapViewHandlerDelegateProtocol, OTRAccountDatabaseCountDelegate >

@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) OTRYapViewHandler *conversationListViewHandler;

@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;

@property (nonatomic) BOOL hasPresentedOnboarding;

@property (nonatomic, strong) OTRAccountDatabaseCount *accountCounter;
@property (nonatomic, strong) MigrationInfoHeaderView *migrationInfoHeaderView;
@property (nonatomic, strong) UISegmentedControl *inboxArchiveControl;

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
    
    _inboxArchiveControl = [[UISegmentedControl alloc] initWithItems:@[INBOX_STRING(), ARCHIVE_STRING()]];
    _inboxArchiveControl.selectedSegmentIndex = 0;
    [self updateInboxArchiveFilteringAndShowArchived:NO];
    [_inboxArchiveControl addTarget:self action:@selector(inboxArchiveControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _inboxArchiveControl;
    
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
    [self.conversationListViewHandler setup:OTRArchiveFilteredConversationsName groups:@[OTRAllPresenceSubscriptionRequestGroup, OTRConversationGroup]];
    
    [self.tableView reloadData];
    [self updateInboxArchiveItems:self.navigationItem.titleView];
    
    self.accountCounter = [[OTRAccountDatabaseCount alloc] initWithDatabaseConnection:[OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection delegate:self];
}

- (void) showOnboardingIfNeeded {
    if (self.hasPresentedOnboarding) {
        return;
    }
    __block BOOL hasAccounts = NO;
    NSParameterAssert(OTRDatabaseManager.shared.uiConnection != nil);
    if (!OTRDatabaseManager.shared.uiConnection) {
        DDLogWarn(@"Database isn't setup yet! Skipping onboarding...");
        return;
    }
    [OTRDatabaseManager.shared.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        NSUInteger count = [transaction numberOfKeysInCollection:[OTRAccount collection]];
        if (count > 0) {
            hasAccounts = YES;
        }
    } completionBlock:^{
        [self continueOnboarding:hasAccounts];
    }];
}

- (void) continueOnboarding:(BOOL)hasAccounts {
    UIStoryboard *onboardingStoryboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:[OTRAssets resourcesBundle]];
    
    //If there is any number of accounts launch into default conversation view otherwise onboarding time
    if (!hasAccounts) {
        UINavigationController *welcomeNavController = [onboardingStoryboard instantiateInitialViewController];
        welcomeNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:welcomeNavController animated:YES completion:nil];
        self.hasPresentedOnboarding = YES;
        return;
    }
    
    OTRXMPPAccount *needsMigration = [self checkIfNeedsMigration];
    if (needsMigration != nil) {
        // Show local notification prompt
        OTRServerDeprecation *deprecationInfo = [OTRServerDeprecation deprecationInfoWithServer:needsMigration.bareJID.domain];
        if (deprecationInfo != nil) {
            NSString *notificationBody = [NSString stringWithFormat:MIGRATION_NOTIFICATION_STRING(), deprecationInfo.name];
            NSDate *now = [NSDate date];
            if (deprecationInfo.shutdownDate != nil && [now compare:deprecationInfo.shutdownDate] == NSOrderedAscending) {
                // Show shutdown date, in x days format
                NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                    fromDate:now
                                                                      toDate:deprecationInfo.shutdownDate
                                                                     options:0];
                long days = [components day];
                notificationBody = [NSString stringWithFormat:MIGRATION_NOTIFICATION_WITH_DATE_STRING(), days];
            }
            
            [[UIApplication sharedApplication] showLocalNotificationWithGroupingIdentifier:@"Migration" body:notificationBody badge:1 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:kOTRNotificationTypeNone, kOTRNotificationType, @"Migration", kOTRNotificationThreadKey, nil] recurring:YES];
        }
    } else {
        [[UIApplication sharedApplication] cancelRecurringLocalNotificationWithIdentifier:@"Migration"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.cellUpdateTimer invalidate];
    [self.tableView reloadData];
    [self updateInboxArchiveItems:self.navigationItem.titleView];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateVisibleCells:) userInfo:nil repeats:YES];
    
    
    [self updateComposeButton:self.accountCounter.numberOfAccounts];
    [self showMigrationViewIfNeeded];
}

- (OTRXMPPAccount *)checkIfNeedsMigration {
    __block OTRXMPPAccount *needsMigration;
    [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray<OTRAccount*> *accounts = [OTRAccount allAccountsWithTransaction:transaction];
        [accounts enumerateObjectsUsingBlock:^(OTRAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj isKindOfClass:[OTRXMPPAccount class]]) {
                return;
            }
            OTRXMPPAccount *xmppAccount = (OTRXMPPAccount *)obj;
            if ([xmppAccount needsMigration]) {
                needsMigration = xmppAccount;
                *stop = YES;
            }
        }];
    }];
    return needsMigration;
}

- (void)showMigrationViewIfNeeded {
    OTRXMPPAccount *needsMigration = [self checkIfNeedsMigration];
    if (needsMigration != nil) {
        self.migrationInfoHeaderView = [self createMigrationHeaderView:needsMigration];
        self.tableView.tableHeaderView = self.migrationInfoHeaderView;
    } else if (self.migrationInfoHeaderView != nil) {
        self.migrationInfoHeaderView = nil;
        self.tableView.tableHeaderView = nil;
    }
}

- (void) showDonationPrompt {
    if (!OTRBranding.allowsDonation ||
        self.hasPresentedOnboarding ||
        TransactionObserver.hasValidReceipt) {
        return;
    }
    NSDate *ignoreDate = [NSUserDefaults.standardUserDefaults objectForKey:kOTRIgnoreDonationDateKey];
    BOOL dateCheck = NO;
    if (!ignoreDate) {
        dateCheck = YES;
    } else {
        NSTimeInterval lastIgnored = [[NSDate date] timeIntervalSinceDate:ignoreDate];
        NSTimeInterval twoWeeks = 60 * 60 * 24 * 14;
        if (lastIgnored > twoWeeks) {
            dateCheck = YES;
        }
    }
    if (!dateCheck) {
        return;
    }
    NSString *title = [NSString stringWithFormat:@"❤️ %@", DONATE_STRING()];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:DID_YOU_KNOW_DONATION_STRING() preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *donate = [UIAlertAction actionWithTitle:DONATE_STRING() style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [PurchaseViewController showFrom:self];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:MAYBE_LATER_STRING() style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:donate];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    [NSUserDefaults.standardUserDefaults setObject:NSDate.date forKey:kOTRIgnoreDonationDateKey];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showOnboardingIfNeeded];
    [self showDonationPrompt];
}
         


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
}

- (void)inboxArchiveControlValueChanged:(id)sender {
    if (![sender isKindOfClass:[UISegmentedControl class]]) {
        return;
    }
    UISegmentedControl *segment = sender;
    BOOL showArchived = NO;
    if (segment.selectedSegmentIndex == 0) {
        showArchived = NO;
    } else if (segment.selectedSegmentIndex == 1) {
        showArchived = YES;
    }
    [self updateInboxArchiveFilteringAndShowArchived:showArchived];
}

- (void) updateInboxArchiveFilteringAndShowArchived:(BOOL)showArchived {
    [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        YapDatabaseFilteredViewTransaction *fvt = [transaction ext:OTRArchiveFilteredConversationsName];
        YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
            if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
                id<OTRThreadOwner> threadOwner = object;
                BOOL isArchived = threadOwner.isArchived;
                return showArchived == isArchived;
            }
            return !showArchived; // Don't show presence requests in Archive
        }];
        [fvt setFiltering:filtering versionTag:[NSUUID UUID].UUIDString];
    }];
}

- (void)settingsButtonPressed:(id)sender
{
    UIViewController * settingsViewController = [GlobalTheme.shared settingsViewController];
    
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
    id <OTRThreadOwner> thread = object;
    return thread;
}

- (void)updateComposeButton:(NSUInteger)numberOfaccounts
{
    self.composeBarButtonItem.enabled = numberOfaccounts > 0;
}

- (void)updateInboxArchiveItems:(UIView*)sender
{
//    if (![sender isKindOfClass:[UISegmentedControl class]]) {
//        return;
//    }
//    UISegmentedControl *control = sender;
    // We can't accurately calculate the unread messages for inbox vs archived
    // This will require a massive reindexing of all messages which should be avoided until db performance is improved
    
    /*
    __block NSUInteger numberUnreadMessages = 0;
    [self.conversationListViewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        numberUnreadMessages = [transaction numberOfUnreadMessages];
    }];
    if (numberUnreadMessages > 99) {
        NSString *title = [NSString stringWithFormat:@"%@ (99+)",CHATS_STRING()];
    }
    else if (numberUnreadMessages > 0)
    {
        NSString *title = [NSString stringWithFormat:@"%@ (%d)",CHATS_STRING(),(int)numberUnreadMessages];
    }
    else {
        self.title = CHATS_STRING();
    }
     */
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.migrationInfoHeaderView != nil) {
        UIView *headerView = self.migrationInfoHeaderView;
        [headerView setNeedsLayout];
        [headerView layoutIfNeeded];
        int height = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        CGRect frame = headerView.frame;
        frame.size.height = height + 1;
        headerView.frame = frame;
        self.tableView.tableHeaderView = headerView;
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
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    //Delete conversation
//    if(editingStyle == UITableViewCellEditingStyleDelete) {
//        
//    }
//    
//}

- (void) handleSubscriptionRequest:(OTRXMPPBuddy*)buddy approved:(BOOL)approved {
    __block OTRAccount *account = nil;
    [self.conversationListViewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        account = [buddy accountWithTransaction:transaction];
    }];
    OTRXMPPManager *manager = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
    [buddy setAskingForApproval:NO];
    if (approved) {
        [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            buddy.trustLevel = BuddyTrustLevelRoster;
            [buddy saveWithTransaction:transaction];
        }];
        // TODO - use the queue for this!
        [manager.xmppRoster acceptPresenceSubscriptionRequestFrom:buddy.bareJID andAddToRoster:YES];
        if ([self.delegate respondsToSelector:@selector(conversationViewController:didSelectThread:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate conversationViewController:self didSelectThread:buddy];
            });
        }
    } else {
        [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy removeWithTransaction:transaction];
        }];
        [manager.xmppRoster rejectPresenceSubscriptionRequestFrom:buddy.bareJID];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRBuddyImageCell *cell = nil;
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    if ([thread isKindOfClass:[OTRXMPPBuddy class]] &&
        [(OTRXMPPBuddy*)thread askingForApproval]) {
        OTRBuddyApprovalCell *approvalCell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyApprovalCell reuseIdentifier] forIndexPath:indexPath];
        [approvalCell setActionBlock:^(OTRBuddyApprovalCell *cell, BOOL approved) {
            [self handleSubscriptionRequest:(OTRXMPPBuddy*)thread approved:approved];
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

//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewCellEditingStyleDelete;
//}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    return [UITableView editActionsForThread:thread deleteActionAlsoRemovesFromRoster:NO connection:OTRDatabaseManager.shared.writeConnection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id <OTRThreadOwner> thread = [self threadForIndexPath:indexPath];
    
    // Bail out if it's a subscription request
    if ([thread isKindOfClass:[OTRXMPPBuddy class]] &&
        [(OTRXMPPBuddy*)thread askingForApproval]) {
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
    [self updateInboxArchiveItems:self.navigationItem.titleView];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if ([rowChanges count] == 0 && sectionChanges == 0) {
        return;
    }
    
    [self updateInboxArchiveItems:self.navigationItem.titleView];
    
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

#pragma - mark Account Migration Methods

- (MigrationInfoHeaderView *)createMigrationHeaderView:(OTRXMPPAccount *)account
{
    OTRServerDeprecation *deprecationInfo = [OTRServerDeprecation deprecationInfoWithServer:account.bareJID.domain];
    if (deprecationInfo == nil) {
        return nil; // Should not happen if we got here already
    }
    UINib *nib = [UINib nibWithNibName:@"MigrationInfoHeaderView" bundle:OTRAssets.resourcesBundle];
    MigrationInfoHeaderView *header = (MigrationInfoHeaderView*)[nib instantiateWithOwner:self options:nil][0];
    [header.titleLabel setText:MIGRATION_STRING()];
    if (deprecationInfo.shutdownDate != nil && [[NSDate date] compare:deprecationInfo.shutdownDate] == NSOrderedAscending) {
        // Show shutdown date
        [header.descriptionLabel setText:[NSString stringWithFormat:MIGRATION_INFO_WITH_DATE_STRING(), deprecationInfo.name, [NSDateFormatter localizedStringFromDate:deprecationInfo.shutdownDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]]];
    } else {
        // No shutdown date or already passed
        [header.descriptionLabel setText:[NSString stringWithFormat:MIGRATION_INFO_STRING(), deprecationInfo.name]];
    }
    [header.startButton setTitle:MIGRATION_START_STRING() forState:UIControlStateNormal];
    [header setAccount:account];
    return header;
}

- (IBAction)didPressStartMigrationButton:(id)sender {
    if (self.migrationInfoHeaderView != nil) {
        OTRXMPPAccount *oldAccount = self.migrationInfoHeaderView.account;
        OTRAccountMigrationViewController *migrateVC = [[OTRAccountMigrationViewController alloc] initWithOldAccount:oldAccount];
        migrateVC.showsCancelButton = YES;
        migrateVC.modalPresentationStyle = UIModalPresentationFormSheet;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:migrateVC];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

@end
