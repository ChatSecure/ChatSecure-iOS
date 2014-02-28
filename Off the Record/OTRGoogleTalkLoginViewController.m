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
#import "OTRManagedGoogleAccount.h"
#import "OTRSecrets.h"

@interface OTRGoogleTalkLoginViewController ()

@property (nonatomic,strong) OTRManagedGoogleAccount * account;

@end

@implementation OTRGoogleTalkLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.connectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    UIEdgeInsets imageInsets = UIEdgeInsetsMake(10.0, 37.0, 10.0, 10.0);
    
    UIImage *buttonImage = [[UIImage imageNamed:@"googleTalkButton"] resizableImageWithCapInsets:imageInsets];
    [self.connectButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    UIImage * pressedButtonImage = [[UIImage imageNamed:@"googleTalkButtonPressed"] resizableImageWithCapInsets:imageInsets];
    [self.connectButton setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
    
    
    [self.connectButton setTitle:@"Connect Google Talk" forState:UIControlStateNormal];
    [self.connectButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.connectButton addTarget:self action:@selector(connectAccount:) forControlEvents:UIControlEventTouchUpInside];
    
    self.disconnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.disconnectButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.disconnectButton setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
    [self.disconnectButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.disconnectButton setTitle:@"Disconnect Google Talk" forState:UIControlStateNormal];
    [self.disconnectButton addTarget:self action:@selector(disconnectAccount:) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)connectAccount:(id)sender
{
    GTMOAuth2ViewControllerTouch * oauthViewController = [GTMOAuth2ViewControllerTouch controllerWithScope:GOOGLE_APP_SCOPE clientID:GOOGLE_APP_ID clientSecret:kOTRGoogleAppSecret keychainItemName:nil completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        //[viewController dismissModalViewControllerAnimated:YES];
        if (!error) {
            [self.account setUsername:auth.userEmail];
            NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
            [context MR_saveToPersistentStoreAndWait];
            self.account.tokenDictionary = auth.parameters;
            [self.loginViewTableView reloadData];
            [self loginButtonPressed:sender];
        }
    }];
    [self.navigationController pushViewController:oauthViewController animated:YES];
}

@end
