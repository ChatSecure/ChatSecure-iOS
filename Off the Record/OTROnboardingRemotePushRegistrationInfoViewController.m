//
//  OTROnboardingRemotePushRegistrationInfoViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROnboardingRemotePushRegistrationInfoViewController.h"
#import "OTROnboardingStepsController.h"

@interface OTROnboardingRemotePushRegistrationInfoViewController ()

@end

@implementation OTROnboardingRemotePushRegistrationInfoViewController

- (void)successfullRegistration:(NSNotification *)notification
{
    [self.stepsController showNextStep];
}

- (void)failedToRegister:(NSNotification *)notification
{
    [self.stepsController showNextStep];
}

@end
