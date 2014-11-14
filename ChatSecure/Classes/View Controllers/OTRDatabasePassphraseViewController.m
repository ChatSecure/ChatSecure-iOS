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
#import "UIAlertView+Blocks.h"
#import "OTRRememberPasswordView.h"
#import "Strings.h"
#import "PureLayout.h"

@interface OTRDatabasePassphraseViewController () <OTRPasswordStrengthViewDelegate>

@property (nonatomic, strong) OTRPasswordStrengthView *passwordView;
@property (nonatomic, strong) UIButton *nextStepButton;
@property (nonatomic, strong) OTRRememberPasswordView *rememberPasswordView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic) BOOL addedConstraints;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@property (nonatomic, strong) id UIKeyboardDidShowNotificationObject;

@end

@implementation OTRDatabasePassphraseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ////// ContainerView //////
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.userInteractionEnabled = YES;
    
    [self.view addSubview:self.containerView];
    
    ////// password view //////
    NSArray *rules = @[[NJOLengthRule ruleWithRange:NSMakeRange(kOTRMinimumPassphraseLength, kOTRMaximumPassphraseLength)]];
    self.passwordView = [[OTRPasswordStrengthView alloc] initWithRules:rules];
    self.passwordView.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordView.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordView.delegate = self;
    
    [self.containerView addSubview:self.passwordView];
    
    ////// Remmeber Password //////
    
    self.rememberPasswordView = [[OTRRememberPasswordView alloc] init];
    self.rememberPasswordView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.rememberPasswordView];
    
    ////// Next Step Button //////
    self.nextStepButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.nextStepButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextStepButton setTitle:NEXT_STRING forState:UIControlStateNormal];
    [self.nextStepButton addTarget:self action:@selector(nextTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.containerView addSubview:self.nextStepButton];
    
    self.addedConstraints = NO;
    
    self.nextStepButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.passwordView.textField becomeFirstResponder];
    
    __weak OTRDatabasePassphraseViewController *welf = self;
    self.UIKeyboardDidShowNotificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf keyboardDidShow:note];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self.UIKeyboardDidShowNotificationObject];
}

- (void) updateViewConstraints {
    
    if (!self.addedConstraints) {
        
        CGFloat margin = 8.0;
        
        [self.passwordView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(margin, margin, margin, margin) excludingEdge:ALEdgeBottom];
        
        [self.rememberPasswordView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:margin];
        [self.rememberPasswordView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:margin];
        [self.rememberPasswordView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.passwordView withOffset:margin*2];
        
        [self.nextStepButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.nextStepButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:margin];
        [self.nextStepButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.rememberPasswordView withOffset:0.0 relation:NSLayoutRelationGreaterThanOrEqual];
        
        [self.containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(70, 0, 0, 0) excludingEdge:ALEdgeBottom];
        self.bottomConstraint = [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0.0];
        
        self.addedConstraints = YES;
    }
    [super updateViewConstraints];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
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

- (void)nextTapped:(id)sender
{
    BOOL rememberPassword = self.rememberPasswordView.rememberPassword;
    NSError *error = nil;
    [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:self.passwordView.textField.text remember:rememberPassword error:&error];
    BOOL success = NO;
    if (!error) {
        success = [[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName];
    }
    
    if (error || !success) {
        [[[UIAlertView alloc] initWithTitle:ERROR_STRING message:DATABASE_SETUP_ERROR_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil] show];
    }
    
    [self.stepsController showNextStep];
}

#pragma - mark OTRPasswordStrengthViewDelegate Methods

- (void)passwordView:(OTRPasswordStrengthView *)view didChangePassword:(NSString *)password strength:(NJOPasswordStrength)strength failingRules:(NSArray *)rules
{
    if ([rules count] || ![password length]) {
        self.nextStepButton.enabled = NO;
    }
    else {
        self.nextStepButton.enabled = YES;
    }
    
}

@end
