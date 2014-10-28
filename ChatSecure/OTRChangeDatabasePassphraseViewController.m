//
//  OTRChangeDatabasePassphraseViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/6/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRChangeDatabasePassphraseViewController.h"
#import "OTRPasswordStrengthView.h"
#import "OTRRememberPasswordView.h"
#import "Strings.h"
#import "PureLayout.h"
#import "OTRDatabaseManager.h"
#import "MBProgressHUD.h"

@interface OTRChangeDatabasePassphraseViewController () <OTRPasswordStrengthViewDelegate>

@property (nonatomic, strong) OTRPasswordStrengthView *passwordView;
@property (nonatomic, strong) UITextField *oldPasswordTextField;
@property (nonatomic, strong) OTRRememberPasswordView *rememberPasswordView;
@property (nonatomic, strong) UIButton *changePasswordButton;
@property (nonatomic) BOOL addedConstraints;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation OTRChangeDatabasePassphraseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ////// New Passowrd View //////
    
    self.passwordView = [[OTRPasswordStrengthView alloc] initWithDefaultRules];
    self.passwordView.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordView.delegate = self;
    self.passwordView.textField.placeholder = NEW_PASSPHRASE_STRING;
    
    [self.view addSubview:self.passwordView];
    
    ////// Old Password TextField //////
    self.oldPasswordTextField = [[UITextField alloc] init];
    self.oldPasswordTextField.secureTextEntry = YES;
    self.oldPasswordTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.oldPasswordTextField.placeholder = CURRENT_PASSPHRASE_STRING;
    
    [self.view addSubview:self.oldPasswordTextField];
    
    ////// changePassword Button //////
    
    self.changePasswordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.changePasswordButton setTitle:CHANGE_PASSPHRASE_STRING forState:UIControlStateNormal];
    [self.changePasswordButton addTarget:self action:@selector(changePasswordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.changePasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.changePasswordButton];
    
    ////// Remember Password View //////
    
    self.rememberPasswordView = [[OTRRememberPasswordView alloc] init];
    self.rememberPasswordView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.rememberPasswordView];
    
    self.addedConstraints = NO;
    
    self.changePasswordButton.enabled = NO;
    [self.oldPasswordTextField becomeFirstResponder];
    
    [self.view updateConstraintsIfNeeded];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.addedConstraints) {
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_passwordView,_oldPasswordTextField,_changePasswordButton,_rememberPasswordView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_passwordView]-|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_oldPasswordTextField]-|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_changePasswordButton]-|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_rememberPasswordView]-|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(70)-[_oldPasswordTextField]-[_passwordView]-[_rememberPasswordView]-[_changePasswordButton]" options:0 metrics:nil views:views]];
        self.addedConstraints = YES;
    }
    
}

- (void)passwordView:(OTRPasswordStrengthView *)view didChangePassword:(NSString *)password strength:(NJOPasswordStrength)strength failingRules:(NSArray *)rules
{
    if ([rules count]) {
        self.changePasswordButton.enabled = NO;
    }
    else {
        self.changePasswordButton.enabled = YES;
    }
}

- (void) changePasswordButtonPressed: (id)sender {
    NSString *password = self.passwordView.textField.text;
    NSAssert(password.length != 0, @"Password must have a length!");
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    BOOL success = [[OTRDatabaseManager sharedInstance].database changeEncryptionKey:password];
    if (!success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:DATABASE_PASSPHRASE_CHANGE_ERROR_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
        [alert show];
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

@end
