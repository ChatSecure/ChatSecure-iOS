//
//  OTRSubscriptionRequestsViewController.m
//  Off the Record
//
//  Created by David on 3/5/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSubscriptionRequestsViewController.h"
#import "OTRXMPPManagedPresenceSubscriptionRequest.h"
#import "OTRManagedXMPPAccount.h"
#import "Strings.h"
#import "OTRXMPPManager.h"
#import "OTRProtocolManager.h"

@interface OTRSubscriptionRequestsViewController ()

@end

@implementation OTRSubscriptionRequestsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = SUBSCRIPTION_REQUEST_TITLE;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
}

-(void)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self subscriptionRequests] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    OTRXMPPManagedPresenceSubscriptionRequest * subRequest = [[self subscriptionRequests] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = subRequest.jid;
    cell.detailTextLabel.text = subRequest.xmppAccount.username;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentlySelectedRequest = [[self subscriptionRequests] objectAtIndex:indexPath.row];
    UIActionSheet * requestActionSheet = [[UIActionSheet alloc] initWithTitle:currentlySelectedRequest.jid delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:REJECT_STRING otherButtonTitles:ADD_STRING, nil];
    [requestActionSheet showInView:self.view];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSFetchedResultsController *)subscriptionRequestsFetchedResultsController
{
    if(_subscriptionRequestsFetchedResultsController)
    {
        return _subscriptionRequestsFetchedResultsController;
    }
    
    _subscriptionRequestsFetchedResultsController = [OTRXMPPManagedPresenceSubscriptionRequest MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:OTRXMPPManagedPresenceSubscriptionRequestAttributes.jid ascending:YES delegate:self];
    
    return _subscriptionRequestsFetchedResultsController;
}

-(NSArray* )subscriptionRequests {
    NSPredicate * accountPredicate = [NSPredicate predicateWithFormat:@"self.xmppAccount.isConnected == YES"];
    return [[self.subscriptionRequestsFetchedResultsController fetchedObjects] filteredArrayUsingPredicate:accountPredicate];
}
/*
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeDelete:
             [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}
*/
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex )
    {
        OTRXMPPManager * manager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:currentlySelectedRequest.xmppAccount];
        XMPPJID *jid = [XMPPJID jidWithString:currentlySelectedRequest.jid];
        
        if (actionSheet.destructiveButtonIndex == buttonIndex) {
            [manager.xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
        }
        else
        {
            [manager.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
        }
        [currentlySelectedRequest MR_deleteEntity];
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    }
    
    
}

@end
