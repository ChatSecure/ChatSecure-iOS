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
#import "OTRManagedAccount.h"

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
        [self myFingerprintsArray];
        [self buddyFingerprintsArray];
        
    }
    return self;
}

- (NSArray *)myFingerprintsArray
{
    if (!_myFingerprintsArray) {
        _myFingerprintsArray = @[];
        NSArray * accounts = [OTRManagedAccount MR_findAllSortedBy:OTRManagedAccountAttributes.username ascending:YES];
        [accounts enumerateObjectsUsingBlock:^(OTRManagedAccount * account, NSUInteger idx, BOOL *stop) {
            NSString * fingerprint = [[OTRKit sharedInstance] fingerprintForAccountName:account.username protocol:account.protocol];
            if (fingerprint.length) {
                NSString * username = account.username;
                _myFingerprintsArray = [_myFingerprintsArray arrayByAddingObject:@{OTRAccountNameKey:username,OTRFingerprintKey:fingerprint}];
            }
        }];
    }
    
    return _myFingerprintsArray;
}

- (NSArray *)buddyFingerprintsArray
{
    if (!_buddyFingerprintsArray) {
        NSSortDescriptor * usernameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:OTRUsernameKey ascending:YES];
        NSSortDescriptor * accountNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:OTRAccountNameKey ascending:YES];
        NSSortDescriptor * trustSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:OTRTrustKey ascending:NO];
        NSArray * sortDescriptorsArray = @[usernameSortDescriptor,accountNameSortDescriptor,trustSortDescriptor];
        
        _buddyFingerprintsArray = [[[OTRKit sharedInstance] allFingerprints] sortedArrayUsingDescriptors:sortDescriptorsArray];
    }
    return _buddyFingerprintsArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Account Fingerprints";
    }
    return @"Buddy Fingerprints";
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
        cell.textLabel.text = cellDict[OTRAccountNameKey];
        cell.detailTextLabel.text = cellDict[OTRFingerprintKey];
    }
    else if (indexPath.section == 1) {
        NSDictionary * cellDict = [self.buddyFingerprintsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = cellDict[OTRUsernameKey];
        cell.detailTextLabel.text = cellDict[OTRAccountNameKey];
        
        BOOL trusted = [cellDict[OTRTrustKey] boolValue];
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
        title = dict[OTRAccountNameKey];
        body = dict[OTRFingerprintKey];
    }
    else if (indexPath.section == 1) {
        NSDictionary * dict = self.buddyFingerprintsArray[indexPath.row];
        title = dict[OTRUsernameKey];
        body = dict[OTRFingerprintKey];
    }
    
    self.alertView = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
    [self.alertView show];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary * dict = self.buddyFingerprintsArray[indexPath.row];
        
        if([[OTRKit sharedInstance] deleteFingerprint:dict[OTRFingerprintKey] username:dict[OTRUsernameKey] accountName:dict[OTRAccountNameKey] protocol:dict[OTRProtocolKey]]) {
            
            //delete fingerpring
            self.buddyFingerprintsArray = nil;
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            
            
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
