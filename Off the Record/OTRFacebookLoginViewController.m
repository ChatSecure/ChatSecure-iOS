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
#import "OTRAppDelegate.h"
#import "OTRConstants.h"
#import <FacebookSDK/FacebookSDK.h>

@interface OTRFacebookLoginViewController ()

@end

@implementation OTRFacebookLoginViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [FBSettings setDefaultAppID:FACEBOOK_APP_ID];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        if ([self.account.password length] && [self.account.username length]) {
            return 1;
        }
        return 0;
    }
    
    return [super tableView:tableView numberOfRowsInSection:section];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 55;
    }
    
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView * view = [[UIView alloc] initWithFrame:CGRectZero];
    if (section == 0) {
        view.frame = CGRectMake(0, 0, tableView.frame.size.width, 55);
        UIButton * facebookButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        facebookButton.frame = CGRectMake(8, 8, tableView.frame.size.width-16, 45);
        
        if ([self.account.password length] && [self.account.username length]) {
            //disconnect button
            [facebookButton setTitle:@"Disconnect Facebook" forState:UIControlStateNormal];
            [facebookButton addTarget:self action:@selector(disconnectFacebook:) forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            [facebookButton setTitle:@"Connect Facebook" forState:UIControlStateNormal];
            [facebookButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
        }
        [view addSubview:facebookButton];
    }
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    if (indexPath.section == 0) {
        if ([self.account.password length] && [self.account.username length]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
            cell.textLabel.text = USERNAME_STRING;
            cell.detailTextLabel.text = self.account.username;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self loginButtonPressed:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        NSURL *url = [ [ NSURL alloc ] initWithString: kOTRFacebookUsernameLink ];
        [[UIApplication sharedApplication] openURL:url];
        
    }
}

-(void)disconnectFacebook:(id)sender {
    [self.account setPassword:nil];
    [self.loginViewTableView reloadData];
}

-(void)loginButtonPressed:(id)sender
{
    self.account.rememberPasswordValue = YES;
    if([self.account.password length])
    {
        [self showLoginProgress];
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol connectWithPassword:self.account.password];
    }
    else{
        //[FBSettings setDefaultAppID:FACEBOOK_APP_ID];
        FBSession * session = [[FBSession alloc] initWithAppID:FACEBOOK_APP_ID permissions:@[@"xmpp_login"] urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
        [FBSession setActiveSession:session];
        [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if ([session isOpen]) {
                
                NSLog(@"Session: %@",session);
                FBRequest * request = [[FBRequest alloc] initWithSession:session graphPath:@"me"];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                    if (!error) {
                        [self didConnectUser:user];
                        self.account.password = session.accessTokenData.accessToken;
                        [self.loginViewTableView reloadData];
                        [self showLoginProgress];
                        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
                        [context MR_saveOnlySelfAndWait];
                        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
                        [protocol connectWithPassword:self.account.password];
                    }
                }];
            }
        }];
    }
}

-(void)didConnectUser:(id<FBGraphUser>)user
{
    if ([user.username length]) {
        self.account.username =  user.username;
    }
    else {
        self.account.username =  user.name;
    }
    [self.loginViewTableView reloadData];
}

@end
