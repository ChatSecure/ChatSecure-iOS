//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBroadcastListViewController.h"

#import "OTRBuddy.h"
//#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccountsManager.h"
#import "YapDatabaseFullTextSearchTransaction.h"
#import "Strings.h"
#import "OTRBroadcastInfoCell.h"

#import "OTRChooseAccountViewController.h"
#import "OTRConversationCell.h"
#import "OTRComposeViewController.h"

#import "OTRMessagesViewController.h"
#import "OTRMessagesGroupViewController.h"
#import "OTRBroadcastGroup.h"

#import "OTRAppDelegate.h"

static CGFloat cellHeight = 80.0;

@interface OTRBroadcastListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, OTRComposeViewControllerDelegate>


@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *broadcastmappings;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic) BOOL viewWithcanAddBuddy;
@property (nonatomic) BOOL viewWithListOfdifussion;
@property (nonatomic, strong) NSMutableArray *arSelectedRows;
@property (nonatomic, strong) UIBarButtonItem * createBarButtonItem;



@end

@implementation OTRBroadcastListViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /*
    UIBarButtonItem * editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = editBarButtonItem;
    */
    
    
    
    /////////// Navigation Bar ///////////
    
    self.title = LIST_OF_DIFUSSION_STRING;
    self.navigationItem.leftBarButtonItem = self.createBarButtonItem;
    
    
    /////////// Search Bar ///////////
    /*
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];*/
    
    /////////// TableView ///////////
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //[self.tableView setEditing:YES animated:YES];
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRBroadcastInfoCell class] forCellReuseIdentifier:[OTRBroadcastInfoCell reuseIdentifier]];
   
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    //////// YapDatabase Connection /////////
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    //self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRBuddyGroup] view:OTRContactDatabaseViewExtensionName];
    
    self.broadcastmappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllBroadcastGroupList] view:OTRAllBroadcastListDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        //[self.mappings updateWithTransaction:transaction];
        [self.broadcastmappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];

    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];*/
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)editButtonPressed:(id)sender
{
    //[self dismissViewControllerAnimated:YES completion:nil];
}



- (BOOL)canAddList
{
    if([OTRAccountsManager allAccountsAbleToAddBuddies]) {
        return YES;
    }
    return NO;
}


- (OTRBroadcastGroup *)broadcastGroupAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    __block OTRBroadcastGroup *broadcastGroup;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        broadcastGroup = [[transaction ext:OTRAllBroadcastListDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.broadcastmappings];
        
    }];
    
    if(broadcastGroup)
    {
        return broadcastGroup;
    }

    return nil;
}

- (void)enterConversationWithBuddies:(OTRBroadcastGroup *)broadcastGroup
{
    if(broadcastGroup)
    {
        OTRMessagesGroupViewController *messagesViewController = [OTRAppDelegate appDelegate].groupMessagesViewController;
        messagesViewController.hidesBottomBarWhenPushed = YES;
        messagesViewController.broadcastGroup = broadcastGroup;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self.navigationController pushViewController:messagesViewController animated:YES];
        }
        
    }
}


-(void)newConversationWithBuddies:(NSMutableArray *)buddies
{
    
    if([buddies count] > 1 )
    {
        OTRBroadcastGroup *broadcastGroup = [[OTRBroadcastGroup alloc] initWithBuddyArray:buddies];
        
        NSString *accountUniqueId = @"";
        for(OTRBuddy *buddy in broadcastGroup.buddies)
            accountUniqueId = buddy.accountUniqueId;
        
        
        broadcastGroup.accountUniqueId = accountUniqueId;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction){
            [broadcastGroup saveWithTransaction:transaction];
        }
         completionBlock:^{
             OTRMessagesGroupViewController *messagesViewController = [OTRAppDelegate appDelegate].groupMessagesViewController;
             messagesViewController.hidesBottomBarWhenPushed = YES;
             messagesViewController.broadcastGroup = broadcastGroup;
             
             if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                 [self.navigationController pushViewController:messagesViewController animated:YES];
             }
         }];
    }
    
}




/*
#pragma - mark keyBoardAnimation Methods
- (void)keyboardWillShow:(NSNotification *)notification
{
    [self animateTableViewWithKeyboardNotification:notification];
}
- (void)keyboardWillHide:(NSNotification *)notification
{
    [self animateTableViewWithKeyboardNotification:notification];
}

- (void)animateTableViewWithKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    //
    // Get keyboard size.
    NSValue *endFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardEndFrame = [self.view convertRect:endFrameValue.CGRectValue fromView:nil];
    
    //
    // Get keyboard animation.
    NSNumber *durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    CGFloat height = keyboardEndFrame.size.height;
    if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
        height = 0;
    }
    
    [self animateTableViewToKeyboardHeight:height animationCurve:animationCurve animationDuration:animationDuration];
}

- (void)animateTableViewToKeyboardHeight:(CGFloat)keyBoardHeight animationCurve:(UIViewAnimationCurve)animationCurve animationDuration:(NSTimeInterval)animationDuration
{
    self.tableViewBottomConstraint.constant = -keyBoardHeight;
    void (^animations)() = ^() {
        [self.view layoutIfNeeded];
    };
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16)
                     animations:animations
                     completion:nil];
    
}*/


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    BOOL canAddList = [self canAddList];
    
    NSInteger sections = 0;
    
    sections = [self.broadcastmappings numberOfSections];
    
    if (canAddList) {
        sections += 1;
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if ([self canAddList] && section == 0) {
        numberOfRows = 1;
    }
    else {
        numberOfRows = [self.broadcastmappings numberOfItemsInSection:0];
    }
   
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section == 0 && [self canAddList]) {
        // add new buddy cell
        static NSString *addCellIdentifier = @"addCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
        }
        cell.textLabel.text = NEW_BROADCAST_LIST_STRING;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
    else {
        
        OTRBroadcastInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBroadcastInfoCell reuseIdentifier] forIndexPath:indexPath];
        OTRBroadcastGroup * broadcastGroup = [self broadcastGroupAtIndexPath:indexPath];
        
        /*__block NSString *buddyAccountName = nil;
         [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
         buddyAccountName = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction].username;
         }];*/
        
        [cell setBroadcastGroup:broadcastGroup];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBroadcastGroup *cellGroup = [[self broadcastGroupAtIndexPath:indexPath] copy];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
         {
             [[[OTRBroadcastGroup fetchObjectWithUniqueID:cellGroup.uniqueId transaction:transaction] copy] removeWithTransaction:transaction] ;
             
         }
         completionBlock:^{
             
             [self.tableView reloadData];
           }];
    }
}


#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  cellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleNone;

    } else {
        return UITableViewCellEditingStyleDelete;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    //NSArray *accounts = [OTRAccountsManager allAccountsAbleToAddBuddies];
    if(indexPath.section == 0  && [self canAddList])
    {
        
        OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] initWithOptions:YES];
        composeViewController.delegate = self;
        UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
        //modalNavigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:modalNavigationController animated:YES completion:nil];
        
    }
    else
    {
        OTRBroadcastGroup *broadcastGroup = [self broadcastGroupAtIndexPath:indexPath];
        if(broadcastGroup)
        {
            [self enterConversationWithBuddies:broadcastGroup];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
    
}

#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRAllBroadcastListDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                           rowChanges:&rowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.broadcastmappings];
    
    /*
    NSArray *messageSectionChanges = nil;
    NSArray *messageRowChanges = nil;
    [[self.databaseConnection ext:OTRBroadcastChatDatabaseViewExtensionName] getSectionChanges:&messageSectionChanges
                                                                              rowChanges:&messageRowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.subscriptionRequestsMappings];
    */
    /*if ([subscriptionSectionChanges count] || [subscriptionRowChanges count]) {
        [self updateInbox];
    }*/
    
    
   
    
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
    
    BOOL canAddList = [self canAddList];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        NSUInteger sectionIndex = sectionChange.index;
        if (canAddList) {
            sectionIndex += 1;
        }
        
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
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
        NSIndexPath *indexPath = rowChange.indexPath;
        NSIndexPath *newIndexPath = rowChange.newIndexPath;
        if (canAddList) {
            indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:1];
            newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:1];
        }
        else{
            indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:0];
            newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:0];
        }
        
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}


#pragma - mark OTRComposeViewController Method

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddies:(NSMutableArray *)buddies
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self newConversationWithBuddies:buddies];
    }];
}


@end
