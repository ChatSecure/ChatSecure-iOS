//
//  OTRBuddyListViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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

#import "OTRBuddyListViewController.h"
#import "OTRChatViewController.h"
#import "OTRLoginViewController.h"
#import "Strings.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"
#import "OTRSettingsViewController.h"
#import "OTRManagedStatusMessage.h"
#import "OTRManagedGroup.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRBuddyListSectionInfo.h"
#import "OTRNewBuddyViewController.h"
#import "OTRXMPPManagedPresenceSubscriptionRequest.h"
#import "OTRSubscriptionRequestsViewController.h"
#import "OTRBuddyViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRImages.h"
#import "OTRUtilities.h"

#import "OTRBuddyCell.h"
#import "OTRRecentBuddyCell.h"

//#define kSignoffTime 500

#define RECENTS_SECTION_INDEX 0
#define BUDDIES_SECTION_INDEX 1

#define HEADER_HEIGHT 24

@interface OTRBuddyListViewController(Private)
- (void) selectActiveConversation;
- (void) deleteBuddy:(OTRManagedBuddy*)buddy;
@end

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize chatViewController;
@synthesize selectedBuddy;
@synthesize searchDisplayController;
@synthesize groupManager;

- (void) dealloc {
    self.buddyListTableView = nil;
    self.chatViewController = nil;
    self.selectedBuddy = nil;
    _buddyFetchedResultsController = nil;
    _recentBuddiesFetchedResultsController = nil;
    _searchBuddyFetchedResultsController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        self.title = BUDDY_LIST_STRING;
        buddyStatusImageDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
        shouldShowStatus = YES;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    
    OTRBuddyListSectionInfo * recentSectionInfo = [[OTRBuddyListSectionInfo alloc] init];
    recentSectionInfo.isOpen = YES;
    recentSectionInfo.title = RECENT_STRING;

    OTRBuddyListSectionInfo * offlineSectionInfo = [[OTRBuddyListSectionInfo alloc] init];
    offlineSectionInfo.isOpen = NO;
    offlineSectionInfo.title = OFFLINE_STRING;
    
    self.sectionInfoSet = [NSMutableOrderedSet orderedSetWithObjects:recentSectionInfo, offlineSectionInfo, nil];
    
    [self setupBuddyFetchedResultsControllers];
    
    self.buddyListTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    buddyListTableView.dataSource = self;
    buddyListTableView.delegate = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSettingsView:)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = SETTINGS_STRING;
    [self.view addSubview:buddyListTableView];
    [self.buddyListTableView registerClass:[OTRSectionHeaderView class] forHeaderFooterViewReuseIdentifier:[OTRSectionHeaderView reuseIdentifier]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
    
    UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.buddyListTableView.frame.size.width, 44)];
    //searchBar.delegate = self;
    self.buddyListTableView.tableHeaderView = searchBar;
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    self.buddyListTableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    
    [self refreshLeftBarItems];
    
    [self updateTitleWithUnreadCount:[[self.unreadMessagesFetchedResultsContrller sections][0] numberOfObjects]];
    // uncomment to see a LOT of console output
	// [Debug setDebuggingEnabled:YES];
	//DDLogInfo(@"LibOrange (v: %@): -beginTest\n", @lib_orange_version_string);
}

- (void)didUpdateNumberOfConnectedAccounts:(NSUInteger)numberOfConnectedAccounts {
    if(numberOfConnectedAccounts > 1 && shouldShowStatus == YES) {
        shouldShowStatus = NO;
        [self.buddyListTableView reloadData];
    }
    else if (numberOfConnectedAccounts <= 1 && shouldShowStatus == NO)
    {
        shouldShowStatus = YES;
        [self.buddyListTableView reloadData];
    }
    [self refreshLeftBarItems];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self didUpdateNumberOfConnectedAccounts:[OTRProtocolManager sharedInstance].numberOfConnectedProtocols];
    
    [[OTRProtocolManager sharedInstance] addObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols)) options:NSKeyValueObservingOptionNew context:NULL];
    
    buddyListTableView.frame = self.view.bounds;
    buddyListTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    [buddyListTableView reloadData];
    [self refreshLeftBarItems];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols))];
    
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.buddyListTableView reloadData];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self didUpdateNumberOfConnectedAccounts:[[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue]];
}

- (void) showSettingsView:(id)sender {
    [self.navigationController pushViewController:[OTR_APP_DELEGATE settingsViewController] animated:YES];
}

-(void)refreshLeftBarItems
{
    [self subscriptionRequestsFetchedResultsController];
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
    
    addButton.enabled = [self shouldEnableAddButton];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"self.xmppAccount.isConnected == YES"];
    NSArray * allRequests = [OTRXMPPManagedPresenceSubscriptionRequest MR_findAll];
    allRequests = [allRequests filteredArrayUsingPredicate:predicate];
    
    if([allRequests count])
    {
        UIImage * buttonImage = [UIImage imageNamed:@"inbox"];
        UIBarButtonItem * requestButton = [[UIBarButtonItem alloc] initWithImage:buttonImage style:UIBarButtonItemStyleBordered target:self action:@selector(requestButtonPressed:)];
        
        self.navigationItem.leftBarButtonItems = @[addButton,requestButton];
    }
    else{
        self.navigationItem.leftBarButtonItems = @[addButton];
    }
        
}

- (BOOL)shouldEnableAddButton {
    return ([[OTRAccountsManager allAccountsAbleToAddBuddies] count] > 0);
}

-(void)requestButtonPressed:(id)sender
{
    OTRSubscriptionRequestsViewController * requestViewController = [[OTRSubscriptionRequestsViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:requestViewController];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(void) addButtonPressed:(id)sender {
    NSArray * allAccounts = [OTRAccountsManager allAccountsAbleToAddBuddies];
    NSUInteger numAccountsLoggedIn = [allAccounts count];
    if (numAccountsLoggedIn == 1) {
        //only one account logged in choose that account to add buddy to
        NSManagedObject * object = [allAccounts lastObject];
        OTRNewBuddyViewController * newBuddyViewController =  [[OTRNewBuddyViewController alloc] initWithAccountObjectID:[object objectID]];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newBuddyViewController];
        
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    else if (numAccountsLoggedIn > 1)
    {
        OTRChooseAccountViewController * chooseAccountViewController = [[OTRChooseAccountViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chooseAccountViewController];
        
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.buddyListTableView = nil;
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

-(void)setupBuddyFetchedResultsControllers
{
    groupManager = [[OTRBuddyListGroupManager alloc] initWithFetchedResultsDelegete:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.buddyListTableView]) {
        //+2 one for recent conversations the other for offline buddies
        NSUInteger num = [self.groupManager numberOfGroups]+2;
        return num;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 36.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return nil;
    }
    
    NSString * title = @"";
    if ([tableView isEqual:self.buddyListTableView]) {
        if (section == RECENTS_SECTION_INDEX) {
            title = RECENT_STRING;
        } else if ([self.groupManager numberOfGroups] >= section) {
            title = [self.groupManager groupNameAtIndex:section-1];
        }
        else
        {
            title = OFFLINE_STRING;
        }
    }
    
    OTRSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OTRSectionHeaderView reuseIdentifier]];

    OTRBuddyListSectionInfo *sectionInfo = [self.sectionInfoSet objectAtIndex:section];
    
    headerView.sectionInfo = sectionInfo;
    headerView.delegate = self;
    
    return headerView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    OTRBuddyListSectionInfo * sectionInfo = sectionInfo = [self.sectionInfoSet objectAtIndex:sectionIndex];
    if (![sectionInfo isOpen]) {
        return 0;
    }
    
    if ([tableView isEqual:self.buddyListTableView]) {
        if (sectionIndex == RECENTS_SECTION_INDEX) {
            return [[self.recentBuddiesFetchedResultsController fetchedObjects] count];
        } else if ([self.groupManager numberOfGroups] >= sectionIndex){
            NSUInteger num =  [self.groupManager numberOfBuddiesAtIndex:sectionIndex-1];
            return num;
        }
        else
        {
            return [[self.offlineBuddiesFetchedResultsController fetchedObjects] count];
        }
        return 0;
    }
    else if ([tableView isEqual:self.searchDisplayController.searchResultsTableView])
    {
        return [[self.searchBuddyFetchedResultsController sections][sectionIndex] numberOfObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const buddyCell = @"buddyCell";
    static NSString * const conversationCell = @"conversationCell";
    OTRBuddyCell * cell = nil;
    
    OTRManagedBuddy *buddy = [self tableView:tableView buddyforRowAtIndexPath:indexPath];
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView] || ([tableView isEqual:self.buddyListTableView] && indexPath.section != RECENTS_SECTION_INDEX)) {
        cell = [tableView dequeueReusableCellWithIdentifier:buddyCell];
        if (!cell)
        {
            cell = [[OTRBuddyCell alloc] initWithReuseIdentifier:buddyCell];
            if ([tableView isEqual:self.buddyListTableView]) {
                UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc]
                                                         initWithTarget:self action:@selector(longPressOnCell:)];
                [cell addGestureRecognizer:gesture];
            }
            
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:conversationCell];
        if (!cell)
        {
            cell = [[OTRRecentBuddyCell alloc] initWithReuseIdentifier:conversationCell];
            UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(longPressOnCell:)];
            [cell addGestureRecognizer:gesture];
        }
    }
    cell.showStatus = shouldShowStatus;
    cell.buddy = buddy;
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

- (OTRManagedBuddy *)tableView:(UITableView *)tableView buddyforRowAtIndexPath:(NSIndexPath *)indexPath {
    OTRManagedBuddy * managedBuddy = nil;
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        managedBuddy = [self.searchBuddyFetchedResultsController objectAtIndexPath:indexPath];
    }
    else if ([tableView isEqual:self.buddyListTableView])
    {
        if (indexPath.section == RECENTS_SECTION_INDEX)
        {
            managedBuddy = [self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath];
        }
        else if([self.groupManager numberOfGroups] >= indexPath.section){
            managedBuddy = [self.groupManager buddyAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1]];
        }
        else {
            managedBuddy = [self.offlineBuddiesFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
        }
    }

    return managedBuddy;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == RECENTS_SECTION_INDEX) {
        return UITableViewCellEditingStyleDelete;
    } else{
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    OTRManagedBuddy * managedBuddy = [self tableView:tableView buddyforRowAtIndexPath:indexPath];
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        [self.searchDisplayController   setActive:NO];
    }
    
    if (managedBuddy) {
        [self enterConversationWithBuddy:managedBuddy];
    }

    
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RECENTS_SECTION_INDEX && editingStyle == UITableViewCellEditingStyleDelete) {
        [[self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath] deleteAllMessages];
    }
}

-(void)enterConversationWithBuddy:(OTRManagedBuddy*)buddy
{
    if(!buddy) {
        return;
    }
    self.selectedBuddy = buddy;
    chatViewController.buddy = buddy;
    
    BOOL chatViewIsVisible = chatViewController.isViewLoaded && chatViewController.view.window;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && !chatViewIsVisible && self.navigationController.visibleViewController != chatViewController) {
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, chatViewController, nil] animated:YES];
    }
}

-(void)longPressOnCell:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateBegan)
        return;
    
    UITableViewCell *cell = (UITableViewCell *)gesture.view;
    
    NSIndexPath * indexPath = [buddyListTableView indexPathForCell:cell];
    
    OTRManagedBuddy * buddy = [self tableView:self.buddyListTableView buddyforRowAtIndexPath:indexPath];
    
    OTRBuddyViewController * buddyViewController = [[OTRBuddyViewController alloc] initWithBuddyID:buddy.objectID];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:buddyViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - NSFetchedReusltsControllerDelegate
    
-(NSFetchedResultsController *)buddyFetchedResultsController{
    if (_buddyFetchedResultsController)
    {
        return _buddyFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%K != nil OR %K != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
    NSString * sortString = [NSString stringWithFormat:@"%@,%@",OTRManagedBuddyAttributes.currentStatus,OTRManagedBuddyAttributes.displayName];
    _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:sortString ascending:YES delegate:self];
    
    return _buddyFetchedResultsController;
}

-(NSFetchedResultsController *)searchBuddyFetchedResultsController
{
    if (_searchBuddyFetchedResultsController)
    {
        return _searchBuddyFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%K != nil OR %K != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
    NSString * sortString = [NSString stringWithFormat:@"%@,%@",OTRManagedBuddyAttributes.currentStatus,OTRManagedBuddyAttributes.displayName];
    _searchBuddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:sortString ascending:YES delegate:self];
    
    return _searchBuddyFetchedResultsController;
    
}

-(NSFetchedResultsController *)recentBuddiesFetchedResultsController
{
    if(_recentBuddiesFetchedResultsController)
    {
        return _recentBuddiesFetchedResultsController;
    }
    /// Maybe instead do a fetch on OTRManagedChatMessage and group by buddy sections -> rows in table
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(%K, $message, $message.isEncrypted == NO).@count != 0)",OTRManagedBuddyRelationships.chatMessages];
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%K != nil OR %K != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
    NSPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,buddyFilter]];
     
    
    _recentBuddiesFetchedResultsController = [OTRManagedBuddy MR_fetchAllSortedBy:OTRManagedBuddyAttributes.lastMessageDate ascending:NO withPredicate:compoundPredicate groupBy:nil delegate:self];
 
    return _recentBuddiesFetchedResultsController;
}

-(NSFetchedResultsController *)unreadMessagesFetchedResultsContrller
{
    if(_unreadMessagesFetchedResultsContrller)
    {
        return _unreadMessagesFetchedResultsContrller;
    }
    
    NSPredicate * encryptionFilter = [NSPredicate predicateWithFormat:@"%K == NO",OTRManagedMessageAttributes.isEncrypted];
    NSPredicate * unreadFilter = [NSPredicate predicateWithFormat:@"%K == NO",OTRManagedChatMessageAttributes.isRead];
    NSPredicate * unreadMessagePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[encryptionFilter, unreadFilter]];
    
    _unreadMessagesFetchedResultsContrller = [OTRManagedChatMessage MR_fetchAllGroupedBy:nil withPredicate:unreadMessagePredicate sortedBy:nil ascending:YES delegate:self];
    
    return _unreadMessagesFetchedResultsContrller;
}

-(NSFetchedResultsController *) offlineBuddiesFetchedResultsController
{
    if(_offlineBuddiesFetchedResultsController)
    {
        return _offlineBuddiesFetchedResultsController;
    }
    
    NSPredicate * offlineBuddyFilter = [NSPredicate predicateWithFormat:@"%K == %d",OTRManagedBuddyAttributes.currentStatus,OTRBuddyStatusOffline];
    NSPredicate * selfBuddyFilter = [NSPredicate predicateWithFormat:@"%K != account.username",OTRManagedBuddyAttributes.accountName];
    NSPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[offlineBuddyFilter,selfBuddyFilter]];
    
    NSString * sortByString = [NSString stringWithFormat:@"%@,%@",OTRManagedBuddyAttributes.displayName,OTRManagedBuddyAttributes.accountName];
    
    _offlineBuddiesFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:compoundPredicate sortedBy:sortByString ascending:YES delegate:self];
    
    return _offlineBuddiesFetchedResultsController;
}

-(NSFetchedResultsController *)subscriptionRequestsFetchedResultsController
{
    if(_subscriptionRequestsFetchedResultsController)
    {
        return _subscriptionRequestsFetchedResultsController;
    }
    
    _subscriptionRequestsFetchedResultsController = [OTRXMPPManagedPresenceSubscriptionRequest MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:nil ascending:NO delegate:self];
    
    return _subscriptionRequestsFetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    UITableView * tableView = nil;
    
    if([controller isEqual:_searchBuddyFetchedResultsController])
    {
        tableView = self.searchDisplayController.searchResultsTableView;
    }
    else if ([self.groupManager isControllerOnline:controller] || [controller isEqual:_recentBuddiesFetchedResultsController] || [controller isEqual:_offlineBuddiesFetchedResultsController]) {
        tableView = self.buddyListTableView;
    }
    
    [tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([controller isEqual:_subscriptionRequestsFetchedResultsController]) {
        [self refreshLeftBarItems];
        return;
    }
    else if([controller isEqual:_unreadMessagesFetchedResultsContrller])
    {
        [self updateTitleWithUnreadCount:[[controller sections][indexPath.section] numberOfObjects]];
        return;
    }
    
    UITableView *tableView = nil;
    NSIndexPath * modifiedIndexPath = indexPath;
    NSIndexPath * modifiedNewIndexPath = newIndexPath;
    
    BOOL isRecentBuddiesFetchedResultsController = [controller isEqual:_recentBuddiesFetchedResultsController];
    
    if ([self.groupManager isControllerOnline:controller]) {
        tableView = self.buddyListTableView;
        
        
        modifiedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section+1];
        modifiedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1];
    }
    else if (isRecentBuddiesFetchedResultsController)
    {
        tableView = self.buddyListTableView;
    }
    else if([controller isEqual:_searchBuddyFetchedResultsController])
    {
        tableView = self.searchDisplayController.searchResultsTableView;
    }
    else if([controller isEqual:_offlineBuddiesFetchedResultsController])
    {
        tableView = self.buddyListTableView;
        NSInteger section = tableView.numberOfSections-1;
        modifiedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:section];
        modifiedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:section];
    }
    
    if (tableView) {
        OTRBuddyListSectionInfo * sectionInfo = [self.sectionInfoSet objectAtIndex:modifiedIndexPath.section];
        if (type == NSFetchedResultsChangeInsert) {
            sectionInfo = [self.sectionInfoSet objectAtIndex:modifiedNewIndexPath.section];
        }
        
        if ([tableView isEqual:self.buddyListTableView] && !sectionInfo.isOpen) {
            return;
        }
        
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[modifiedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[modifiedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:@[modifiedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView reloadRowsAtIndexPaths:@[modifiedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView moveRowAtIndexPath:modifiedIndexPath toIndexPath:modifiedNewIndexPath];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    UITableView * tableView = nil;
    
    if([controller isEqual:_searchBuddyFetchedResultsController])
    {
        tableView = self.searchDisplayController.searchResultsTableView;
    }
    else if ([self.groupManager isControllerOnline:controller] || [controller isEqual:_recentBuddiesFetchedResultsController] || [controller isEqual:_offlineBuddiesFetchedResultsController]) {
        tableView = self.buddyListTableView;
    }
    
    [tableView endUpdates];
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    self.searchBuddyFetchedResultsController.delegate = nil;
    self.searchBuddyFetchedResultsController = nil;
}
-(void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    self.searchBuddyFetchedResultsController.delegate = nil;
    self.searchBuddyFetchedResultsController = nil;
}

-(void)manager:(OTRBuddyListGroupManager *)manager didChangeSectionAtIndex:(NSUInteger)section newSectionIndex:(NSUInteger)newSection forChangeType:(NSFetchedResultsChangeType)type
{
    NSUInteger sectionModified = section+1;
    NSUInteger newSectionModified = newSection +1;
    //[self.buddyListTableView beginUpdates];
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            OTRBuddyListSectionInfo * secInfo = [[OTRBuddyListSectionInfo alloc] init];
            secInfo.isOpen = YES;
            secInfo.title = [manager groupNameAtIndex:newSection];
            if (newSectionModified >= [self.sectionInfoSet count]) {
                [self.sectionInfoSet addObject:secInfo];
            } else {
                [self.sectionInfoSet insertObject:secInfo atIndex:newSectionModified];
            }

            [self.buddyListTableView insertSections:[NSIndexSet indexSetWithIndex:newSectionModified] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeDelete:
        {
            [self.sectionInfoSet removeObjectAtIndex:sectionModified];
            [self.buddyListTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionModified] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
            
        default:
            break;
    }
    //[self.buddyListTableView endUpdates];
}

- (void) sectionHeaderViewChanged:(OTRSectionHeaderView *)sectionHeaderView
{
    OTRBuddyListSectionInfo *sectionInfo = sectionHeaderView.sectionInfo;
    NSUInteger section = [self.sectionInfoSet indexOfObject:sectionInfo];
    NSUInteger numRows = 0;
    if (section == RECENTS_SECTION_INDEX) {
        numRows = [[self.recentBuddiesFetchedResultsController fetchedObjects] count];
    }
    else if([self.groupManager numberOfGroups] >= section)
    {
        numRows = [self.groupManager numberOfBuddiesAtIndex:section-1];
    }
    else{
        numRows = [[self.offlineBuddiesFetchedResultsController fetchedObjects] count];
    }
    
    if (numRows == 0) {
        return;
    }
        
    NSMutableArray * rowsToChange = [NSMutableArray array];
    
    for (NSInteger i = 0; i < numRows; i++) {
        [rowsToChange addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    
    [self.buddyListTableView beginUpdates];
    if (sectionInfo.isOpen) {
        [self.buddyListTableView insertRowsAtIndexPaths:rowsToChange withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        [self.buddyListTableView deleteRowsAtIndexPaths:rowsToChange withRowAnimation:UITableViewRowAnimationTop];
    }
    [self.buddyListTableView endUpdates];
}

-(void)updateTitleWithUnreadCount:(NSInteger) unreadMessagesCount
{
    NSMutableString * title = [BUDDY_LIST_STRING mutableCopy];
    if (unreadMessagesCount > 0) {
        if (unreadMessagesCount < 100) {
            [title appendFormat:@" (%d)",unreadMessagesCount];
        }
        else{
            [title appendFormat:@" (99+)"];
        }
    }
    
    self.title = title;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    _searchBuddyFetchedResultsController.delegate = nil;
    _searchBuddyFetchedResultsController = nil;
    
    NSPredicate * buddyNameFilter = [NSPredicate predicateWithFormat:@"%K contains[cd] %@ OR %K contains[cd] %@",OTRManagedBuddyAttributes.accountName,searchText,OTRManagedBuddyAttributes.displayName ,searchText];
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%K != nil OR %K != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
    NSPredicate * selfBuddyFilter = [NSPredicate predicateWithFormat:@"%K != account.username",OTRManagedBuddyAttributes.accountName];
    NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyNameFilter,buddyFilter,selfBuddyFilter]];
    NSString * sortString = [NSString stringWithFormat:@"%@,%@",OTRManagedBuddyAttributes.currentStatus,OTRManagedBuddyAttributes.displayName];
    _searchBuddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:predicate sortedBy:sortString ascending:YES delegate:self];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if([searchString length])
    {
        [self filterContentForSearchText:searchString scope:nil];
        return YES;
    }
}
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    return YES;
}

-(void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    self.searchBuddyFetchedResultsController.delegate = nil;
    self.searchBuddyFetchedResultsController = nil;
}

@end
