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
#import "OTRManagedStatus.h"
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
@synthesize sectionInfoArray;

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
    OTRBuddyListSectionInfo * offlineSectionInfo = [[OTRBuddyListSectionInfo alloc] init];
    recentSectionInfo.open = YES;
    offlineSectionInfo.open = NO;
    
    sectionInfoArray = [@[recentSectionInfo,offlineSectionInfo] mutableCopy];
    
    [self setupBuddyFetchedResultsControllers];
    
    self.buddyListTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    buddyListTableView.dataSource = self;
    buddyListTableView.delegate = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSettingsView:)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = @"settings";
    [self.view addSubview:buddyListTableView];
    
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
	NSLog(@"LibOrange (v: %@): -beginTest\n", @lib_orange_version_string);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    buddyListTableView.frame = self.view.bounds;
    buddyListTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    [buddyListTableView reloadData];
    [self refreshLeftBarItems];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.buddyListTableView reloadData];
    
}

- (void) showSettingsView:(id)sender {
    [self.navigationController pushViewController:[OTR_APP_DELEGATE settingsViewController] animated:YES];
}

-(void)refreshLeftBarItems
{
    [self subscriptionRequestsFetchedResultsController];
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
    addButton.enabled = NO;
    
    NSUInteger numAccountsLoggedIn = [OTRAccountsManager numberOfAccountsLoggedIn];
    
    if (numAccountsLoggedIn) {
        addButton.enabled = YES;
    }
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"self.xmppAccount.isConnected == YES"];
    NSArray * allRequests = [OTRXMPPManagedPresenceSubscriptionRequest MR_findAllWithPredicate:predicate];
    
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

-(void)requestButtonPressed:(id)sender
{
    OTRSubscriptionRequestsViewController * requestViewController = [[OTRSubscriptionRequestsViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:requestViewController];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentModalViewController:navController animated:YES];
}

-(void) addButtonPressed:(id)sender {
    NSUInteger numAccountsLoggedIn = [OTRAccountsManager numberOfAccountsLoggedIn];
    if (numAccountsLoggedIn == 1) {
        //only one account logged in choose that account to add buddy to
        NSManagedObject * object = [[OTRAccountsManager allLoggedInAccounts] lastObject];
        OTRNewBuddyViewController * newBuddyViewController =  [[OTRNewBuddyViewController alloc] initWithAccountObjectID:[object objectID]];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newBuddyViewController];
        
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.navigationController presentModalViewController:navController animated:YES];
    }
    else if (numAccountsLoggedIn > 1)
    {
        OTRChooseAccountViewController * chooseAccountViewController = [[OTRChooseAccountViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chooseAccountViewController];
        
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.navigationController presentModalViewController:navController animated:YES];
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

    OTRBuddyListSectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
    if (!sectionInfo.sectionHeaderView) {
        sectionInfo.sectionHeaderView = [[OTRSectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.bounds.size.width, HEADER_HEIGHT) title:title section:section delegate:self];
    }
    sectionInfo.sectionHeaderView.disclosureButton.selected = !sectionInfo.open;
    sectionInfo.sectionHeaderView.section = section;
    
    return sectionInfo.sectionHeaderView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    OTRBuddyListSectionInfo * sectionInfo = sectionInfo = [self.sectionInfoArray objectAtIndex:sectionIndex];
    if (![sectionInfo open]) {
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
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
    
    OTRManagedBuddy *buddy = nil;
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        buddy = [self.searchBuddyFetchedResultsController objectAtIndexPath:indexPath];
        [self configureBuddyCell:cell withBuddy:buddy];
    }
    else if (indexPath.section == RECENTS_SECTION_INDEX) {
        buddy = [self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath];
        [self configureRecentCell:cell withBuddy:buddy];
    } else{
        if ([self.groupManager numberOfGroups] >= indexPath.section) {
            buddy = [self.groupManager buddyAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section-1]];
        }
        else{
            NSFetchedResultsController* resultsController = self.offlineBuddiesFetchedResultsController;
            buddy = [resultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
            
        }
        [self configureBuddyCell:cell withBuddy:buddy];
    }
    return cell;
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
    OTRManagedBuddy * managedBuddy = nil;
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        managedBuddy = [self.searchBuddyFetchedResultsController objectAtIndexPath:indexPath];
        [self enterConversationWithBuddy:managedBuddy];
        [self.searchDisplayController   setActive:NO];
    }
    else if (indexPath.section == RECENTS_SECTION_INDEX)
    {
        managedBuddy = [self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath];
    }
    else{
        if ([self.groupManager numberOfGroups] >= indexPath.section) {
            managedBuddy = [self.groupManager buddyAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section-1]];
        }
        else{
            NSFetchedResultsController* resultsController = self.offlineBuddiesFetchedResultsController;
            //buddy = [resultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
        }
    }
    
    if (managedBuddy) {
        [self enterConversationWithBuddy:managedBuddy];
    }
    

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RECENTS_SECTION_INDEX && editingStyle == UITableViewCellEditingStyleDelete) {
        [[self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath] deleteAllMessages];
    }
}

- (void) deleteBuddy:(OTRManagedBuddy*)buddy {
    //TODO best way to delete buddy
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
    UITableView * tableView = (UITableView *)cell.superview;
    
    NSIndexPath * indexPath = [tableView indexPathForCell:cell];
    
    OTRManagedBuddy * buddy = [self buddyWithTableView:tableView atIndexPath:indexPath];
    
    OTRBuddyViewController * buddyViewController = [[OTRBuddyViewController alloc] initWithBuddyID:buddy.objectID];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:buddyViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navController animated:YES];
    
}

-(OTRManagedBuddy *)buddyWithTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    OTRManagedBuddy * managedBuddy = nil;
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        [self.searchDisplayController   setActive:NO];
        managedBuddy = [self.searchBuddyFetchedResultsController objectAtIndexPath:indexPath];
        [self enterConversationWithBuddy:managedBuddy];
    }
    
    if ([tableView isEqual:self.buddyListTableView]) {
        
        if (indexPath.section == RECENTS_SECTION_INDEX) {
            managedBuddy = [self.recentBuddiesFetchedResultsController objectAtIndexPath:indexPath];
            
        }
        else{
            if ([self.groupManager numberOfGroups] >= indexPath.section) {
                managedBuddy = [self.groupManager buddyAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section-1]];
            }
            else{
                NSFetchedResultsController* resultsController = self.offlineBuddiesFetchedResultsController;
                managedBuddy = [resultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
            }
        }
    }
    return managedBuddy;
}

#pragma mark - NSFetchedReusltsControllerDelegate
    
-(NSFetchedResultsController *)buddyFetchedResultsController{
    if (_buddyFetchedResultsController)
    {
        return _buddyFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    
    _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:@"currentStatus,displayName" ascending:YES delegate:self];
    
    return _buddyFetchedResultsController;
}

-(NSFetchedResultsController *)searchBuddyFetchedResultsController
{
    if (_searchBuddyFetchedResultsController)
    {
        return _searchBuddyFetchedResultsController;
    }
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    _searchBuddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:buddyFilter sortedBy:@"currentStatus,displayName" ascending:YES delegate:self];
    
    return _searchBuddyFetchedResultsController;
    
}

-(NSFetchedResultsController *)recentBuddiesFetchedResultsController
{
    if(_recentBuddiesFetchedResultsController)
    {
        return _recentBuddiesFetchedResultsController;
    }
    
     //predicate = [NSPredicate predicateWithFormat:@"messages.@count != 0"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(messages, $message, $message.isEncrypted == NO).@count != 0)"];
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    NSPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,buddyFilter]];
    
    _recentBuddiesFetchedResultsController = [OTRManagedBuddy MR_fetchAllSortedBy:@"lastMessageDate" ascending:NO withPredicate:compoundPredicate groupBy:nil delegate:self];
 
    return _recentBuddiesFetchedResultsController;
}

-(NSFetchedResultsController *)unreadMessagesFetchedResultsContrller
{
    if(_unreadMessagesFetchedResultsContrller)
    {
        return _unreadMessagesFetchedResultsContrller;
    }
    
    NSPredicate * encryptionFilter = [NSPredicate predicateWithFormat:@"self.isEncrypted == NO"];
    NSPredicate * unreadFilter = [NSPredicate predicateWithFormat:@"isRead == NO"];
    NSPredicate * unreadMessagePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[encryptionFilter, unreadFilter]];
    
    _unreadMessagesFetchedResultsContrller = [OTRManagedMessage MR_fetchAllGroupedBy:nil withPredicate:unreadMessagePredicate sortedBy:nil ascending:YES delegate:self];
    
    return _unreadMessagesFetchedResultsContrller;
}

-(NSFetchedResultsController *) offlineBuddiesFetchedResultsController
{
    if(_offlineBuddiesFetchedResultsController)
    {
        return _offlineBuddiesFetchedResultsController;
    }
    
    NSPredicate * offlineBuddyFilter = [NSPredicate predicateWithFormat:@"%K == %d",OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    NSPredicate * selfBuddyFilter = [NSPredicate predicateWithFormat:@"accountName != account.username"];
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
    
    NSPredicate * accountPredicate = [NSPredicate predicateWithFormat:@"self.xmppAccount.isConnected == YES"];
    
    
    _subscriptionRequestsFetchedResultsController = [OTRXMPPManagedPresenceSubscriptionRequest MR_fetchAllGroupedBy:nil withPredicate:accountPredicate sortedBy:nil ascending:NO delegate:self];
    
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
    OTRManagedBuddy * buddy = anObject;
    NSIndexPath * modifiedIndexPath = indexPath;
    NSIndexPath * modifiedNewIndexPath = newIndexPath;
    
    BOOL isRecentBuddiesFetchedResultsController = [controller isEqual:_recentBuddiesFetchedResultsController];
    
    if ([self.groupManager isControllerOnline:controller]) {
        tableView = self.buddyListTableView;
        
        
        modifiedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section+1];
        modifiedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1];
        //[tableView beginUpdates];
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
        OTRBuddyListSectionInfo * sectionInfo = [self.sectionInfoArray objectAtIndex:modifiedIndexPath.section];
        if ([tableView isEqual:self.buddyListTableView] && !sectionInfo.open ) {
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
                if ([controller isEqual:_recentBuddiesFetchedResultsController]) {
                    [self configureRecentCell:[tableView cellForRowAtIndexPath:modifiedIndexPath] withBuddy:buddy];
                }
                else{
                    [self configureBuddyCell:[tableView cellForRowAtIndexPath:modifiedIndexPath] withBuddy:buddy];
                }
                break;
                
            case NSFetchedResultsChangeMove:
                if ([controller isEqual:_recentBuddiesFetchedResultsController]) {
                    [self configureRecentCell:[tableView cellForRowAtIndexPath:modifiedIndexPath] withBuddy:buddy];
                }
                else{
                    [self configureBuddyCell:[tableView cellForRowAtIndexPath:modifiedIndexPath] withBuddy:buddy];
                }
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
            secInfo.open = YES;
            secInfo.sectionHeaderView.section = newSectionModified;
            if (newSectionModified >= [self.sectionInfoArray count]) {
                [self.sectionInfoArray addObject:secInfo];
            } else {
                [self.sectionInfoArray insertObject:secInfo atIndex:newSectionModified];
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
            [self.sectionInfoArray removeObjectAtIndex:sectionModified];
            [self.buddyListTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionModified] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
            
        default:
            break;
    }
    //[self.buddyListTableView endUpdates];
}

-(void)sectionHeaderView:(OTRSectionHeaderView *)sectionHeaderView section:(NSUInteger)section opened:(BOOL)opened
{
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
    
    
    OTRBuddyListSectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
	sectionInfo.open = opened;
    
    
    NSMutableArray * rowsToChange = [NSMutableArray array];
    
    for (NSInteger i = 0; i < numRows; i++) {
        [rowsToChange addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    
    [self.buddyListTableView beginUpdates];
    if (opened) {
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


-(void) configureRecentCell:(UITableViewCell *)cell withBuddy:(OTRManagedBuddy *) buddy
{
    [self configureCell:cell withBuddy:buddy];
    NSInteger numberOfUnreadMessages = [buddy numberOfUnreadMessages];
    
    
    NSDate * date = buddy.lastMessageDate;
    NSString *stringFromDate = nil;
    
    if([OTRUtilities dateInLast24Hours:date])
    {
        stringFromDate = [NSDateFormatter localizedStringFromDate:buddy.lastMessageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else if ([OTRUtilities dateInLast7Days:date])
    {
        //show day of week
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEEE"];
        stringFromDate = [formatter stringFromDate:date];
    }
    else{
        stringFromDate= [NSDateFormatter localizedStringFromDate:buddy.lastMessageDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
    
    cell.detailTextLabel.text = stringFromDate;
    
    if (numberOfUnreadMessages>0) {
        UILabel * messageCountLabel = nil;
        if (cell.accessoryView) {
            messageCountLabel = (UILabel *)cell.accessoryView;
        }
        else
        {
            messageCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 42.0, 28.0)];
            messageCountLabel.backgroundColor = [UIColor darkGrayColor];
            messageCountLabel.textColor = [UIColor whiteColor];
            messageCountLabel.layer.cornerRadius = 14;
            messageCountLabel.numberOfLines = 0;
            messageCountLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageCountLabel.textAlignment = UITextAlignmentCenter;
        }
        if (numberOfUnreadMessages > 99) {
            messageCountLabel.text = [NSString stringWithFormat:@"%d+",99];
        }
        else
        {
            messageCountLabel.text = [NSString stringWithFormat:@"%d",[buddy numberOfUnreadMessages]];
        }
        cell.accessoryView = messageCountLabel;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

-(void) configureCell:(UITableViewCell *)cell withBuddy:(OTRManagedBuddy *)buddy
{
    NSString *buddyUsername = buddy.displayName;
    if (![buddy.displayName length]) {
        buddyUsername = buddy.accountName;
    }
    
    OTRBuddyStatus buddyStatus = [buddy currentStatusMessage].statusValue;
    
    cell.textLabel.text = buddyUsername;
    cell.accessibilityLabel = buddyUsername;
    
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.text = [buddy currentStatusMessage].message;
    
    switch(buddyStatus)
    {
        case kOTRBuddyStatusOffline:
            cell.textLabel.textColor = [UIColor lightGrayColor];
            break;
        case kOTRBuddyStatusAway:
            cell.textLabel.textColor = [UIColor darkGrayColor];
            break;
        case kOTRBuddyStatusXa:
            cell.textLabel.textColor = [UIColor darkGrayColor];
            break;
        case kOTRBUddyStatusDnd:
            cell.textLabel.textColor = [UIColor darkGrayColor];
            break;
        case kOTRBuddyStatusAvailable:
            cell.textLabel.textColor = [UIColor darkTextColor];
            break;
        default:
            cell.textLabel.textColor = [UIColor lightGrayColor];
            break;
    }
    
    UIImage * image = [buddyStatusImageDictionary objectForKey:[NSNumber numberWithInteger:buddyStatus]];
    if (!image) {
        image = [OTRImages statusImageWithStatus:buddyStatus];
        [buddyStatusImageDictionary setObject:image forKey:[NSNumber numberWithInteger:buddyStatus]];
    }
    cell.imageView.image = image;
}

-(void)configureBuddyCell:(UITableViewCell *)cell withBuddy:(OTRManagedBuddy *)buddy
{
    [self configureCell:cell withBuddy:buddy];
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(longPressOnCell:)];
    [cell addGestureRecognizer:gesture];
}



- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    _searchBuddyFetchedResultsController.delegate = nil;
    _searchBuddyFetchedResultsController = nil;
    
    NSPredicate * buddyNameFilter = [NSPredicate predicateWithFormat:@"accountName contains[cd] %@ OR displayName contains[cd] %@",searchText ,searchText];
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    NSPredicate * selfBuddyFilter = [NSPredicate predicateWithFormat:@"accountName != account.username"];
    NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyNameFilter,buddyFilter,selfBuddyFilter]];
    _searchBuddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:predicate sortedBy:@"currentStatus,displayName" ascending:YES delegate:self];
    
    //[searchRequest setPredicate:buddyFilter];
    
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
