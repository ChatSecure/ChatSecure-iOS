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
    OTROnboardingPushAccountLoginViewController *pushLoginViewController = [[OTROnboardingPushAccountLoginViewController alloc] init];
    OTRRemotePushRegistrationInfoViewController *pushRegistrationViewController = [[OTRRemotePushRegistrationInfoViewController alloc] init];
    
    return @[databasePassphraseViewController,pushLoginViewController,pushRegistrationViewController];
}

- (void)finishedAllSteps {
    [OTRAppDelegate showConversationViewController];
}


@end
