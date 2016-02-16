//
//  OTRNewBuddyViewController.m
//  Off the Record
//
//  Created by David on 3/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRNewBuddyViewController.h"
#import "OTRInLineTextEditTableViewCell.h"
#import "OTRProtocolManager.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRStrings.h"
#import "OTRXMPPManager.h"
#import "OTRDatabaseManager.h"

#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPBuddy.h"

#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import "XMPPURI.h"
#import "OTRLanguageManager.h"
#import "NSURL+ChatSecure.h"

@interface OTRNewBuddyViewController () <QRCodeReaderDelegate>

@property (nonatomic) BOOL isXMPPaccount;

@end

@implementation OTRNewBuddyViewController

-(id)initWithAccountId:(NSString *)accountId {
    
    if (self = [super init]) {
        
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            self.account = [OTRAccount fetchObjectWithUniqueID:accountId transaction:transaction];
        }];
    }
    return self;
    
}

-(void)setAccount:(OTRAccount *)account
{
    self.isXMPPaccount = [[account protocolClass] isSubclassOfClass:[OTRXMPPManager class]];
    _account = account;
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return self.account.username;
    }
    return @"";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = ADD_BUDDY_STRING;
    
    //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    
    
    UIBarButtonItem *qrButton = [[UIBarButtonItem alloc] initWithTitle:QR_CODE_STRING style:UIBarButtonItemStylePlain target:self action:@selector(qrButtonPressed:)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[doneButton, qrButton];
    
    self.accountNameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.accountNameTextField.placeholder = XMPP_USERNAME_EXAMPLE_STRING;
    
    if (self.isXMPPaccount) {
        self.displayNameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.displayNameTextField.placeholder = OPTIONAL_STRING;
        self.accountNameTextField.delegate= self.displayNameTextField.delegate = self;
        
        self.displayNameTextField.autocapitalizationType = self.accountNameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.displayNameTextField.autocorrectionType = self.accountNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    
    if (self.storyboard == nil) {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if (self.storyboard == nil) {
        [self.view addSubview:self.tableView];
    }
    
    [self.accountNameTextField becomeFirstResponder];
	// Do any additional setup after loading the view.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isXMPPaccount) {
        return 2;
    }
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellType = @"Cell";
    UITextField * textField = nil;
    NSString * cellText = nil;
    
    if (indexPath.row == 0) {
        textField = self.accountNameTextField;
        cellText = USERNAME_STRING;
    }
    else if(indexPath.row == 1) {
        textField = self.displayNameTextField;
        cellText = NAME_STRING;
    }
    
    OTRInLineTextEditTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (!cell) {
        cell = [[OTRInLineTextEditTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
    }
    cell.textLabel.text = cellText;
    [cell layoutIfNeeded];
    cell.textField = textField;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(BOOL)checkFields
{
    if ([[self.accountNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)updateReturnButtons:(UITextField *)textField;
{
    if ([self checkFields] && [[self.accountNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] &&[[self.displayNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]) {
        textField.returnKeyType = UIReturnKeyDone;
    }
    else if ([textField isEqual:self.accountNameTextField]) {
        textField.returnKeyType = UIReturnKeyNext;
    }
    else if ([textField isEqual:self.displayNameTextField] && ![self checkFields])
    {
        textField.returnKeyType = UIReturnKeyNext;
    }
    else
    {
        textField.returnKeyType = UIReturnKeyDone;
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self updateReturnButtons:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone ) {
        [self doneButtonPressed:textField];
    }
    else{
        [textField resignFirstResponder];
        if ([textField isEqual:self.accountNameTextField]) {
            [self.displayNameTextField becomeFirstResponder];
        }
        else{
            [self.accountNameTextField becomeFirstResponder];
        }
    }
    
    return NO;
}

-(void)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

-(IBAction)doneButtonPressed:(id)sender
{
    if ([self checkFields]) {
        NSString * newBuddyAccountName = [[self.accountNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
        NSString * newBuddyDisplayName = [self.displayNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        __block OTRXMPPBuddy *buddy = nil;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            buddy = [OTRXMPPBuddy fetchBuddyWithUsername:newBuddyAccountName withAccountUniqueId:self.account.uniqueId transaction:transaction];
            if (!buddy) {
                buddy = [[OTRXMPPBuddy alloc] init];
                buddy.username = newBuddyAccountName;
                buddy.accountUniqueId = self.account.uniqueId;
            }
            
            buddy.displayName = newBuddyDisplayName;
            [buddy saveWithTransaction:transaction];
        }];
        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol addBuddy:buddy];

        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(controller:didAddBuddy:)]) {
            [self.delegate controller:self didAddBuddy:buddy];
        }
        [self dismissViewController];
    }
    else
    {
        
        [UIView animateWithDuration:.3 animations:^{
            self.accountNameTextField.backgroundColor = [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: .8];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 animations:^{
                self.accountNameTextField.backgroundColor = [UIColor clearColor];
            } completion:NULL];
        }];
        
    }
    
}

- (void)dismissViewController {
    if (self.delegate == nil || ([self.delegate respondsToSelector:@selector(shouldDismissViewController:)] && [self.delegate shouldDismissViewController:self])) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) qrButtonPressed:(id)sender {
    if (![QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
        return;
    }
    
    QRCodeReaderViewController *reader = [[QRCodeReaderViewController alloc] init];
    reader.modalPresentationStyle = UIModalPresentationFormSheet;
    reader.delegate = self;
    [self presentViewController:reader animated:YES completion:NULL];
}

- (void)populateFromQRResult:(NSString *)result
{
    NSURL *resultURL = [NSURL URLWithString:result];
    if ([result containsString:@"xmpp:"]) {
        XMPPURI *uri = [[XMPPURI alloc] initWithURIString:result];
        NSString *jid = uri.jid.full;
        if (jid.length) {
            self.accountNameTextField.text = jid;
        }
    } else if ([resultURL otr_isInviteLink]) {
        NSURL *url = [NSURL URLWithString:result];
        __block NSString *username = nil;
        __block NSString *fingerprint = nil;
        [url otr_decodeShareLink:^(NSString *uName, NSString *fPrint) {
            username = uName;
            fingerprint = fPrint;
        }];
        if (username.length) {
            self.accountNameTextField.text = username;
        }
#warning TODO: Process OTR fingerprint
        // this is where you'd add the OTR (or Axolotl) fingerprint to the trusted store
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unrecognized Invite Format", @"shown when invite QR code doesnt work") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - QRCodeReader Delegate Methods

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self populateFromQRResult:result];
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:NULL];
}

@end
