//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRComposeViewController.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccountsManager.h"
@import YapDatabase.YapDatabaseFullTextSearch;
@import YapDatabase.YapDatabaseView;
#import "OTRStrings.h"
#import "OTRBuddyInfoCell.h"
#import "OTRNewBuddyViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRLanguageManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@import OTRAssets;

static CGFloat OTRBuddyInfoCellHeight = 80.0;

@interface OTRComposeViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, OTRYapViewHandlerDelegateProtocol>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) OTRYapViewHandler *viewHandler;
@property (nonatomic, strong) NSArray *searchResults;

@property (nonatomic, strong) NSMutableSet <NSString *>*selectedBuddiesIdSet;

@end

@implementation OTRComposeViewController

- (instancetype)init {
    if (self = [super init]) {
        self.selectedBuddiesIdSet = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /////////// Navigation Bar ///////////
    self.title = COMPOSE_STRING;
    
    UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    
    UIImage *checkImage = [UIImage imageNamed:@"ic-check" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithImage:checkImage style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
    doneButtonItem.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    self.navigationItem.rightBarButtonItem = doneButtonItem;
    
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
    self.tableView.rowHeight = OTRBuddyInfoCellHeight;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRBuddyInfoCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    //////// YapDatabase Connection /////////
    self.viewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:[[OTRDatabaseManager sharedInstance] newConnection]];
    self.viewHandler.delegate = self;
    [self.viewHandler setup:OTRAllBuddiesDatabaseViewExtensionName groups:@[OTRBuddyGroup]];
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

- (void)doneButtonPressed:(id)sender
{
    void (^completion)(NSString *) = ^void(NSString *name) {
        if ([self.delegate respondsToSelector:@selector(controller:didSelectBuddies:accountId:name:)]) {
            //TODO: Naive choosing account just any buddy but should really check that account is connected or show picker
            __block NSString *accountId = nil;
            [self.viewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                NSString *buddyKey  = [self.selectedBuddiesIdSet anyObject];
                accountId = [OTRBuddy fetchObjectWithUniqueID:buddyKey transaction:transaction].accountUniqueId;
            }];
            [self.delegate controller:self didSelectBuddies:[self.selectedBuddiesIdSet allObjects] accountId:accountId name:name];
        }
    };
    
    if (self.selectedBuddiesIdSet.count > 1) {
        //Group so need user to select name
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Group Name" message:@"Enter a group name" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *name = alertController.textFields.firstObject.text;
            completion(name);
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Group name";
            
            [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:textField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                okAction.enabled = textField.text.length > 0;
            }];
        }];
        
        
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        completion(nil);
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
        return [self.viewHandler object:viewIndexPath];
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

- (void)selectedBuddy:(NSString *)buddyId{
    if (![buddyId length]) {
        return;
    }
    
    
    if ([self.selectedBuddiesIdSet containsObject:buddyId]) {
        [self.selectedBuddiesIdSet removeObject:buddyId];
    } else {
        [self.selectedBuddiesIdSet addObject:buddyId];
    }
    
    //Check legth of selected buddies and if none then disable button
    if ([self.selectedBuddiesIdSet count]) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
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
        [self.viewHandler.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
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
        sections = [self.viewHandler.mappings numberOfSections];
    }
    
    if (canAddBuddies) {
        sections += 1;
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (section == 0 && [self canAddBuddies]) {
        numberOfRows = 1;
    }
    else {
        if ([self useSearchResults]) {
            numberOfRows = [self.searchResults count];
        }
        else {
            numberOfRows = [self.viewHandler.mappings numberOfItemsInSection:0];
        }
    }
   
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    else {
        OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
        OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
        
        __block NSString *buddyAccountName = nil;
        [self.viewHandler.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddyAccountName = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction].username;
        }];
        
        [cell setThread:buddy withAccountName:buddyAccountName];
        
        [cell.avatarImageView.layer setCornerRadius:(OTRBuddyInfoCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
        if ([self.selectedBuddiesIdSet containsObject:buddy.uniqueId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
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
    if(indexPath.section == 0 && [self canAddBuddies]) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *accounts = [OTRAccountsManager allAccountsAbleToAddBuddies];
    if(indexPath.section == 0 && [accounts count])
    {
        [self addBuddy:accounts];
    }
    else {
        OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
        [self selectedBuddy:buddy.uniqueId];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeBuddy:[self buddyAtIndexPath:indexPath]];
    }
}

- (void)removeBuddy:(OTRBuddy *)buddy {
    __block NSString *key = buddy.uniqueId;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRBuddy *dbBuddy = [OTRBuddy fetchObjectWithUniqueID:key transaction:transaction];
        if (dbBuddy) {
            BuddyAction *action = [[BuddyAction alloc] init];
            action.buddy = dbBuddy;
            action.action = BuddyActionTypeDelete;
            [action saveWithTransaction:transaction];
            [dbBuddy removeWithTransaction:transaction];
        }
    }];
}

- (void)addBuddy:(NSArray * _Nullable)accountsAbleToAddBuddies
{
    //add buddy cell
    UIViewController *viewController = nil;
    if([accountsAbleToAddBuddies count] > 1) {
        // pick which account
        viewController = [[OTRChooseAccountViewController alloc] init];
    }
    else {
        OTRAccount *account = [accountsAbleToAddBuddies firstObject];
        viewController = [[OTRNewBuddyViewController alloc] initWithAccountId:account.uniqueId];
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma - mark YapDatabaseViewUpdate

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if ([sectionChanges count] == 0 && [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    [self.tableView beginUpdates];
    
    BOOL canAddBuddies = [self canAddBuddies];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        NSUInteger sectionIndex = sectionChange.index;
        if (canAddBuddies) {
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
            indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:1];
            newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:1];
        }
        else {
            
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
