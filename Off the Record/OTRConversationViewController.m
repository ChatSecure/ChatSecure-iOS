//
//  OTRConversationViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationViewController.h"

#import "OTRSettingsViewController.h"
#import "OTRChatViewController.h"
#import "OTRComposeViewController.h"

#import "OTRConversationCell.h"

#import "OTRManagedAccount.h"
#import "OTRManagedBuddy.h"

#import "OTRLog.h"

static CGFloat cellHeight = 80.0;

@interface OTRConversationViewController () <NSFetchedResultsControllerDelegate, OTRComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *buddyFetchedResultsController;
@property (nonatomic, strong) OTRChatViewController *chatViewController;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;

@end

@implementation OTRConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    ///////////// Setup Navigation Bar //////////////
    
    self.title = @"Chats";
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(settingsButtonPressed:)];
    self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
    
    UIBarButtonItem *composeBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonPressed:)];
    self.navigationItem.leftBarButtonItem = composeBarButtonItem;
    
    ////////// Create TableView /////////////////
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRConversationCell class] forCellReuseIdentifier:[OTRConversationCell reuseIdentifier]];
    
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.cellUpdateTimer invalidate];
    [self updateVisibleCells:self];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateVisibleCells:) userInfo:nil repeats:YES];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
}

- (void)settingsButtonPressed:(id)sender
{
    OTRSettingsViewController * settingsViewController = [[OTRSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)composeButtonPressed:(id)sender
{
    OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] init];
    composeViewController.delegate = self;
    UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
    //modalNavigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:modalNavigationController animated:YES completion:nil];
}

- (void)enterConversationWithBuddy:(OTRManagedBuddy *)buddy
{
    [self.chatViewController setBuddy:buddy];
    [self.navigationController pushViewController:self.chatViewController animated:YES];
}

- (void)updateVisibleCells:(id)sender
{
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in indexPathsArray)
    {
        OTRManagedBuddy * buddy = [self.buddyFetchedResultsController objectAtIndexPath:indexPath];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[OTRConversationCell class]]) {
            [(OTRConversationCell *)cell setBuddy:buddy];
        }
    }
}

- (NSFetchedResultsController *)buddyFetchedResultsController
{
    if (!_buddyFetchedResultsController) {
        NSPredicate *buddyFilter = [NSPredicate predicateWithFormat:@"%@ != nil OR %@ != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
        
        NSPredicate *hasMessagesPredicate = [NSPredicate predicateWithFormat:@"%K.@count > 0",OTRManagedBuddyRelationships.chatMessages];
        
        NSPredicate *selfBuddyFilter = [NSPredicate predicateWithFormat:@"%K != account.username",OTRManagedBuddyAttributes.accountName];
        
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,selfBuddyFilter,hasMessagesPredicate]];
        
        _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:predicate sortedBy:OTRManagedBuddyAttributes.lastMessageDate ascending:YES delegate:self];
        
    }
    return _buddyFetchedResultsController;
}

- (OTRChatViewController *)chatViewController
{
    if (!_chatViewController) {
        _chatViewController = [[OTRChatViewController alloc] init];
    }
    return _chatViewController;
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.buddyFetchedResultsController sections][section] numberOfObjects];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRManagedBuddy *cellBuddy = [self.buddyFetchedResultsController objectAtIndexPath:indexPath];
        NSPredicate *messagePredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedMessageRelationships.buddy,cellBuddy];
        NSPredicate *chatMessagePredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRManagedChatMessageRelationships.chatBuddy,cellBuddy];
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        [OTRManagedMessage MR_deleteAllMatchingPredicate:messagePredicate inContext:context];
        [OTRManagedChatMessage MR_deleteAllMatchingPredicate:chatMessagePredicate inContext:context];
        [context MR_saveToPersistentStoreAndWait];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
    OTRManagedBuddy * buddy = [self.buddyFetchedResultsController objectAtIndexPath:indexPath];
    
    [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
    
    [cell setBuddy:buddy];
    NSLog(@"Index Path: %d",indexPath.row);
    
    return cell;
}

#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  cellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTRManagedBuddy *buddy = [self.buddyFetchedResultsController objectAtIndexPath:indexPath];
    [self enterConversationWithBuddy:buddy];
}

#pragma - mark NSFetchedResultsControllerDelegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if ([controller isEqual: _buddyFetchedResultsController]) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView * tableView = nil;
    if ([controller isEqual:_buddyFetchedResultsController]) {
        tableView = self.tableView;
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
            case NSFetchedResultsChangeMove:
                [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
                break;
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
            default:
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([controller isEqual:_buddyFetchedResultsController]) {
        [self.tableView endUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

#pragma - mark OTRComposeViewController Method

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddy:(OTRManagedBuddy *)buddy
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self enterConversationWithBuddy:buddy];
    }];
}



@end
