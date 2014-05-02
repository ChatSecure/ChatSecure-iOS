//
//  OTRPushAccountLoginViewController.m
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushAccountLoginViewController.h"
#import "OTRPushManager.h"
#import "OTRTextFieldTableViewCell.h"
#import "Strings.h"
#import "OTRLog.h"
#import "UIAlertView+Blocks.h"
#import "OTRProtocolManager.h"
#import "OTRRemotePushRegistrationInfoViewController.h"

NSString *const OTRTextFieldTableViewCellIdentifier =  @"OTRTextFieldTableViewCellIdentifier";
NSString *const OTRDefaultTableViewCellIdentifier = @"OTRDefaultTableViewCellIdentifier";

CGFloat loginButtonHeight = 44;
int minPasswordLength = 4;
int maxPasswordLength = 100;
int maxUsernameLength = 30;
int maxEmailLength = 100;

@interface OTRPushAccountLoginViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;

@property (nonatomic) BOOL createAccountMode;

@property (nonatomic, strong) OTRPushManager *pushManager;

@end

@implementation OTRPushAccountLoginViewController

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
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.tableView registerClass:[OTRTextFieldTableViewCell class] forCellReuseIdentifier:OTRTextFieldTableViewCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:OTRDefaultTableViewCellIdentifier];
    
    [self.view addSubview:self.tableView];
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.placeholder = USERNAME_STRING;
    self.usernameTextField.delegate = self;
    
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.placeholder = EMAIL_STRING;
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.placeholder = PASSWORD_STRING;
    self.passwordTextField.delegate = self;
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.loginButton.enabled = NO;
    self.loginButton.frame = CGRectMake(0, 0, self.view.bounds.size.height-10, loginButtonHeight);
    
    self.createAccountMode = YES;
}

- (void)loginButtonPressed:(id)sender
{
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = self.passwordTextField.text;
    
    if (self.createAccountMode) {
        if (![self validEmail:email]) {
            [self showErrorTitle:@"Invalid Email" descritpion:@"Please choose a valid email address"];
            [self.emailTextField becomeFirstResponder];
        }
        else {
            [self.pushManager createNewAccountWithUsername:username password:password emial:email completion:^(BOOL success, NSError *error) {
                if (error) {
                    DDLogError(@"Error Creating Account: %@",error);
                    [self showErrorTitle:@"Error Creating Account" descritpion:error.localizedDescription];
                }
                else {
                    [self shownPushRegistrationViewController];
                }
            }];
        }
        
        
    }
    else {
        [self.pushManager loginWithUsername:username password:password completion:^(BOOL success, NSError *error) {
            if (error) {
                DDLogError(@"Error Loggin in: %@",error);
                [self showErrorTitle:@"Error" descritpion:error.description];
            }
            else {
                [self shownPushRegistrationViewController];
            }
        }];
    }
}

- (void)shownPushRegistrationViewController
{
    OTRRemotePushRegistrationInfoViewController *viewController = [[OTRRemotePushRegistrationInfoViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)setCreateAccountMode:(BOOL)createAccountMode
{
    _createAccountMode = createAccountMode;
    if (_createAccountMode) {
        [self.loginButton setTitle:@"Sign Up" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Sign Up" forState:UIControlStateDisabled];
    }
    else {
        [self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Sign In" forState:UIControlStateDisabled];
    }
    [self.tableView reloadData];
}

- (BOOL)validUsername:(NSString *)string
{
    if ([string length] && [string length] <= maxUsernameLength) {
        return YES;
    }
    return NO;
}

- (BOOL)validPassword:(NSString *)string
{
    if ([string length] <= maxPasswordLength && [string length] > 4) {
        return YES;
    }
    return NO;
}

- (BOOL)validEmail:(NSString *)string
{
    string = [self stripWhiteSpace:string];
    if ([string length] > maxEmailLength) {
        return NO;
    }
    
    if ([string length]) {
        if ([string rangeOfString:@"@"].location == NSNotFound) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)stripWhiteSpace:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)showErrorTitle:(NSString *)title descritpion:(NSString *)description
{
    RIButtonItem *okButotn = [RIButtonItem itemWithLabel:OK_STRING];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:description cancelButtonItem:nil otherButtonItems:okButotn, nil];
    [alertView show];
}

// password strength meter

#pragma - mark UITableViewDataSource Methods

////// Required //////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        if (self.createAccountMode) {
            //username
            //email
            //password
            return 3;
        }
        else {
            //username
            //password
            return 2;
        }
    }
    else {
        //cell for switching between types
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        OTRTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OTRTextFieldTableViewCellIdentifier forIndexPath:indexPath];
        if (indexPath.row == 0) {
            cell.textField = self.usernameTextField;
        }
        else if (self.createAccountMode && indexPath.row == 1) {
            cell.textField = self.emailTextField;
            
        }
        else {
            cell.textField = self.passwordTextField;
        }
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OTRDefaultTableViewCellIdentifier forIndexPath:indexPath];
        if (self.createAccountMode) {
            cell.textLabel.text = @"Login?";
        }
        else {
            cell.textLabel.text = @"Create Account?";
        }
        
        return cell;
    }
    
}

////// Optional //////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return self.loginButton;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return loginButtonHeight;
    }
    return 0;
}


#pragma - mark UITableViewDelegate Methods

////// Optional //////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        self.createAccountMode = !self.createAccountMode;
    }
}

#pragma - mark UITextFieldDelegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *passwordString = nil;
    NSString *usernameString = nil;
    
    if ([textField isEqual:self.usernameTextField]) {
        usernameString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        passwordString = self.passwordTextField.text;
    }
    else if ([textField isEqual:self.passwordTextField]) {
        passwordString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        usernameString = self.usernameTextField.text;
    }
    
    if ([self validPassword:passwordString] && [self validUsername:usernameString]) {
        self.loginButton.enabled = YES;
    }
    else {
        self.loginButton.enabled = NO;
    }
    
    
    return YES;
}

@end
