//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRContactsViewController.h"

#import "OTRBuddy.h"
#import "OTRGroup.h"
#import "OTRBuddyGroup.h"
//#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "OTRAccountsManager.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccountsManager.h"
#import "YapDatabaseFullTextSearchTransaction.h"
#import "Strings.h"
#import "OTRBuddyInfoCell.h"
#import "OTRBuddyListCell.h"
#import "OTRNewBuddyViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRConversationCell.h"
#import "OTRBroadcastListViewController.h"
#import "DTCustomColoredAccessory.h"



#import "OTRMessagesViewController.h"
#import "OTRAppDelegate.h"

static CGFloat cellHeight = 80.0;

@interface OTRContactsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>


@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *contactmappings;
@property (nonatomic, strong) YapDatabaseViewMappings *contactByGroupmappings;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) OTRAccount *account;


@property (nonatomic, strong) NSMutableArray *arSelectedRows;
@property (nonatomic, strong) UIBarButtonItem * createBarButtonItem;
@property int currentExpandedIndex;
@property (nonatomic, strong) NSMutableIndexSet *expandedSections;



@end

@implementation OTRContactsViewController


- (id) init {
    if (self = [super init]) {
    
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        
        /////////// TabBar icon /////////////
        UITabBarItem *tab2 = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:2];
        tab2.title = CONTACTS_STRING;
        [self setTabBarItem:tab2];
        
        self.currentExpandedIndex = -1;

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.account = [[OTRAccountsManager allAutoLoginAccounts] objectAtIndex:0];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    self.createBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(createButtonPressed:)];
    self.createBarButtonItem.enabled = NO;
    
    
    /////////// Navigation Bar ///////////
    self.title = CONTACTS_STRING;
    
    
    /////////// Search Bar ///////////
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];
    
    /////////// TableView ///////////
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRBuddyInfoCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];
    [self.tableView registerClass:[OTRBuddyListCell class] forCellReuseIdentifier:[OTRBuddyListCell reuseIdentifier]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    //////// YapDatabase Connection /////////
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    
    self.contactmappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllGroupsGroup] view:OTRGroupDatabaseViewExtensionName];
    
     self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:OTRContactByGroupList view:OTRContactByGroupDatabaseViewExtensionName];
    
    self.contactByGroupmappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRBuddyGroupList] view:OTRContactDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.contactmappings updateWithTransaction:transaction];
        [self.contactByGroupmappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseDidUpdate:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    self.arSelectedRows = [[NSMutableArray alloc] init];
    self.expandedSections = [[NSMutableIndexSet alloc] init];
}


- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Expanding

-(BOOL)tableView:(UITableView *)tableView canCollapseSection:(NSInteger)section
{
    int sec;
    if ([self canAddBuddies]) {
        sec = 2;
    }else{
        sec = 1;
    }
    
    if((section >= sec)  && (section < (sec + [self.mappings numberOfSections]))) return YES;
    
    return NO;
}


- (void)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)canAddBuddies
{
    if([OTRAccountsManager allAccountsAbleToAddBuddies]) {
        return YES;
    }
    return NO;
}

- (OTRBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection: indexPath.section- [self.mappings numberOfSections]];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddyGroup *buddyGroup;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddyGroup = [[transaction ext:OTRContactByGroupDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.mappings];
            
        }];
        
        
        __block OTRBuddy *buddy = nil;
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup.buddyUniqueId transaction:transaction] copy];
        }];
        
        return buddy;
    }
    
    
    return nil;
}

- (OTRBuddy *)buddySolitareAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection: indexPath.section- [self.mappings numberOfSections]];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddy *buddy;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction ext:OTRContactDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.contactByGroupmappings];
            
        }];
        
        return buddy;
    }
    
    
    return nil;
}


- (OTRGroup *)groupAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section-2];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRGroup *group;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            group = [OTRGroup fetchGroupWithGroupName:[[self.mappings groupForSection:viewIndexPath.section] substringFromIndex:3] withAccountUniqueId:self.account.uniqueId transaction:transaction];
            
        }];
        
        return group;
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


- (void)enterConversationWithBuddy:(OTRBuddy *)buddy
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    
    OTRMessagesViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesViewController;
    messagesViewController.hidesBottomBarWhenPushed = YES;
    messagesViewController.buddy = buddy;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    }
    
}



- (void)enterGroupChatWithGroup:(OTRGroup *)group
{
    
    /*OTRMessagesViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesViewController;
    messagesViewController.hidesBottomBarWhenPushed = YES;
    messagesViewController.buddy = buddy;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    }*/
    
}



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
    
}

#pragma - mark UISearchBarDelegateMethods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length]) {
        
        searchText = [NSString stringWithFormat:@"%@*",searchText];
        
        NSMutableArray *tempSearchResults = [NSMutableArray new];
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:OTRBuddyNameSearchDatabaseViewExtensionName] enumerateKeysAndObjectsMatching:searchText usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
                if ([object isKindOfClass:[OTRBuddy class]]) {
                    [tempSearchResults addObject:object];
                }
                
                if ([object isKindOfClass:[OTRGroup class]]) {
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

#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    BOOL canAddBuddies = [self canAddBuddies];
    
    NSInteger sections = 0;
    if ([self useSearchResults]) {
        sections = 1;
    }
    else {
        sections = [self.mappings numberOfSections];
        if([self.contactByGroupmappings numberOfSections])
        {
            sections += 1;
        }
        
        if (canAddBuddies) {
            sections += 2;
        }
        
    }
    
    
    
    
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if ([self useSearchResults]) {
        numberOfRows = [self.searchResults count];
    }
    else{

        if([self tableView:tableView canCollapseSection:section])
        {
            int sec;
            if ([self canAddBuddies]) {
                sec = 2;
            }else{
                sec = 1;
            }
            
            if(section >= sec && section < (sec + [self.mappings numberOfSections]))
            {
                /*if ([self useSearchResults]) {
                 numberOfRows = [self.searchResults count];
                 }
                 else {*/
                if([self.expandedSections containsIndex:section])
                {
                    numberOfRows = [self.mappings numberOfItemsInSection:(section - sec)];
                }
                else
                {
                    numberOfRows = 1;
                }
                
            }
            
        }
        else{
            
            if([self canAddBuddies] && section == 0)
            {
                numberOfRows = 1;
            }
            else if(([self canAddBuddies] && section == 1) || (![self canAddBuddies] && section == 0))
            {
                numberOfRows = 1;
            }
            else
            {
                numberOfRows = [self.contactByGroupmappings numberOfItemsInSection:0];
            }
            
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];

    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
                
                OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
                
                [cell setBuddy:buddy];
                
                [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                return cell;
                
            }
            else if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRGroup class]])
            {
                static NSString *addCellIdentifier = @"addCellIdentifier";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
                }
                
                OTRGroup * group = [self groupAtIndexPath:indexPath];
                cell.textLabel.text =group.displayName;
                return cell;
            }
            
            return nil;
        }
        
        return nil;
        
    }
    else{
        if(indexPath.section == 0 && [self canAddBuddies]) {
            // add new buddy cell
            static NSString *addCellIdentifier = @"addCellIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
            }
            cell.textLabel.text = ADD_BUDDY_STRING;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        else if((indexPath.section == 0 && ![self canAddBuddies]) || (indexPath.section == 1 && [self canAddBuddies])) {
            // add new buddy cell
            static NSString *addCellIdentifier = @"addCellIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
            }
            cell.textLabel.text = LIST_OF_DIFUSSION_STRING;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        else if((indexPath.section == 1 && ![self canAddBuddies]) || (indexPath.section == 2 && [self canAddBuddies]) || (indexPath.section < (1 +[self.mappings numberOfSections]) && ![self canAddBuddies]) || (indexPath.section < (2 +[self.mappings numberOfSections]) && [self canAddBuddies]))
        {
            //OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
            
            if([self tableView:tableView canCollapseSection:indexPath.section])
            {
                if(!indexPath.row){
                    
                    static NSString *addCellIdentifier = @"addCellIdentifier";
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
                    if (!cell) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
                    }
                    
                    OTRGroup * group = [self groupAtIndexPath:indexPath];
                    cell.textLabel.text =group.displayName;
                    
                    
                    
                    if([self.expandedSections containsIndex:indexPath.section])
                    {
                        DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
                        [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                        cell.accessoryView = h;
                    }
                    else{
                        DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
                        [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                        cell.accessoryView = h;
                    }
                
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    return cell;
                }
                else{
                    
                    OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
                    
                    OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
                    
                    [cell setBuddy:buddy];
                    
                    [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                   
                    return cell;
                }
            }
            return nil;
        }
        else {
            
            OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
             
             OTRBuddy * buddy = [self buddySolitareAtIndexPath:indexPath];
            [cell setBuddy:buddy];
             
             [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
             
             return cell;
            
        }
    }
    
}


#pragma mark - private

-(void)didSelectAccessory:(UIControl *)button withEvent:(UIEvent *)event
{
    UITableViewCell *cell = (UITableViewCell*)button.superview;
    UITableView *tableView = (UITableView*)cell.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}



#pragma - mark UITableViewDelegate Methods

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if([self tableView:tableView canCollapseSection:indexPath.section])
    {
        if(!indexPath.row)
        {
            
            NSInteger section = indexPath.section;
            
            BOOL currentlyExpanded = [self.expandedSections containsIndex:section];
            NSInteger rows;
            
            NSMutableArray *tmpArray = [NSMutableArray array];
            
            if(currentlyExpanded)
            {
                rows = [self tableView:tableView numberOfRowsInSection:section];
                [self.expandedSections removeIndex:section];
            }
            else{
                [self.expandedSections addIndex:section];
                rows = [self tableView:tableView numberOfRowsInSection:section];
            }
            
            
            for (int i = 1; i < rows; i++)
            {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:section];
                
                [tmpArray addObject:tmpIndexPath];
            }
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if(currentlyExpanded)
            {
                [tableView deleteRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
                [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = h;
            }
            else{
                [tableView insertRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
                [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView =  h;
            }
        }
    }

}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  cellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSIndexPath *viewIndexPath =  [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        
        if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
            [self enterConversationWithBuddy:buddy];
        }
        else if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRGroup class]])
        {
            OTRGroup *group = [self groupAtIndexPath:indexPath];
            [self enterGroupChatWithGroup:group];
        }
        
    }
    else{
        NSArray *accounts = [OTRAccountsManager allAccountsAbleToAddBuddies];
        if(indexPath.section == 0)
        {
            
            //add buddy cell
            UIViewController *viewController = nil;
            OTRAccount *account = [accounts firstObject];
            
            viewController = [[OTRNewBuddyViewController alloc] initWithAccountId:account.uniqueId];
            
            [self.navigationController pushViewController:viewController animated:YES];
            
        }
        else if((indexPath.section == 0 && ![self canAddBuddies]) || (indexPath.section == 1 && [self canAddBuddies]))
        {
            
            OTRBroadcastListViewController *broadcastViewController = [[OTRBroadcastListViewController alloc] init];
            
            [self.navigationController pushViewController:broadcastViewController animated:YES];
            /*OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] initWithOptions:NO difussionList:YES];
             //composeViewController.delegate = self;
             UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
             //modalNavigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
             
             [self presentViewController:modalNavigationController animated:YES completion:nil];*/
        }
        else if((indexPath.section == 1 && ![self canAddBuddies]) || (indexPath.section == 2 && [self canAddBuddies]) || (indexPath.section < (1 +[self.mappings numberOfSections]) && ![self canAddBuddies]) || (indexPath.section < (2 +[self.mappings numberOfSections]) && [self canAddBuddies]))
        {
            if([self tableView:tableView canCollapseSection:indexPath.section])
            {
                if(!indexPath.row)
                {
                }
                else
                {
                    OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
                    [self enterConversationWithBuddy:buddy];
                    
                }
            }
            
            
            
        }
        else
        {
            OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
            [self enterConversationWithBuddy:buddy];
        }

    }
    
}




#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}


#pragma - mark YapDatabaseViewUpdate

- (void)yapDatabaseDidUpdate:(NSNotification *)notification;
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = notification.userInfo[@"notifications"];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    if ([self useSearchResults]) {
        return;
    }
    
    [[self.databaseConnection ext:OTRContactDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                                 rowChanges:&rowChanges
                                                                           forNotifications:notifications
                                                                               withMappings:self.mappings];
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.tableView beginUpdates];
    
    BOOL canAddBuddies = [self canAddBuddies];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        NSUInteger sectionIndex = sectionChange.index;
        if (canAddBuddies) {
            sectionIndex += 2;
        }
        else
        {
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
            case YapDatabaseViewChangeMove :
            case YapDatabaseViewChangeUpdate :
                break;
        }
    }
    
    
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        NSIndexPath *indexPath = rowChange.indexPath;
        NSIndexPath *newIndexPath = rowChange.newIndexPath;
        if (canAddBuddies) {
            indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:2];
            newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:2];
        }
        else
        {
            indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:1];
            newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:1];
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
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
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


@end
