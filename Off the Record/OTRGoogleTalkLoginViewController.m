//
//  OTRGoogleTalkLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRGoogleTalkLoginViewController.h"
#import "Strings.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "OTRSecrets.h"
/*
#ifdef CRITTERCISM_ENABLED
#import "OTRSecrets.h"
#else
#define GOOGLE_APP_SECRET @"YOUR GOOGLE APP SECRET"
#endif
 */

@interface OTRGoogleTalkLoginViewController ()

@end

@implementation OTRGoogleTalkLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.connectButton setTitle:@"Connect Google Talk" forState:UIControlStateNormal];
    [self.connectButton addTarget:self action:@selector(connectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.disconnectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.disconnectButton setTitle:@"Disconnect Google Talk" forState:UIControlStateNormal];
    [self.disconnectButton addTarget:self action:@selector(disconnectButton:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)connectButtonPressed:(id)sender {
    GTMOAuth2ViewControllerTouch * oauthViewController = [GTMOAuth2ViewControllerTouch controllerWithScope:GOOGLE_APP_SCOPE clientID:GOOGLE_APP_ID clientSecret:GOOGLE_APP_SECRET keychainItemName:nil completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        //[viewController dismissModalViewControllerAnimated:YES];
        if (!error) {
            [self.account setUsername:auth.userEmail];
            [self.account setPassword:auth.accessToken];
            [self.loginViewTableView reloadData];
            [self showLoginProgress];
            NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
            [context MR_saveOnlySelfAndWait];
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
            [protocol connectWithPassword:self.account.password];
        }
    }];
    
    [self.navigationController pushViewController:oauthViewController animated:YES];
    
    
    
}

@end
