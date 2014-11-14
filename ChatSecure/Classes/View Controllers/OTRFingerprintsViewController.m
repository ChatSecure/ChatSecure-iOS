//
//  OTRFingerprintsViewController.m
//  Off the Record
//
//  Created by David Chiles on 2/11/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRFingerprintsViewController.h"
#import "OTRKit.h"
#import "Strings.h"
#import "OTRAccount.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"

@interface OTRFingerprintsViewController ()

@property (nonatomic,strong) NSArray * buddyFingerprintsArray;
@property (nonatomic,strong) NSArray * myFingerprintsArray;

@property (nonatomic,strong) UIAlertView * alertView;

@end

@implementation OTRFingerprintsViewController

- (void)dealloc
{
    _alertView.delegate = nil;
    _alertView = nil;
    _buddyFingerprintsArray = nil;
    _myFingerprintsArray = nil;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self loadMyFingerprints];
        [self loadBuddyFingerprints];
        
    }
    return self;
}

- (void)loadMyFingerprints
{
    //FIXME I don't think this will work
    __weak OTRFingerprintsViewController *weakSelf = self;
    NSMutableArray *fingerprintsArray = [NSMutableArray array];
    self.myFingerprintsArray = fingerprintsArray;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [[transaction ext:OTRAllAccountDatabaseViewExtensionName] enumerateKeysAndObjectsInGroup:OTRAllAccountGroup usingBlock:^(NSString *collection, NSString *key, OTRAccount *account, NSUInteger index, BOOL *stop) {
            [[OTRKit sharedInstance] fingerprintForAccountName:account.username protocol:account.protocolTypeString completion:^(NSString *fingerprint) {
                if (fingerprint) {
                    [fingerprintsArray addObject:@{kOTRKitAccountNameKey:account.username,kOTRKitFingerprintKey:fingerprint}];
                    [weakSelf.tableView reloadData];
                }
            }];
        }];
    }];
}

- (void)loadBuddyFingerprints
{
    __weak OTRFingerprintsViewController *welf = self;
    [[OTRKit sharedInstance] requestAllFingerprints:^(NSArray *allFingerprints) {
        NSSortDescriptor * usernameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kOTRKitUsernameKey ascending:YES];
        NSSortDescriptor * accountNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kOTRKitAccountNameKey ascending:YES];
        NSSortDescriptor * trustSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kOTRKitTrustKey ascending:NO];
        NSArray * sortDescriptorsArray = @[usernameSortDescriptor,accountNameSortDescriptor,trustSortDescriptor];
        self.buddyFingerprintsArray = [allFingerprints sortedArrayUsingDescriptors:sortDescriptorsArray];
        [welf.tableView reloadData];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return ACCOUNT_FINGERPRINTS_STRING;
    }
    return BUDDY_FINGERPRINTS_STRING;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.myFingerprintsArray count];
    }
    return [self.buddyFingerprintsArray count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return YES;
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.section == 0) {
        NSDictionary * cellDict = [self.myFingerprintsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = cellDict[kOTRKitAccountNameKey];
        cell.detailTextLabel.text = cellDict[kOTRKitFingerprintKey];
    }
    else if (indexPath.section == 1) {
        NSDictionary * cellDict = [self.buddyFingerprintsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = cellDict[kOTRKitUsernameKey];
        cell.detailTextLabel.text = cellDict[kOTRKitAccountNameKey];
        
        BOOL trusted = [cellDict[kOTRKitTrustKey] boolValue];
        if (trusted) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString * body  = nil;
    NSString * title = nil;
    if (indexPath.section == 0) {
        NSDictionary * dict = self.myFingerprintsArray[indexPath.row];
        title = dict[kOTRKitAccountNameKey];
        body = dict[kOTRKitFingerprintKey];
    }
    else if (indexPath.section == 1) {
        NSDictionary * dict = self.buddyFingerprintsArray[indexPath.row];
        title = dict[kOTRKitUsernameKey];
        NSString * fingerprint = dict[kOTRKitFingerprintKey];
        BOOL verified = [dict[kOTRKitTrustKey] boolValue];
        NSString * verifiedString = nil;
        if (verified) {
            verifiedString = VERIFIED_STRING;
        }
        else {
            verifiedString = NOT_VERIFIED_STRING;
        }
        body = [NSString stringWithFormat:@"%@\n%@",fingerprint,verifiedString];
    }
    
    self.alertView = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
    [self.alertView show];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary * dict = self.buddyFingerprintsArray[indexPath.row];
        
        
        [[OTRKit sharedInstance] deleteFingerprint:dict[kOTRKitFingerprintKey] username:dict[kOTRKitUsernameKey] accountName:dict[kOTRKitAccountNameKey] protocol:dict[kOTRKitProtocolKey] completion:^(BOOL success) {
            if (success) {
                self.buddyFingerprintsArray = nil;
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }];
    }
}

@end
