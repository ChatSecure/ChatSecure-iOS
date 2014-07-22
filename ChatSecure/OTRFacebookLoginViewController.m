//
//  OTRFacebookLoginViewController.m
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

#import "OTRFacebookLoginViewController.h"
#import "Strings.h"
#import "OTRConstants.h"
#import "FacebookSDK.h"
#import "OTRDatabaseManager.h"
#import "FBLoginViewButtonPNG.h"
#import "FBLoginViewButtonPressedPNG.h"

@interface OTRFacebookLoginViewController ()

@property (nonatomic,strong)  OTRFacebookOAuthXMPPAccount *account;

@end

@implementation OTRFacebookLoginViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [FBSettings setDefaultAppID:FACEBOOK_APP_ID];
    self.connectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.connectButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.connectButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIEdgeInsets imageInsets = UIEdgeInsetsMake(4.0, 40.0, 4.0, 4.0);
    
    UIImage *buttonImage = [[FBLoginViewButtonPNG image] resizableImageWithCapInsets:imageInsets];
    [self.connectButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    UIImage * pressedButtonImage = [[FBLoginViewButtonPressedPNG image] resizableImageWithCapInsets:imageInsets];
    [self.connectButton setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
    
    self.disconnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.disconnectButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.disconnectButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.disconnectButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.disconnectButton setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
    
    [self.disconnectButton setTitle:DISCONNECT_FACEBOOK_STRING forState:UIControlStateNormal];
    [self.disconnectButton addTarget:self action:@selector(disconnectAccount:) forControlEvents:UIControlEventTouchUpInside];

    [self.connectButton setTitle:CONNECT_FACEBOOK_STRING forState:UIControlStateNormal];
    [self.connectButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)connectAccount:(id)sender
{
    if ([FBSession activeSession].isOpen) {
        [self requestMe:[FBSession activeSession] sender:sender];
    }
    else {
        [[FBSession activeSession] openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if ([session isOpen]) {
                [self requestMe:session sender:sender];
            }
        }];
    }
}

- (void)requestMe:(FBSession *)session sender:(id)sender
{
    FBRequest * request = [[FBRequest alloc] initWithSession:session graphPath:@"me"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
        if (!error) {
            [self didConnectUser:user];
            if(![self isDuplicateUsername:self.account.username])
            {
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [self.account saveWithTransaction:transaction];
                }];
                self.account.oAuthTokenDictionary = [session.accessTokenData dictionary];
                [self.loginViewTableView reloadData];
                [self loginButtonPressed:sender];
            }
            else {
                [self showAlertViewWithTitle:DUPLICATE_ACCOUNT_STRING message:DUPLICATE_ACCOUNT_MESSAGE_STRING error:nil];
            }
            
        }
    }];
}

-(void)didConnectUser:(id<FBGraphUser>)user
{
    if ([user.name length]) {
        self.account.displayName = user.name;
    }
    else if ([user.username length]) {
        self.account.displayName =  user.username;
    }
    
    self.account.username = [NSString stringWithFormat:@"-%@@%@",user.objectID,kOTRFacebookDomain];
}

@end
