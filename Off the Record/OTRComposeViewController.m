//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRComposeViewController.h"

#import "OTRManagedBuddy.h"
#import "OTRLog.h"

#import "OTRBuddyInfoCell.h"

static CGFloat cellHeight = 60.0;

@interface OTRComposeViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *buddySearchFetchedResultsController;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;

@end

@implementation OTRComposeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /////////// Navigation Bar ///////////
    self.title = @"Compose";
    UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    
    /////////// Search Bar ///////////
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    [self.view addSubview:self.searchBar];
    
    /////////// TableView ///////////
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRBuddyInfoCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
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

- (NSFetchedResultsController *)buddySearchFetchedResultsController
{
    if (!_buddySearchFetchedResultsController) {
        _buddySearchFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:[NSString stringWithFormat:@"%@,%@,%@",OTRManagedBuddyAttributes.currentStatus,OTRManagedBuddyAttributes.displayName,OTRManagedBuddyAttributes.accountName] ascending:YES delegate:self];
    }
    return _buddySearchFetchedResultsController;
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
    NSPredicate * predicate = nil;
    if (searchText.length) {
        predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@ OR %K contains[cd] %@",OTRManagedBuddyAttributes.accountName, searchText,OTRManagedBuddyAttributes.displayName,searchText];
    }
    
    self.buddySearchFetchedResultsController.fetchRequest.predicate = predicate;
    NSError *error = nil;
    [self.buddySearchFetchedResultsController performFetch:&error];
    if (error) {
        DDLogError(@"Fetch Error: %@",error);
    }
    [self.tableView reloadData];
}

#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.buddySearchFetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.buddySearchFetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
    OTRManagedBuddy * buddy = [self.buddySearchFetchedResultsController objectAtIndexPath:indexPath];
    
    [cell setBuddy:buddy];
    
    [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*margin)/2.0];
    
    return cell;
}

#pragma - mark UITableViewDelegate Methods

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
    if ([self.delegate respondsToSelector:@selector(controller:didSelectBuddy:)]) {
        [self.delegate controller:self didSelectBuddy:[self.buddySearchFetchedResultsController objectAtIndexPath:indexPath]];
    }
}

#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}


#pragma - mark NSFetchedResultsDelegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


@end
