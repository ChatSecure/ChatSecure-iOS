//
//  OTRDatabaseUnlockViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseUnlockViewController.h"
#import "OTRDatabaseManager.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"

@interface OTRDatabaseUnlockViewController ()

@property (nonatomic, strong) UITextField *passphraseTextField;
@property (nonatomic, strong) UIButton *unlockButton;

@property (nonatomic, strong) NSLayoutConstraint *textFieldCenterXConstraint;

@end

@implementation OTRDatabaseUnlockViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.passphraseTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.passphraseTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passphraseTextField.secureTextEntry = YES;
    self.passphraseTextField.borderStyle = UITextBorderStyleRoundedRect;
    
    [self.view addSubview:self.passphraseTextField];
    
    self.unlockButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.unlockButton setTitle:@"Unlock" forState:UIControlStateNormal];
    [self.unlockButton addTarget:self action:@selector(unlockTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.unlockButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.unlockButton];
    
    [self setupConstraints];
}

- (void)setupConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_unlockButton,_passphraseTextField);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_unlockButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(100)-[_passphraseTextField]-[_unlockButton]" options:0 metrics:nil views:views]];
    
    
    self.textFieldCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.passphraseTextField attribute:NSLayoutAttributeCenterX relatedBy:self.view toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.textFieldCenterXConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.passphraseTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.unlockButton attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
}

- (void)unlockTapped:(id)sender
{
    [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:self.passphraseTextField.text remember:NO];
    
    if ([[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName]) {
        [OTRAppDelegate showConversationViewController];
    }
    else {
        [self shake:sender number:10 direction:1];
    }
    
}

-(void)shake:(UIView *)view number:(int)shakes direction:(int)direction
{
    if (shakes > 0) {
        self.textFieldCenterXConstraint.constant = 5*direction;
    }
    else {
        self.textFieldCenterXConstraint.constant = 0.0;
    }
    
    
    [UIView animateWithDuration:0.03 animations:^ {
        [self.view layoutIfNeeded];
    }
                     completion:^(BOOL finished)
    {
         if(shakes > 0)
         {
             [self shake:view number:shakes-1 direction:direction *-1];
         }
        
     }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.passphraseTextField becomeFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
