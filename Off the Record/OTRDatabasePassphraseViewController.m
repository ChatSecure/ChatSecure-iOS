//
//  OTRDatabasePassphraseViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabasePassphraseViewController.h"
#import "OTRPasswordStrengthView.h"
#import "RMStepsController.h"
#import "Strings.h"
#import "OTRDatabaseManager.h"
#import "OTRConstants.h"

@interface OTRDatabasePassphraseViewController () <OTRPasswordStrengthViewDelegate>

@property (nonatomic, strong) OTRPasswordStrengthView *passwordView;
@property (nonatomic, strong) UIButton *nextStepButton;
@property (nonatomic, strong) UILabel *rememberPasswordLabel;
@property (nonatomic, strong) UISwitch *rememberPasswordSwitch;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation OTRDatabasePassphraseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ////// ContainerView //////
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.userInteractionEnabled = YES;
    
    [self.view addSubview:containerView];
    
    ////// password view //////
    self.passwordView = [[OTRPasswordStrengthView alloc] initWithDefaultRules];
    self.passwordView.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordView.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordView.delegate = self;
    
    [containerView addSubview:self.passwordView];
    
    ////// Remmeber Password //////
    
    self.rememberPasswordLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.rememberPasswordLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rememberPasswordLabel.text = REMEMBER_PASSWORD_STRING;
    
    self.rememberPasswordSwitch = [[UISwitch alloc] init];
    self.rememberPasswordSwitch.on = YES;
    self.rememberPasswordSwitch.userInteractionEnabled = YES;
    self.rememberPasswordSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rememberPasswordSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    
    UIView *rememberPasswordView = [[UIView alloc] initWithFrame:CGRectZero];
    rememberPasswordView.translatesAutoresizingMaskIntoConstraints = NO;
    rememberPasswordView.userInteractionEnabled = YES;
    
    [rememberPasswordView addSubview:self.rememberPasswordSwitch];
    [rememberPasswordView addSubview:self.rememberPasswordLabel];
    [containerView addSubview:rememberPasswordView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_rememberPasswordLabel,_rememberPasswordSwitch);
    [rememberPasswordView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_rememberPasswordLabel]->=0-[_rememberPasswordSwitch]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
    
    
    ////// Next Step Button //////
    self.nextStepButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.nextStepButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextStepButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.nextStepButton addTarget:self action:@selector(nextTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [containerView addSubview:self.nextStepButton];
    
    views = NSDictionaryOfVariableBindings(_passwordView,_nextStepButton,containerView,rememberPasswordView);
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_passwordView]-|" options:0 metrics:nil views:views]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_nextStepButton]-|" options:0 metrics:nil views:views]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[rememberPasswordView]-|" options:0 metrics:nil views:views]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_passwordView]-5-[rememberPasswordView]->=0-[_nextStepButton]-|" options:0 metrics:nil views:views]];
    
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[containerView]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.bottomConstraint];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self keyboardDidShow:note];
    }];
    
    self.nextStepButton.enabled = NO;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.passwordView.textField becomeFirstResponder];
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

- (void)switchChanged:(id)sender
{
    
}

- (void)nextTapped:(id)sender
{
    NSError *error = [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:self.passwordView.textField.text remember:NO];
    BOOL success = NO;
    if (!error) {
        success = [[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName];
    }
    
    if (error || success) {
        //error message
    }
    
    
    [self.stepsController showNextStep];
}

#pragma - mark OTRPasswordStrengthViewDelegate Methods

- (void)passwordView:(OTRPasswordStrengthView *)view didChangePassword:(NSString *)password strength:(NJOPasswordStrength)strength failingRules:(NSArray *)rules
{
    if ([rules count]) {
        self.nextStepButton.enabled = NO;
    }
    else {
        self.nextStepButton.enabled = YES;
    }
    
}

@end
