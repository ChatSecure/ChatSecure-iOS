//
//  OTRLoginViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRLoginViewController.h"
#import "OTRConstants.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedOscarAccount.h"


#import "OTRXMPPLoginViewController.h"
#import "OTRJabberLoginViewController.h"
#import "OTRFacebookLoginViewController.h"
#import "OTROscarLoginViewController.h"
#import "OTRGoogleTalkLoginViewController.h"
#import "OTRInLineTextEditTableViewCell.h"
#import "OTRManagedXMPPTorAccount.h"

#import "SIAlertView.h"

#import "OTRCertificatePinning.h"

#define kFieldBuffer 20;

NSString *const kTextLabelTextKey       = @"kTextLabelTextKey";
NSString *const kCellTypeKey            = @"kCellTypeKey";
NSString *const kUserInputViewKey       = @"kUserInputViewKey";
NSString *const kCellTypeTextField      = @"kCellTypeTextField";
NSString *const kCellTypeSwitch         = @"kCellTypeSwitch";
NSString *const KCellTypeHelp           = @"KCellTypeHelp";

NSUInteger const kErrorAlertViewTag     = 130;
NSUInteger const kErrorInfoAlertViewTag = 131;
NSUInteger const kNewCertAlertViewTag   = 132;



@interface OTRLoginViewController(Private)
- (float) getMidpointOffsetforHUD;
@end

@implementation OTRLoginViewController

- (void) dealloc {
    self.logoView = nil;
    self.rememberPasswordSwitch = nil;
    self.usernameTextField = nil;
    self.passwordTextField = nil;
    self.loginButton = nil;
    self.cancelButton = nil;
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.account = nil;
    self.textFieldTextColor = nil;
}

- (id) initWithAccountID:(NSManagedObjectID *)newAccountID {
    if (self = [super init]) {
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        self.account = (OTRManagedAccount *)[context existingObjectWithID:newAccountID error:nil];
        
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            self.textFieldTextColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
        }
        else {
            self.textFieldTextColor = [UIColor colorWithRed:0 green:0.47843137 blue:1 alpha:1];
        }
        
    }
    return self;
}

-(void)setupFields
{
    [self addCellinfoWithSection:0 row:0 labelText:USERNAME_STRING cellType:kCellTypeTextField userInputView:self.usernameTextField];

    [self addCellinfoWithSection:0 row:1 labelText:PASSWORD_STRING cellType:kCellTypeTextField userInputView:self.passwordTextField];
    
    [self addCellinfoWithSection:0 row:2 labelText:REMEMBER_PASSWORD_STRING cellType:kCellTypeSwitch userInputView:self.rememberPasswordSwitch];
    
    [self addCellinfoWithSection:0 row:3 labelText:LOGIN_AUTOMATICALLY_STRING cellType:kCellTypeSwitch userInputView:self.autoLoginSwitch];
}

-(UITextField *)usernameTextField
{
    if (!_usernameTextField) {
        _usernameTextField = [[UITextField alloc] init];
        _usernameTextField.delegate = self;
        _usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _usernameTextField.text = self.account.username;
        _usernameTextField.returnKeyType = UIReturnKeyDone;
        _usernameTextField.textColor = self.textFieldTextColor;
    }
    return  _usernameTextField;
}

-(UITextField *)passwordTextField
{
    if(!_passwordTextField) {
        _passwordTextField = [[UITextField alloc] init];
        _passwordTextField.delegate = self;
        _passwordTextField.secureTextEntry = YES;
        _passwordTextField.returnKeyType = UIReturnKeyDone;
        _passwordTextField.textColor = self.textFieldTextColor;
        _passwordTextField.placeholder = REQUIRED_STRING;
    }
    return _passwordTextField;
}

- (UISwitch *)rememberPasswordSwitch
{
    if (!_rememberPasswordSwitch) {
        _rememberPasswordSwitch = [[UISwitch alloc] init];
        [_rememberPasswordSwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _rememberPasswordSwitch;
}

- (UISwitch *)autoLoginSwitch
{
    if (!_autoLoginSwitch) {
        _autoLoginSwitch = [[UISwitch alloc] init];
        [_autoLoginSwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _autoLoginSwitch;
}

- (UITableView *)loginViewTableView
{
    if (!_loginViewTableView) {
        _loginViewTableView= [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _loginViewTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_loginViewTableView setDelegate:self];
        [_loginViewTableView setDataSource:self];
    }
    return _loginViewTableView;
}

- (NSMutableArray *)tableViewArray
{
    if(!_tableViewArray)
    {
        _tableViewArray = [[NSMutableArray alloc] init];
    }
    return _tableViewArray;
}

- (void)switchDidChange:(id)sender
{
    if ([sender isEqual:self.autoLoginSwitch]) {
        if (self.autoLoginSwitch.on) {
            [self.rememberPasswordSwitch setOn:YES animated:YES];
        }
    }
    else if ([sender isEqual:self.rememberPasswordSwitch]) {
        if (!self.rememberPasswordSwitch.on) {
            [self.autoLoginSwitch setOn:NO animated:YES];
        }
    }
    
}

-(void)addCellinfoWithSection:(NSInteger)section row:(NSInteger)row labelText:(id)text cellType:(NSString *)type userInputView:(UIView *)inputView;
{    
    if ([self.tableViewArray count]<(section+1)) {
        [self.tableViewArray setObject:[[NSMutableArray alloc] init] atIndexedSubscript:section];
    }
    
    NSDictionary * cellDictionary = [NSDictionary dictionaryWithObjectsAndKeys:text,kTextLabelTextKey,type,kCellTypeKey,inputView,kUserInputViewKey, nil];
    
    [[self.tableViewArray objectAtIndex:section] insertObject:cellDictionary atIndex:row];
    
}

- (void) viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupFields];
    
    self.title = self.account.providerName;
    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:LOGIN_STRING style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.navigationItem.rightBarButtonItem = self.loginButton;
    
    if (!self.isNewAccount) {
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }
    
    
    
    [self.view addSubview:self.loginViewTableView];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewArray.count;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.tableViewArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.tableViewArray.count > 1)
    {
        if(section == 0)
            return BASIC_STRING;
        else if (section == 1)
            return ADVANCED_STRING;
    }
    return @"";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[[[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:kCellTypeKey] isEqualToString:KCellTypeHelp])
    {
        CGFloat height = ((UILabel *)[[[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:kTextLabelTextKey]).frame.size.height+10;
        return height;
    }
    return 44.0f;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary * cellDictionary = [[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString * cellType = [cellDictionary objectForKey:kCellTypeKey];
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    if( [cellType isEqualToString:kCellTypeSwitch])
    {
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
        }
        cell.textLabel.text = [cellDictionary objectForKey:kTextLabelTextKey];
        cell.accessoryView=[cellDictionary objectForKey:kUserInputViewKey];
        
    }
    else if( [cellType isEqualToString:KCellTypeHelp])
    {
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
            
            [cell.contentView addSubview:[cellDictionary objectForKey:kTextLabelTextKey]];
            cell.accessoryView = [cellDictionary objectForKey:kUserInputViewKey];
        }
        
    }
    else if([cellType isEqualToString:kCellTypeTextField])
    {
        if(!cell)
        {
            cell = [[OTRInLineTextEditTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
        }
        cell.textLabel.text = [cellDictionary objectForKey:kTextLabelTextKey];
        [cell layoutIfNeeded];
        ((OTRInLineTextEditTableViewCell *)cell).textField = [cellDictionary objectForKey:kUserInputViewKey];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}




#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(protocolLoginFailed:)
                                                 name:kOTRProtocolLoginFail
                                               object:nil ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(protocolLoginSuccess:)
                                                 name:kOTRProtocolLoginSuccess
                                               object:nil ];
    
    if(!self.usernameTextField.text.length)
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
    
    self.autoLoginSwitch.on = self.account.autologinValue;
    self.rememberPasswordSwitch.on = self.account.rememberPasswordValue;
    if (self.account.rememberPasswordValue) {
        self.passwordTextField.text = self.account.password;
    } else {
        self.passwordTextField.text = @"";
    }
}
- (void) viewWillDisappear:(BOOL)animated {
    
    
    [self readInFields];
    
    if(self.account.username.length)
    {
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    }
    [self.view resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTRProtocolLoginFail
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                              name:kOTRProtocolLoginSuccess
                                                  object:nil];
}

-(void)readInFields
{
    self.account.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.account.rememberPasswordValue = self.rememberPasswordSwitch.on;
    
    self.account.autologinValue = self.autoLoginSwitch.on;
    
    if (self.account.rememberPasswordValue) {
        self.account.password = self.passwordTextField.text;
    } else {
        self.account.password = nil;
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self hideHUD];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

-(void) timeout:(NSTimer *) timer
{
    //[timeoutTimer invalidate];
    [self hideHUD];
}
- (void)hideHUD {
    if (self.HUD) {
        [self.HUD hide:YES];
    }
}

- (void)protocolLoginFailed:(NSNotification*)notification
{
    [self hideHUD];
    NSString * errorMessage = @"";
    if([self.account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        errorMessage = XMPP_FAIL_STRING;
        
    }
    else {
        errorMessage = OSCAR_FAIL_STRING;
    }
    NSError * error = notification.userInfo[kOTRNotificationErrorKey];
    
    [self showAlertViewWithTitle:ERROR_STRING message:errorMessage error:error];
}

-(void)protocolLoginSuccess:(NSNotification*)notification
{
    [self hideHUD];
    [self dismissViewControllerAnimated:YES completion:nil];
}  

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message error:(NSError *)error
{
    UIAlertView * alertView = nil;
    if (error) {
        self.recentError = error;
        alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:OK_STRING,INFO_STRING, nil];
    }
    else {
        alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        
    }
    
    if (alertView) {
        alertView.tag = kErrorAlertViewTag;
        [alertView show];
    }
}



- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        [self showHUDWithText:LOGGING_IN_STRING];
        
        [self readInFields];
        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol connectWithPassword:self.passwordTextField.text];
    }
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
}

- (void)showHUDWithText:(NSString *)text
{
    [self.view endEditing:YES];
    if (!self.HUD) {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
    }
    
    self.HUD.labelText = text;
    [self.HUD show:YES];
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
}

- (void)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

-(BOOL)checkFields
{
    BOOL fields = self.usernameTextField.text.length && self.passwordTextField.text.length;
    
    if(!fields)
    {
        [self showAlertViewWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING error:nil];
    }
    return fields;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void) didMoveToParentViewController:(UIViewController *)parent
{
    //Delete Account because user went back to choose different account type
    if(!parent)
    {
        [OTRAccountsManager removeAccount:self.account];
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kErrorAlertViewTag) {
        if(alertView.numberOfButtons > 1 && buttonIndex == 1) {
            NSString * errorDescriptionString = [NSString stringWithFormat:@"%@ : %@",[self.recentError domain],[self.recentError localizedDescription]];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:INFO_STRING message:errorDescriptionString delegate:self cancelButtonTitle:nil otherButtonTitles:OK_STRING,COPY_STRING, nil];
            alert.tag = kErrorInfoAlertViewTag;
            [alert show];
        }
    }
    else if (alertView.tag == kErrorInfoAlertViewTag) {
        if (buttonIndex == 1) {
            NSString * errorDescriptionString = [NSString stringWithFormat:@"Domain: %@\nCode: %d\nUserInfo: %@",[self.recentError domain],[self.recentError code],[self.recentError userInfo]];
            UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
            [pasteBoard setString:errorDescriptionString];
        }
    }
}

+(OTRLoginViewController *)loginViewControllerWithAcccountID:(NSManagedObjectID *)accountID
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedAccount * account = (OTRManagedAccount *)[context existingObjectWithID:accountID error:nil];
    switch (account.accountType) {
        case OTRAccountTypeAIM:
            return [[OTROscarLoginViewController alloc] initWithAccountID:accountID];
            break;
        case OTRAccountTypeXMPPTor:
        case OTRAccountTypeJabber:
            return [[OTRJabberLoginViewController alloc] initWithAccountID:accountID];
            break;
        case OTRAccountTypeFacebook:
            return [[OTRFacebookLoginViewController alloc] initWithAccountID:accountID];
            break;
        case OTRAccountTypeGoogleTalk:
            return [[OTRGoogleTalkLoginViewController alloc] initWithAccountID:accountID];
            break;
        default:
            break;
    }
}

@end
