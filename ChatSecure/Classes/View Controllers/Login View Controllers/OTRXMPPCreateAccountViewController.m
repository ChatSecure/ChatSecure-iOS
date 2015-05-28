//
//  OTRXMPPCreateViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountViewController.h"
#import "Strings.h"

#import "OTRTorManager.h"
#import "OTRAccountsManager.h"
#import "OTRLog.h"
#import "OTRConstants.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPManager.h"
#import "OTRTextFieldTableViewCell.h"
#import "JVFloatLabeledTextField.h"
#import "OTRDatabaseManager.h"
#import "OTRDomainCellInfo.h"
#import "OTRDatabaseView.h"
#import "OTRXMPPTorAccount.h"
#import "Strings.h"

static NSString * const domainCellIdentifier = @"domainCellIdentifer";

@interface OTRXMPPCreateAccountViewController ()

@property (nonatomic, strong) NSArray * hostnameArray;

@property (nonatomic, strong) JVFloatLabeledTextField *customHostnameTextField;

@property (nonatomic, strong) OTRXMPPManager *currentXMPPManager;

@end

@implementation OTRXMPPCreateAccountViewController

@dynamic account;

- (id)init
{
    if (self = [super init]) {
        self.customHostnameTextField = [[JVFloatLabeledTextField alloc] initWithFrame:CGRectZero];
        [self.customHostnameTextField setPlaceholder:CUSTOM_STRING];
        self.customHostnameTextField.returnKeyType = UIReturnKeyDone;
        self.customHostnameTextField.delegate = self;
    }
    return self;
}

- (id)initWithHostnames:(NSArray *)newHostnames
{
    self = [self init];
    if (self) {
        self.hostnameArray = newHostnames;
        self.selectedHostnameIndex = 0;
    }
    return self;
}

#pragma - mark View Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = CREATE_NEW_ACCOUNT_STRING;
	self.usernameTextField.placeholder = USERNAME_STRING;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    self.loginButton.title = CREATE_STRING;
}

#pragma - mark UITableViewDelegate Mehtods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.hostnameArray.count) {
        return 2;
    }
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return self.hostnameArray.count+1;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return HOSTNAME_STRING;
    }
    return BASIC_STRING;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return 44.0f;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell * cell = nil;
    if (indexPath.section == 1) {
        if (indexPath.row < [self.hostnameArray count]) {
            cell = [tableView dequeueReusableCellWithIdentifier:domainCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:domainCellIdentifier];
            }
            OTRDomainCellInfo* cellInfo = self.hostnameArray[indexPath.row];
            cell.textLabel.text = cellInfo.displayName;
            cell.detailTextLabel.text = cellInfo.domain;
        }
        else
        {
            //Other or Custom Hostname
            
            OTRTextFieldTableViewCell *textCell = [tableView dequeueReusableCellWithIdentifier:[OTRTextFieldTableViewCell reuseIdentifier]];
            if (!cell) {
                textCell = [[OTRTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[OTRTextFieldTableViewCell reuseIdentifier]];
            }
            
            textCell.textField = self.customHostnameTextField;
            cell = textCell;
        }
        
        if (self.selectedHostnameIndex == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    else {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1 && self.selectedHostnameIndex != indexPath.row) {
        NSInteger oldRow = self.selectedHostnameIndex;
        self.selectedHostnameIndex = indexPath.row;
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldRow inSection:1];
        
        [tableView reloadRowsAtIndexPaths:@[oldIndexPath,indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)fixUsername:(NSString *)username withDomain:(NSString *)domain;
{
    NSString * finalUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    if ([finalUsername length]) {
        if ([finalUsername rangeOfString:@"@"].location == NSNotFound) {
            //append correct domain
            finalUsername = [NSString stringWithFormat:@"%@@%@",finalUsername,domain];
        }
    }
    return finalUsername;
}

- (BOOL)checkFields
{
    BOOL fields = [super checkFields];
    if (fields) {
        if (![[self serverHostnameForIndex:self.selectedHostnameIndex] length]) {
            fields = NO;
            [self showAlertViewWithTitle:ERROR_STRING message:DOMAIN_BLANK_ERROR_STRING error:nil];
        }
    }
    return fields;
}

- (BOOL) checkForDuplicateTorAccounts {
    OTRXMPPTorAccount *thisAccount = (OTRXMPPTorAccount*)self.account;
    NSString *selectedDomain = nil;
    if (thisAccount.domain.length) {
        selectedDomain = thisAccount.domain;
    } else {
        selectedDomain = [self serverHostnameForIndex:self.selectedHostnameIndex];
    }
    __block BOOL alreadyExistingTorDomain = NO;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:OTRAllAccountDatabaseViewExtensionName];
        [viewTransaction enumerateKeysAndObjectsInGroup:OTRAllAccountGroup usingBlock:^(NSString *collection, NSString *key, OTRXMPPAccount *account, NSUInteger index, BOOL *stop) {
            if ([account isKindOfClass:[OTRXMPPTorAccount class]] && [account.domain isEqualToString:selectedDomain] && thisAccount.uniqueId != account.uniqueId) {
                alreadyExistingTorDomain = YES;
            }
        }];
    }];
    return alreadyExistingTorDomain;
}

-(void) loginButtonPressed:(id)sender
{
    if (![self checkFields]) {
        return;
    }
    
    // Kludge to prevent multiple Tor connections to the same domain until
    // we support Tor's SOCKS user/pass isolation
    if (self.isTorAccount) {
        BOOL dupes = [self checkForDuplicateTorAccounts];
        if (dupes) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:TOR_DOMAIN_WARNING_MESSAGE_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            [alert show];
            return;
        }
    }
    
    self.loginButtonPressed = YES;
    if(self.isTorAccount && ![OTRTorManager sharedInstance].torManager.isConnected)
    {
        if ([OTRTorManager sharedInstance].torManager.status == CPAStatusConnecting) {
            return;
        }
        [self showHUDWithText:CONNECTING_TO_TOR_STRING];
        [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
            // TODO: handle Tor/SOCKS setup error
            if (error) {
                DDLogError(@"Error setting up Tor: %@", error);
            } else {
                // successfully connected to Tor
                [super loginButtonPressed:sender];
            }
        } progress:^(NSInteger progress, NSString *summaryString) {
            self.HUD.mode = MBProgressHUDModeDeterminate;
            self.HUD.labelText = summaryString;
            self.HUD.progress = progress/100.0;
        }];
    }
    else {
        [self showHUDWithText:CREATING_ACCOUNT_STRING];
        __weak typeof(self)weakSelf = self;
//        self.currentXMPPManager = [OTRXMPPManager attemptToCreateAccountWithUsername:self.usernameTextField.text password:self.passwordTextField.text domain:[self serverHostnameForIndex:self.selectedHostnameIndex] completionQueue:dispatch_get_main_queue() completion:^(NSError *error) {
//            __strong typeof(weakSelf)strongSelf = weakSelf;
//            if (error) {
//                [strongSelf didReceiveRegistrationFailedError:error];
//            }
//            else {
//                [strongSelf didReceiveRegistrationSucceeded];
//            }
//        }];
    }
}

- (void)didReceiveRegistrationSucceeded
{
    if (self.currentXMPPManager) {
        self.HUD.labelText = LOGGING_IN_STRING;
        self.currentXMPPManager.account.rememberPassword = self.rememberPasswordSwitch.on;
        self.currentXMPPManager.account.autologin = self.autoLoginSwitch.on;
        self.currentXMPPManager.account.domain = [self serverHostnameForIndex:self.selectedHostnameIndex];
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.currentXMPPManager.account saveWithTransaction:transaction];
        }];
        
        [[OTRProtocolManager sharedInstance] setProtocol:self.currentXMPPManager forAccount:self.currentXMPPManager.account];
        
        [self.currentXMPPManager connectWithPassword:self.passwordTextField.text userInitiated:YES];
    }
}

- (void)didReceiveRegistrationFailedError:(NSError *)error
{
    [self hideHUD];
    DDLogWarn(@"Registration Failed: %@",error);
    NSString * errorString = REGISTER_ERROR_STRING;
    if (error) {
        if ([error.domain isEqualToString:OTRXMPPErrorDomain]) {
            if (error.code == OTRXMPPUnsupportedAction) {
                errorString = IN_BAND_ERROR_STRING;
            }
            else if (error.code == OTRXMPPXMLError) {
                if ([error.localizedDescription length]) {
                    errorString = error.localizedDescription;
                }
            }
        }
    }
    
    [self showAlertViewWithTitle:ERROR_STRING message:errorString error:error];
}

- (NSString *)usernameHostnameForIndex:(NSInteger)index
{
    NSString *hostname = nil;
    if (index < [self.hostnameArray count]) {
        OTRDomainCellInfo *cellInfo = self.hostnameArray[index];
        hostname = cellInfo.usernameDomain;
    }
    else {
        hostname = self.customHostnameTextField.text;
        //Other
    }
    return hostname;
}

- (NSString *)serverHostnameForIndex:(NSInteger)index
{
    NSString *hostname = nil;
    if (index < [self.hostnameArray count]) {
        OTRDomainCellInfo *cellInfo = self.hostnameArray[index];
        hostname = cellInfo.domain;
    }
    else {
        hostname = self.customHostnameTextField.text;
        //Other
    }
    return hostname;
}

+ (instancetype)createViewControllerWithHostnames:(NSArray *)hostNames
{
    return [[self alloc] initWithHostnames:hostNames];
}

#pragma - mark UITextFieldDelegate  

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:self.customHostnameTextField]) {
        
        if (self.selectedHostnameIndex != [self.hostnameArray count]) {
            NSInteger oldRow = self.selectedHostnameIndex;
            self.selectedHostnameIndex = [self.hostnameArray count];
            [self.loginViewTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldRow inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
            
            UITableViewCell *cell = [self.loginViewTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.hostnameArray count] inSection:1]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
        
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}
@end
