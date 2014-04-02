//
//  OTRConversationViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationViewController.h"

#import "OTRSettingsViewController.h"
//#import "OTRChatViewController.h"
#import "OTRComposeViewController.h"

#import "OTRConversationCell.h"

#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRMessage.h"

#import "OTRLog.h"
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseView.h"
#import "YapDatabaseViewMappings.h"


static CGFloat cellHeight = 80.0;

@interface OTRConversationViewController () <NSFetchedResultsControllerDelegate, OTRComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
//@property (nonatomic, strong) OTRChatViewController *chatViewController;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) YapDatabaseConnection *connection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
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
    
    ////////// Create YapDatabase View /////////////////
    
    self.connection = [OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection;
    
    [OTRDatabaseView registerConversationDatabaseView];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRConversationGroup] view:OTRConversationDatabaseViewExtensionName];
    
    
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:OTRUIDatabaseConnectionDidUpdateNotification
                                               object:nil];
    
    
    
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

- (void)enterConversationWithBuddy:(OTRBuddy *)buddy
{
    //[self.chatViewController setBuddy:buddy];
    //[self.navigationController pushViewController:self.chatViewController animated:YES];
}

- (void)updateVisibleCells:(id)sender
{
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
/*
- (OTRChatViewController *)chatViewController
{
    if (!_chatViewController) {
        _chatViewController = [[OTRChatViewController alloc] init];
    }
    return _chatViewController;
}
*/
- (OTRBuddy *)buddyForIndexPath:(NSIndexPath *)indexPath
{
    
    __block OTRBuddy *buddy = nil;
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        buddy = [[transaction extension:OTRConversationDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    return buddy;
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.mappings numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBuddy *cellBuddy = [self buddyForIndexPath:indexPath];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRMessage deleteAllMessagesForBuddyId:cellBuddy.uniqueId transaction:transaction];
        }];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
    OTRBuddy * buddy = [self buddyForIndexPath:indexPath];
    
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
    OTRBuddy *buddy = [self buddyForIndexPath:indexPath];
    [self enterConversationWithBuddy:buddy];
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = notification.userInfo[@"notifications"];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.connection ext:OTRConversationDatabaseViewExtensionName] getSectionChanges:&sectionChanges
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

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddy:(OTRManagedBuddy *)buddy
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self enterConversationWithBuddy:buddy];
    }];
}



@end
