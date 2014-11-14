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
#import "OTRDatabaseManager.h"

@interface OTRChangeDatabasePassphraseViewController () <OTRPasswordStrengthViewDelegate>

@property (nonatomic, strong) OTRPasswordStrengthView *passwordView;
@property (nonatomic, strong) UITextField *oldPassphraseTextField;
@property (nonatomic, strong) OTRRememberPasswordView *rememberPasswordView;
@property (nonatomic, strong) UIButton *changePasswordButton;
@property (nonatomic) BOOL addedConstraints;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic) BOOL requireOldPassphrase;

@end

@implementation OTRChangeDatabasePassphraseViewController

- (instancetype)initRequireOldPassphrase:(BOOL)requireOldPassphrase
{
    if(self = [self init]) {
        self.requireOldPassphrase = requireOldPassphrase;
    }
    return self;
}

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
    if (self.requireOldPassphrase) {
        self.oldPassphraseTextField = [[UITextField alloc] init];
        self.oldPassphraseTextField.secureTextEntry = YES;
        self.oldPassphraseTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.oldPassphraseTextField.placeholder = CURRENT_PASSPHRASE_STRING;
        
        [self.view addSubview:self.oldPassphraseTextField];
    }
    
    
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
    [self.oldPassphraseTextField becomeFirstResponder];
    
    [self.view updateConstraintsIfNeeded];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.addedConstraints) {
        
        CGFloat margin = 8;
        
        if(self.oldPassphraseTextField) {
            [self.oldPassphraseTextField autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:margin];
            [self.oldPassphraseTextField autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:margin];
            [self.oldPassphraseTextField autoPinToTopLayoutGuideOfViewController:self withInset:margin];
            
            [self.passwordView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.oldPassphraseTextField withOffset:margin];
        }
        else {
            [self.passwordView autoPinToTopLayoutGuideOfViewController:self withInset:margin];
        }
        
        [self.passwordView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:margin];
        [self.passwordView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:margin];
        
        [self.rememberPasswordView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:margin];
        [self.rememberPasswordView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:margin];
        
        [self.changePasswordButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:margin];
        [self.changePasswordButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:margin];
        
        [self.rememberPasswordView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.passwordView withOffset:margin];
        [self.changePasswordButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.rememberPasswordView withOffset:margin];
        
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
    if (password.length == 0) {
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    BOOL success = [[OTRDatabaseManager sharedInstance] changePassphrase:password remember:self.rememberPasswordView.rememberPassword];
    if (!success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:DATABASE_PASSPHRASE_CHANGE_ERROR_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:DATABASE_PASSPHRASE_CHANGE_SUCCESS_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
        [alert show];
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

@end
