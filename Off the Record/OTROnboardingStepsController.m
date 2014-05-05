//
//  OTROnboardingStepsController.m
//  Off the Record
//
//  Created by David Chiles on 5/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROnboardingStepsController.h"
#import "OTRDatabasePassphraseViewController.h"
#import "OTROnboardingPushAccountLoginViewController.h"
#import "OTRRemotePushRegistrationInfoViewController.h"
#import "OTRAppDelegate.h"

@interface OTROnboardingStepsController ()

@end

@implementation OTROnboardingStepsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSArray *)stepViewControllers
{
    OTRDatabasePassphraseViewController *databasePassphraseViewController = [[OTRDatabasePassphraseViewController alloc] init];
    databasePassphraseViewController.step.title = @"Database Passphrase";
    OTROnboardingPushAccountLoginViewController *pushLoginViewController = [[OTROnboardingPushAccountLoginViewController alloc] init];
    pushLoginViewController.step.title = @"ChatSecure Push";
    OTRRemotePushRegistrationInfoViewController *pushRegistrationViewController = [[OTRRemotePushRegistrationInfoViewController alloc] init];
    pushRegistrationViewController.step.title = @"Push Registration";
    
    
    return @[databasePassphraseViewController,pushLoginViewController,pushRegistrationViewController];
}

- (void)finishedAllSteps {
    [OTRAppDelegate showConversationViewController];
}


@end
