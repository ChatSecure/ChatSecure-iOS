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
#import "Strings.h"

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
    NSMutableArray *steps = [NSMutableArray array];
    OTRDatabasePassphraseViewController *databasePassphraseViewController = [[OTRDatabasePassphraseViewController alloc] init];
    databasePassphraseViewController.step.title = NEW_PASSPHRASE_STRING;
    [steps addObject:databasePassphraseViewController];
    
#if CHATSECURE_PUSH
    OTROnboardingPushAccountLoginViewController *pushLoginViewController = [[OTROnboardingPushAccountLoginViewController alloc] init];
    pushLoginViewController.step.title = CHATSECURE_PUSH_STRING;
    [steps addObject:pushLoginViewController];
    OTRRemotePushRegistrationInfoViewController *pushRegistrationViewController = [[OTRRemotePushRegistrationInfoViewController alloc] init];
    pushRegistrationViewController.step.title = @"Push Registration";
    [steps addObject:pushRegistrationViewController];
#endif
    
    return steps;
}

- (void)finishedAllSteps {
    [[OTRAppDelegate appDelegate] showConversationViewController];
}

#pragma - mark RMStepsBarDelegate

- (void)stepsBar:(RMStepsBar *)bar shouldSelectStepAtIndex:(NSInteger)index
{
    return;
}


@end
