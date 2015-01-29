//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRComposeViewController.h"

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
#import "OTRBuddyInfoCell.h"
#import "OTRBuddyListCell.h"
#import "OTRNewBuddyViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRConversationCell.h"
#import "OTRBroadcastListViewController.h"


#import "OTRMessagesViewController.h"
#import "OTRAppDelegate.h"

static CGFloat OTRBuddyInfoCellHeight = 80.0;


@interface OTRComposeViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>


@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic) BOOL viewWithcanAddBuddy;
@property (nonatomic) BOOL viewWithListOfdifussion;
@property (nonatomic, strong) NSMutableArray *arSelectedRows;
@property (nonatomic, strong) UIBarButtonItem * createBarButtonItem;



@end

@implementation OTRComposeViewController


- (id) initWithOptions:(BOOL)listOfDifussion{
    if (self = [super init]) {
        self.viewWithListOfdifussion = listOfDifussion;
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    self.createBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(createButtonPressed:)];
    self.createBarButtonItem.enabled = NO;
    
    
    /////////// Navigation Bar ///////////
    if(!self.viewWithListOfdifussion)
    {
        self.title = COMPOSE_STRING;
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    }
    else{
        self.title = LIST_OF_DIFUSSION_STRING;
        self.navigationItem.leftBarButtonItem = self.createBarButtonItem;
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    }
    
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
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllBuddiesGroupList] view:OTRAllBuddiesDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseDidUpdate:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    self.arSelectedRows = [[NSMutableArray alloc] init];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(controller:didSelectBuddies:)])
    {
        NSMutableArray *buddies = [[NSMutableArray alloc]init];
        for(NSIndexPath *indexPath in self.arSelectedRows) {
            OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
            [buddies addObject:buddy];
        }
        [self.delegate controller:self didSelectBuddies:buddies];
    }

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
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddy *buddy;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction ext:OTRAllBuddiesDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.mappings];
            
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
            }];
        } completionBlock:^{
            self.searchResults = tempSearchResults;
            [self.tableView reloadData];
        }];
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
    }
    
    if (canAddBuddies && self.viewWithcanAddBuddy) {
        sections += 2;
    }
    else if(!canAddBuddies && self.viewWithcanAddBuddy)
    {
        sections +=1;
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (self.viewWithcanAddBuddy) {
        if(section == 0)
        {
            numberOfRows = 1;
        }
        else if(section == 1 && [self canAddBuddies])
        {
            numberOfRows = 1;
        }
        else if(section >= 1)
        {
            if ([self useSearchResults]) {
                numberOfRows = [self.searchResults count];
            }
            else {
                numberOfRows = [self.mappings numberOfItemsInSection:0];
            }
        }
    }
    else {
        if ([self useSearchResults]) {
            numberOfRows = [self.searchResults count];
        }
        else {
            numberOfRows = [self.mappings numberOfItemsInSection:0];
        }
    }
   
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(self.viewWithListOfdifussion)
    {
        OTRBuddyListCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyListCell reuseIdentifier] forIndexPath:indexPath];
        OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
        
        /*__block NSString *buddyAccountName = nil;
         [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
         buddyAccountName = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction].username;
         }];*/
        
        //[cell setBuddy:buddy withAccountName:buddyAccountName];
        [cell setBuddy:buddy];
        
        [cell.avatarImageView.layer setCornerRadius:(OTRBuddyInfoCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
        if([self.arSelectedRows containsObject:indexPath])
        {
            [cell.button checkAnimated:NO];
        }
    
        
        return cell;

    }
    else{
        OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
        OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
        
        /*__block NSString *buddyAccountName = nil;
         [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
         buddyAccountName = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction].username;
         }];*/
        
        [cell setBuddy:buddy];
        
        [cell.avatarImageView.layer setCornerRadius:(OTRBuddyInfoCellHeight -2.0*OTRBuddyImageCellPadding)/2.0];
        
        return cell;

    }
    
}

#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return OTRBuddyInfoCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return OTRBuddyInfoCellHeight;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(!self.viewWithListOfdifussion)
    {
    
        if ([self.delegate respondsToSelector:@selector(controller:didSelectBuddy:)]) {
            OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
            [self.delegate controller:self didSelectBuddy:buddy];
        }
        else{
            
        }
    }
    else{
        OTRBuddyListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if(cell.button.isChecked)
        {
            [cell.button uncheckAnimated:YES];
            [self.arSelectedRows removeObject:indexPath];

        }
        else{
            [cell.button checkAnimated:YES];
            [self.arSelectedRows addObject:indexPath];
        }
        
        if([self.arSelectedRows count] > 1)
        {
            self.createBarButtonItem.enabled = YES;
        }
        else{
            self.createBarButtonItem.enabled = NO;
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
     NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
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
            case YapDatabaseViewChangeMove :
            case YapDatabaseViewChangeUpdate :
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
