//
//  OTRDemoChatViewController.m
//  Off the Record
//
//  Created by David on 10/21/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDemoChatViewController.h"

@interface OTRDemoChatViewController ()

@end

@implementation OTRDemoChatViewController

@synthesize lockVerifiedButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)refreshLockButton
{
    self.navigationItem.rightBarButtonItem = self.lockVerifiedButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[OTRManagedChatMessage newMessageFromBuddy:self.buddy message:@"Hello" encrypted:NO delayedDate:nil];
    [OTRManagedChatMessage newMessageToBuddy:self.buddy message:@"Bonjour" encrypted:NO];
    [OTRManagedChatMessage newMessageFromBuddy:self.buddy message:@"Hallo" encrypted:NO delayedDate:nil];
    [OTRManagedChatMessage newMessageToBuddy:self.buddy message:@"你好" encrypted:NO];
    [OTRManagedChatMessage newMessageFromBuddy:self.buddy message:@"привет" encrypted:NO delayedDate:nil];
    [OTRManagedChatMessage newMessageToBuddy:self.buddy message:@"Merhaba" encrypted:NO];
    [OTRManagedChatMessage newMessageFromBuddy:self.buddy message:@"مرحبا" encrypted:NO delayedDate:nil];
    [OTRManagedChatMessage newMessageToBuddy:self.buddy message:@"Olá" encrypted:NO];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
