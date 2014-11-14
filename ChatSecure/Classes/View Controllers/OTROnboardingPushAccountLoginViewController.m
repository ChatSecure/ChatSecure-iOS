//
//  OTROnboardingPushAccountLoginViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROnboardingPushAccountLoginViewController.h"
#import "OTROnboardingStepsController.h"
#import "Strings.h"

@interface OTROnboardingPushAccountLoginViewController ()

@property (nonatomic, strong) UIButton *skipButton;

@end

@implementation OTROnboardingPushAccountLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.skipButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.skipButton setTitle:SKIP_STRING forState:UIControlStateNormal];
    [self.skipButton addTarget:self action:@selector(skipTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.skipButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_skipButton);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_skipButton]-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_skipButton]-|" options:0 metrics:nil views:views]];
    
}

- (void)skipTapped:(id)sender
{
    [self.stepsController finishedAllSteps];
}

- (void)loginSuccessful
{
    [self.stepsController showNextStep];
}

@end
