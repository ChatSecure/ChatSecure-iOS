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


#import "OTRXMPPLoginViewController.h"
#import "OTRJabberLoginViewController.h"
#import "OTRFacebookLoginViewController.h"
#import "OTRGoogleTalkLoginViewController.h"
#import "OTRInLineTextEditTableViewCell.h"
#import "OTRUtilities.h"
#import "OTRXMPPError.h"

#import "UIAlertView+Blocks.h"
#import "OTRCertificatePinning.h"
#import "OTRDatabaseManager.h"

#import "OTRXMPPTorAccount.h"

NSString *const kTextLabelTextKey       = @"kTextLabelTextKey";
NSString *const kCellTypeKey            = @"kCellTypeKey";
NSString *const kUserInputViewKey       = @"kUserInputViewKey";
NSString *const kCellTypeTextField      = @"kCellTypeTextField";
NSString *const kCellTypeSwitch         = @"kCellTypeSwitch";
NSString *const KCellTypeHelp           = @"KCellTypeHelp";

@interface OTRLoginViewController ()

@property (nonatomic, weak) id kOTRProtocolLoginFailObject;
@property (nonatomic, weak) id kOTRProtocolLoginSuccessObject;

@end

@implementation OTRLoginViewController

- (id) initWithAccount:(OTRAccount *)account{
    if (self = [super init]) {
        self.account = account;
        
        self.textFieldTextColor = [UIColor colorWithRed:0 green:0.47843137 blue:1 alpha:1];
        
    }
    return self;
}

-(void)setupFields
{
    [self addCellinfoWithSection:0 row:0 labelText:USERNAME_STRING cellType:kCellTypeTextField userInputView:self.usernameTextField];

    [self addCellinfoWithSection:0 row:1 labelText:PASSWORD_STRING cellType:kCellTypeTextField userInputView:self.passwordTextField];
    
    [self addCellinfoWithSection:0 row:2 labelText:REMEMBER_PASSWORD_STRING cellType:kCellTypeSwitch userInputView:self.rememberPasswordSwitch];
    
    if(![self.account isKindOfClass:[OTRXMPPTorAccount class]])
    {
        [self addCellinfoWithSection:0 row:3 labelText:LOGIN_AUTOMATICALLY_STRING cellType:kCellTypeSwitch userInputView:self.autoLoginSwitch];
    }
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

- (void)addCellinfoWithSection:(NSInteger)section row:(NSInteger)row labelText:(id)text cellType:(NSString *)type userInputView:(UIView *)inputView;
{
    if (!self.tableViewArray) {
        self.tableViewArray = [[NSMutableArray alloc] init];
    }
    
    if ([self.tableViewArray count]<(section+1)) {
        [self.tableViewArray setObject:[[NSMutableArray alloc] init] atIndexedSubscript:section];
    }
    
    NSDictionary * cellDictionary = [NSDictionary dictionaryWithObjectsAndKeys:text,kTextLabelTextKey,type,kCellTypeKey,inputView,kUserInputViewKey, nil];
    
    [[self.tableViewArray objectAtIndex:section] insertObject:cellDictionary atIndex:row];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupFields];
    
    self.title = [self.account accountDisplayName];
    
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

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    
    __weak OTRLoginViewController *welf = self;
    self.kOTRProtocolLoginFailObject = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRProtocolLoginFail object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf protocolLoginFailed:note];
    }];
    
    self.kOTRProtocolLoginSuccessObject = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRProtocolLoginSuccess object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf protocolLoginSuccess:note];
    }];
    
    if(!self.usernameTextField.text.length)
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
    
    self.autoLoginSwitch.on = self.account.autologin;
    self.rememberPasswordSwitch.on = self.account.rememberPassword;
    if (self.account.rememberPassword) {
        self.passwordTextField.text = self.account.password;
    } else {
        self.passwordTextField.text = @"";
    }
}
- (void) viewWillDisappear:(BOOL)animated
{    
    [super viewWillDisappear:animated];
    [self readInFields];
    
    [self.view resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self.kOTRProtocolLoginSuccessObject];
    [[NSNotificationCenter defaultCenter] removeObserver:self.kOTRProtocolLoginFailObject];
}

-(void)readInFields
{
    self.account.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.account.rememberPassword = self.rememberPasswordSwitch.on;
    
    self.account.autologin = self.autoLoginSwitch.on;
    
    if (self.account.rememberPassword) {
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

- (void)hideHUD {
    if (self.HUD) {
        [self.HUD hide:YES];
    }
}

- (void)protocolLoginFailed:(NSNotification*)notification
{
    if(self.HUD)
    {
        [self.HUD hide:YES];
    }
    
    if (self.account.protocolType == OTRProtocolTypeXMPP) {
        NSDictionary * userInfo = notification.userInfo;
        id error = userInfo[kOTRNotificationErrorKey];
        
        if ([error isKindOfClass:[NSError class]]) {
            [self showAlertViewWithTitle:ERROR_STRING message:XMPP_FAIL_STRING error:error];
        }
        else {
            [self showAlertViewWithTitle:ERROR_STRING message:XMPP_FAIL_STRING error:nil];
        }
    }
}

- (void)protocolLoginSuccess:(NSNotification*)notification
{
    [self hideHUD];
    __block OTRAccount *accountCopy = [self.account copy];
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        [accountCopy saveWithTransaction:transaction];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}  




- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        [self showHUDWithText:LOGGING_IN_STRING];
        
        [self readInFields];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            
            [self.account saveWithTransaction:transaction];
        }];
        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol connectWithPassword:self.passwordTextField.text];
    }
}

- (void)showHUDWithText:(NSString *)text
{
    [self.view endEditing:YES];
    if (!self.HUD) {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
    }
    self.HUD.mode = MBProgressHUDModeIndeterminate;
    self.HUD.labelText = text;
    [self.HUD show:YES];
}

- (void)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)isDuplicateUsername:(NSString *)username
{
    __block BOOL isDuplicate = NO;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *accounts = [OTRAccount allAccountsWithUsername:username transaction:transaction];
        if(accounts.count) {
            //already more than one account with this username
            OTRAccount *savedAccount = [accounts firstObject];
            if(accounts.count > 1 || ![savedAccount.uniqueId isEqualToString:self.account.uniqueId])
            {
                isDuplicate = YES;
            }
        }
    }];
    
    return isDuplicate;
}

- (BOOL)checkFields
{
    __block BOOL fields = self.usernameTextField.text.length && self.passwordTextField.text.length;
    
    if (fields) {
        //check that the username is unique
        if([self isDuplicateUsername:self.usernameTextField.text])
        {
            fields = NO;
            [self showAlertViewWithTitle:DUPLICATE_ACCOUNT_STRING message:DUPLICATE_ACCOUNT_MESSAGE_STRING error:nil];
        }
    }
    else
    {
        [self showAlertViewWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING error:nil];
    }
    return fields;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    //Delete Account because user went back to choose different account type
    if(!parent)
    {
        [OTRAccountsManager removeAccount:self.account];
    }
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RIButtonItem * okButtonItem = [RIButtonItem itemWithLabel:OK_STRING];
        UIAlertView * alertView = nil;
        if (error) {
            RIButtonItem * infoButton = [RIButtonItem itemWithLabel:INFO_STRING action:^{
                NSString * errorDescriptionString = [NSString stringWithFormat:@"%@ : %@",[error domain],[error localizedDescription]];
                
                if ([[error domain] isEqualToString:@"kCFStreamErrorDomainSSL"]) {
                    NSString * sslString = [OTRXMPPError errorStringWithSSLStatus:(OSStatus)error.code];
                    if ([sslString length]) {
                        errorDescriptionString = [errorDescriptionString stringByAppendingFormat:@"\n%@",sslString];
                    }
                }
                
                
                RIButtonItem * copyButtonItem = [RIButtonItem itemWithLabel:COPY_STRING action:^{
                    NSString * copyString = [NSString stringWithFormat:@"Domain: %@\nCode: %ld\nUserInfo: %@",[error domain],(long)[error code],[error userInfo]];
                    
                    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                    [pasteBoard setString:copyString];
                }];
                
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:INFO_STRING
                                                                 message:errorDescriptionString
                                                        cancelButtonItem:nil
                                                        otherButtonItems:okButtonItem,copyButtonItem, nil];
                
                [alert show];
            }];
            alertView = [[UIAlertView alloc] initWithTitle:title
                                                   message:message
                                          cancelButtonItem:nil
                                          otherButtonItems:okButtonItem,infoButton, nil];
        }
        else {
            alertView = [[UIAlertView alloc] initWithTitle:title
                                                   message:message
                                          cancelButtonItem:nil
                                          otherButtonItems:okButtonItem, nil];
        }
        
        
        
        if (alertView) {
            [alertView show];
        }
    });
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [self.HUD removeFromSuperview];
}

+(OTRLoginViewController *)loginViewControllerWithAcccount:(OTRAccount *)account
{
    
    switch (account.accountType) {
        case OTRAccountTypeXMPPTor:
        case OTRAccountTypeJabber:
            return [[OTRJabberLoginViewController alloc] initWithAccount:account];
        case OTRAccountTypeFacebook:
            return [[OTRFacebookLoginViewController alloc] initWithAccount:account];
        case OTRAccountTypeGoogleTalk:
            return [[OTRGoogleTalkLoginViewController alloc] initWithAccount:account];
        default:
            return nil;
    }
}

@end
