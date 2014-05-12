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

@interface OTRPushAccountLoginViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) BOOL createAccountMode;

@property (nonatomic, strong) OTRPushManager *pushManager;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSArray *emailConstraints;

@property (nonatomic, strong) NSDictionary *metrics;
@property (nonatomic, strong) NSDictionary *views;

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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.contentView];
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.placeholder = USERNAME_STRING;
    self.usernameTextField.delegate = self;
    self.usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.usernameTextField];
    
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.placeholder = EMAIL_STRING;
    self.emailTextField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.emailTextField];
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.placeholder = PASSWORD_STRING;
    self.passwordTextField.delegate = self;
    self.passwordTextField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.passwordTextField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.loginButton.enabled = NO;
    //self.loginButton.frame = CGRectMake(0, 0, self.view.bounds.size.height-10, loginButtonHeight);
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.loginButton];
    
    
    self.switchCreateOrLogin = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.switchCreateOrLogin addTarget:self action:@selector(switchCreateAccountMode:) forControlEvents:UIControlEventTouchUpInside];
    self.switchCreateOrLogin.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.switchCreateOrLogin];
    
    self.createAccountMode = YES;
    [self setupConstraints];
}

- (void)setupConstraints
{
    self.views = NSDictionaryOfVariableBindings(_contentView,_usernameTextField,_emailTextField,_passwordTextField,_loginButton,_switchCreateOrLogin);
    self.metrics = @{@"margin":@(12)};
    
    ////// ScrollView //////
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView]|" options:0 metrics:0 views:self.views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]
    ;
    [self.view addConstraint:self.bottomConstraint];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_usernameTextField]-|" options:0 metrics:0 views:self.views]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_passwordTextField]-|" options:0 metrics:0 views:self.views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_loginButton]-|" options:0 metrics:0 views:self.views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_switchCreateOrLogin]-|" options:0 metrics:0 views:self.views]];
    
    [self addEmailTextFieldAnimated:NO];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self keyboardDidShow:note];
    }];
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

- (void)addEmailTextFieldAnimated:(BOOL)animated
{
    NSMutableArray *mutableEmailTextFieldConstraints = [NSMutableArray array];
    
    if ([self.emailConstraints count]) {
        [self.view removeConstraints:self.emailConstraints];
    }
    
    [self.view addSubview:self.emailTextField];
    
    [mutableEmailTextFieldConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_emailTextField]-|" options:0 metrics:0 views:self.views]];
    
    [mutableEmailTextFieldConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-70-[_usernameTextField]-(margin)-[_emailTextField]-(margin)-[_passwordTextField]-(margin)-[_loginButton]-(margin)-[_switchCreateOrLogin]->=0-|" options:0 metrics:self.metrics views:self.views]];
    
    self.emailConstraints = [mutableEmailTextFieldConstraints copy];
    [self.view addConstraints:self.emailConstraints];
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)removeEmailTextFieldAnimated:(BOOL)animated
{
    [self.emailTextField removeFromSuperview];
    
    if (self.emailConstraints) {
        [self.view removeConstraints:self.emailConstraints];
    }
    
    self.emailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-70-[_usernameTextField]-(margin)-[_passwordTextField]-(margin)-[_loginButton]-(margin)-[_switchCreateOrLogin]->=0-|" options:0 metrics:self.metrics views:self.views];
    
    [self.view addConstraints:self.emailConstraints];
    NSTimeInterval duration = 0.3;
    if (!animated) {
        duration = 0.0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)shownPushRegistrationViewController
{
    OTRRemotePushRegistrationInfoViewController *viewController = [[OTRRemotePushRegistrationInfoViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}
     
- (void)switchCreateAccountMode:(id)sender
{
    self.createAccountMode = !self.createAccountMode;
}

- (void)setCreateAccountMode:(BOOL)createAccountMode
{
    _createAccountMode = createAccountMode;
    if (_createAccountMode) {
        [self.loginButton setTitle:@"Sign Up" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Sign Up" forState:UIControlStateDisabled];
        [self.switchCreateOrLogin setTitle:@"Already have an account" forState:UIControlStateNormal];
        
    }
    else {
        [self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Sign In" forState:UIControlStateDisabled];
        [self.switchCreateOrLogin setTitle:@"Create account" forState:UIControlStateNormal];
    }
    
    if (!self.createAccountMode) {
        [self removeEmailTextFieldAnimated:YES];
    }
    else {
        [self addEmailTextFieldAnimated:YES];
    }
    
    [UIView animateKeyframesWithDuration:.5 delay:0.0 options:0 animations:^{
        [self.contentView layoutIfNeeded];
    } completion:nil];
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

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSValue *beginFrameValue = notification.userInfo[UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardBeginFrame = [self.view convertRect:beginFrameValue.CGRectValue fromView:nil];
    
    NSValue *endFrameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardEndFrame = [self.view convertRect:endFrameValue.CGRectValue fromView:nil];
    
    
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    self.bottomConstraint.constant = keyboardEndFrame.size.height * -1;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
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
