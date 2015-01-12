    //
//  OTRConversationViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationViewController.h"

#import "OTRSettingsViewController.h"
#import "OTRMessagesViewController.h"
#import "OTRComposeViewController.h"
#import "OTRSubscriptionRequestsViewController.h"
#import "YapDatabaseFullTextSearchTransaction.h"

#import "OTRConversationCell.h"
#import "OTRNotificationPermissions.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRXMPPBuddy.h"
#import "OTRMessage.h"
#import "UIViewController+ChatSecure.h"
#import "OTRLog.h" 
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseView.h"
#import "YapDatabaseViewMappings.h"

#import "OTROnboardingStepsController.h"
#import "OTRAppDelegate.h"

static CGFloat kOTRConversationCellHeight = 80.0;


@interface OTRConversationViewController () <OTRComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) YapDatabaseConnection *connection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *chatMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *subscriptionRequestsMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *unreadMessagesMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *deleteMessagesMappings;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) NSArray *searchResults;

@property (nonatomic, weak) id textViewNotificationObject;

@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;
@end

@implementation OTRConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*OTRComposeViewController * composeView = [[OTRComposeViewController alloc] init];
    
    //important to set the viewcontroller's delegate to be self
    composeView.delegate = self;*/
    
    ////// Reset buddy status //////
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [OTRBuddy resetAllBuddyStatusesWithTransaction:transaction];
        [OTRBuddy resetAllChatStatesWithTransaction:transaction];
    }];
    
    //////////// TabBar Icon /////////
    UITabBarItem *tab1 = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag:1];
    tab1.title = CHATS_STRING;
    [self setTabBarItem:tab1];
    

    ///////////// Setup Navigation Bar //////////////
    
    self.title = CHATS_STRING;
    //UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"OTRSettingsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed:)];
    //self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
    
    self.composeBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonPressed:)];
    self.navigationItem.leftBarButtonItem = self.composeBarButtonItem;

    
    /////////// Search Bar ///////////
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];
    
    
    ////////// Create TableView /////////////////
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.accessibilityIdentifier = @"conversationTableView";
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = kOTRConversationCellHeight;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRConversationCell class] forCellReuseIdentifier:[OTRConversationCell reuseIdentifier]];
    
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    ////////// Create YapDatabase View /////////////////
    
    self.connection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.connection.name = NSStringFromClass([self class]);
    [self.connection beginLongLivedReadTransaction];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRConversationGroup]
                                                               view:OTRConversationDatabaseViewExtensionName];
    
    self.chatMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRChatMessageGroup]
                                                               view:OTRChatDatabaseViewExtensionName];
    self.subscriptionRequestsMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllPresenceSubscriptionRequestGroup]
                                                                                   view:OTRAllSubscriptionRequestsViewExtensionName];
    self.unreadMessagesMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return NSOrderedSame;
    } view:OTRUnreadMessagesViewExtensionName];
    
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.subscriptionRequestsMappings updateWithTransaction:transaction];
        [self.unreadMessagesMappings updateWithTransaction:transaction];
        [self.chatMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    
    
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
    
    [[OTRProtocolManager sharedInstance] addObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols)) options:NSKeyValueObservingOptionNew context:NULL];
    
    /*if (![[OTRDatabaseManager sharedInstance] existsYapDatabase]) {
        ////// Onboarding //////
        OTROnboardingStepsController *onboardingStepsController = [[OTROnboardingStepsController alloc] init];
        onboardingStepsController.stepsBar.hideCancelButton = YES;
        
        [self.navigationController presentViewController:onboardingStepsController animated:NO completion:nil];
        
    }*/
    [self.tableView reloadData];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [OTRNotificationPermissions checkPermissions];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
    
    [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols))];
}

- (void)settingsButtonPressed:(id)sender
{
    OTRSettingsViewController * settingsViewController = [[OTRSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)composeButtonPressed:(id)sender
{
    OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] initWithOptions:NO];
    composeViewController.delegate = self;
    UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
    //modalNavigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:modalNavigationController animated:YES completion:nil];
}

- (void)enterConversationWithBuddy:(OTRBuddy *)buddy
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    OTRMessagesViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesViewController;
    messagesViewController.hidesBottomBarWhenPushed = YES;
    messagesViewController.autoScroll = YES;
    messagesViewController.buddy = buddy;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && ![messagesViewController otr_isVisible]) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    }
    
}

- (void)enterConversationWithBuddy:(OTRBuddy *)buddy andMessage:(OTRMessage *)message
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    OTRMessagesViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesViewController;
    messagesViewController.hidesBottomBarWhenPushed = YES;
    messagesViewController.autoScroll = NO;
    messagesViewController.buddy = buddy;
    messagesViewController.message = message;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && ![messagesViewController otr_isVisible]) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    }
    
    
}

- (void)updateVisibleCells:(id)sender
{
    if ([self useSearchResults]) {
        return;
    }
    
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


- (OTRMessage *)messageForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if(![self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                return self.searchResults[viewIndexPath.row];
            }
        }
    }
    
    return nil;
}

- (OTRBuddy *)buddyForIndexPath:(NSIndexPath *)indexPath
{
     NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    

    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                return self.searchResults[viewIndexPath.row];
            }
            else{
                __block OTRBuddy *buddy = nil;
                OTRMessage *message = self.searchResults[viewIndexPath.row];
                [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                   
                    buddy =  [message buddyWithTransaction:transaction];
                }];
                
                return buddy;
            }
        }
    }
    else
    {
        __block OTRBuddy *buddy = nil;
        [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            
            buddy = [[transaction extension:OTRConversationDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
        }];
        
        return buddy;
    }
    
    return nil;
}

- (BOOL)useSearchResults
{
    if([self.searchBar.text length])
    {
        return YES;
    }
    return NO;
}

- (void)enableComposeButton
{
    self.composeBarButtonItem.enabled = YES;
}

- (void)disableComposeButton
{
    self.composeBarButtonItem.enabled = NO;
}

#pragma KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSUInteger numberConnectedAccounts = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
    if (numberConnectedAccounts) {
        [self enableComposeButton];
    }
    else {
        [self disableComposeButton];
    }
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
        self.navigationItem.leftBarButtonItem = self.composeBarButtonItem;
    }
    
}

- (void)inboxButtonPressed:(id)sender
{
    OTRSubscriptionRequestsViewController *viewController = [[OTRSubscriptionRequestsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];

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
        self.title = [NSString stringWithFormat:@"%@ (%ld)",CHATS_STRING,numberUnreadMessages];
    }
    else {
        self.title = CHATS_STRING;
    }
}


- (void)updateLasMessage
{
    [self.tableView reloadData];
}



#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    if ([self useSearchResults]) {
        numberOfRows = [self.searchResults count];
    }
    else {
        numberOfRows = [self.mappings numberOfItemsInSection:section];
    }
    
    return numberOfRows;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self useSearchResults]) {
        return;
    }
    
    
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBuddy *cellBuddy = [[self buddyForIndexPath:indexPath] copy];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
        {
            [OTRMessage deleteAllMessagesForBuddyId:cellBuddy.uniqueId transaction:transaction];
            //TODO[[[OTRXMPPBuddy fetchObjectWithUniqueID:cellBuddy.uniqueId transaction:transaction] copy] removeWithTransaction:transaction] ;
            
        }
        completionBlock:^{
           
            [self.tableView reloadData];

        } ];
        
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
                OTRBuddy * buddy = [self buddyForIndexPath:indexPath];
                
                [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                
                [cell setBuddy:buddy];
                
                return cell;
            }
            else{
                OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
                
                OTRBuddy * buddy = [self buddyForIndexPath:indexPath];
                OTRMessage * message = [self messageForIndexPath:indexPath];
                
                [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                [cell setBuddy:buddy withMessage:message andSearch:self.searchString];
                
                return cell;

            }
            
            return nil;
        }
        
        return nil;
    }
    else{
    
        OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
        OTRBuddy * buddy = [self buddyForIndexPath:indexPath];
        
        [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];

        
        [cell setBuddy:buddy];
        
        return cell;
    }
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
    if ([self useSearchResults]) {
        return nil;
    }
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self useSearchResults]) {
        OTRBuddy *buddy = [self buddyForIndexPath:indexPath];
        OTRMessage * message = [self messageForIndexPath:indexPath];
        [self enterConversationWithBuddy:buddy andMessage:message];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }

    }
    else{
        OTRBuddy *buddy = [self buddyForIndexPath:indexPath];
        [self enterConversationWithBuddy:buddy];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
     NSArray *notifications = [self.connection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    /*
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        
        [self.mappings updateWithTransaction:transaction];
        [self.chatMappings updateWithTransaction:transaction];
        [self.unreadMessagesMappings updateWithTransaction:transaction];
        [self.subscriptionRequestsMappings updateWithTransaction:transaction];
    }];*/
    
    
    if ([self useSearchResults]) {
        return;
    }
    
    [[self.connection ext:OTRConversationDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                           rowChanges:&rowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.mappings];
    
    NSArray *subscriptionSectionChanges = nil;
    NSArray *subscriptionRowChanges = nil;
    [[self.connection ext:OTRAllSubscriptionRequestsViewExtensionName] getSectionChanges:&subscriptionSectionChanges
                                                                              rowChanges:&subscriptionRowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.subscriptionRequestsMappings];
    
    if ([subscriptionSectionChanges count] || [subscriptionRowChanges count]) {
        [self updateInbox];
    }
    
    NSArray *unreadMessagesSectionChanges = nil;
    NSArray *unreadMessagesRowChanges = nil;
    
    [[self.connection ext:OTRUnreadMessagesViewExtensionName] getSectionChanges:&unreadMessagesSectionChanges
                                                                     rowChanges:&unreadMessagesRowChanges
                                                               forNotifications:notifications
                                                                   withMappings:self.unreadMessagesMappings];
    
    if ([unreadMessagesSectionChanges count] || [unreadMessagesRowChanges count]) {
        [self updateTitle];
    }
    
    
    NSArray *chatSectionChanges = nil;
    NSArray *chatRowChanges = nil;
    
    [[self.connection ext:OTRUnreadMessagesViewExtensionName] getSectionChanges:&chatSectionChanges
                                                                     rowChanges:&chatRowChanges
                                                               forNotifications:notifications
                                                                   withMappings:self.chatMappings];
    
    if ([chatSectionChanges count] || [chatRowChanges count]) {
        [self.tableView reloadData];
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


#pragma - mark UISearchBarDelegateMethods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length]) {
        
        self.searchString = [NSString stringWithFormat:@"%@*",searchText];
        
        NSMutableArray *tempSearchResults = [NSMutableArray new];
        [self.connection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:OTRChatNameSearchDatabaseViewExtensionName] enumerateKeysAndObjectsMatching:self.searchString usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
                if ([object isKindOfClass:[OTRBuddy class]]) {
                    [tempSearchResults addObject:object];
                }
                
                if ([object isKindOfClass:[OTRMessage class]]) {
                    [tempSearchResults addObject:object];
                }
    
            }];
        } completionBlock:^{
            self.searchResults = tempSearchResults;
            [self.tableView reloadData];
        }];  
    }
    else{
        [self.tableView reloadData];
    }
}



@end
