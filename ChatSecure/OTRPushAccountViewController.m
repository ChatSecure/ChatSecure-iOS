//
//  OTRPushAccountViewController.m
//  Off the Record
//
//  Created by David Chiles on 4/29/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushAccountViewController.h"
#import "OTRPushManager.h"

#import "OTRProtocolManager.h"
#import "OTRAccountsManager.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseViewMappings.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRYapPushDevice.h"
#import "OTRYapPushToken.h"
#import "OTRYapPushAccount.h"

@interface OTRPushAccountViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) OTRPushManager *pushManager;

@property (nonatomic, strong) YapDatabaseViewMappings *mappings;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;


@end

@implementation OTRPushAccountViewController

- (id)init
{
    if (self = [super init]) {
        self.pushManager = [[OTRProtocolManager sharedInstance] defaultPushManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ////// TEST!!!!!!!!! //////
    
    /*[self.pushManager loginWithUsername:@"bob" password:@"bob" completion:^(BOOL success, NSError *error) {
        if (error)
        {
            DDLogError(@"Error loggin in: %@",error);

        }
    }];*/
    
    
     ////// TaleView //////
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    
    [self.view addSubview:self.tableView];
    
    ////// YapDatabase View //////
    self.databaseConnection = [OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection;
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRPushAccountGroup,OTRPushTokenGroup,OTRPushDeviceGroup] view:OTRAllPushAccountInfoViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
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
    
    [self.pushManager refreshCurrentAccount:^(BOOL success, NSError *error) {
        if (error) {
            DDLogError(@"Error refreshing accoutnt %@",error);
        }
    }];
    [self.pushManager fetchAllDevices:^(BOOL success, NSError *error) {
        if (error) {
            DDLogError(@"Error refreshing Devices %@",error);
        }
    }];
    /*
    [self.pushManager fetchAllPushTokens:^(BOOL success, NSError *error) {
        if (error) {
            DDLogError(@"Error refreshing Tokens %@",error);
        }
    }];*/
}

#pragma - mark YapDatabaseMethods

- (OTRPushObject *)pushObjectAtIndexPath:(NSIndexPath *)indexPath
{
    __block OTRPushObject *pushObject = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        pushObject = [[transaction extension:OTRAllPushAccountInfoViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    return pushObject;
}

#pragma - mark UITableViewDataSource Methods

////// Required //////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    else
    {
        //tokens
        //devices
        return [self.mappings numberOfItemsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSString *const accountCellIdentifier = @"accountCellIdentifier";
    NSString *const defaultCellIdentifier = @"accountCellIdentifier";
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:accountCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:accountCellIdentifier];
        }
        
        OTRYapPushAccount *pushAccount = [OTRAccountsManager defaultPushAccount];
        cell.textLabel.text = pushAccount.pushAccount.username;
        cell.detailTextLabel.text = pushAccount.pushAccount.username;
        
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:defaultCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:defaultCellIdentifier];
        }
        
        
        OTRPushObject *pushObject = [self pushObjectAtIndexPath:indexPath];
        
        if ([pushObject isKindOfClass:[OTRPushDevice class]]) {
            OTRPushDevice *device =(OTRPushDevice *)pushObject;
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %d %@",device.deviceName,device.osType,device.osVersion];
            cell.detailTextLabel.text = ((OTRPushDevice *)pushObject).pushToken;
        }
        else if ([pushObject isKindOfClass:[OTRPushToken class]]){
            OTRPushToken *token = (OTRPushToken *)pushObject;
            
            cell.textLabel.text = token.token;
            cell.detailTextLabel.text = nil;
        }
        
        
    }
    return cell;
}

////// Optional //////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.mappings groupForSection:section];
}


#pragma - mark UITableViewDelegate Methods

////// Optional //////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSMutableArray *devices = [NSMutableArray array];
        NSArray *allDeviceKeys = [transaction allKeysInCollection:[OTRYapPushToken collection]];
        [transaction enumerateObjectsForKeys:allDeviceKeys inCollection:[OTRYapPushToken collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
            [devices addObject:object];
        }];
        
    }];
}

#pragma - mark  YapDatabaseNotification

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = notification.userInfo[@"notifications"];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRAllPushAccountInfoViewExtensionName] getSectionChanges:&sectionChanges
                                                                                 rowChanges:&rowChanges
                                                                           forNotifications:notifications
                                                                               withMappings:self.mappings];
    
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
            case YapDatabaseViewChangeUpdate:
            case YapDatabaseViewChangeMove:
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
