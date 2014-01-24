//
//  OTRXMPPOAUTHLoginViewController.m
//  Off the Record
//
//  Created by David on 9/13/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPOAUTHLoginViewController.h"

#import "OTRLog.h"

@interface OTRXMPPOAUTHLoginViewController ()

@end

@implementation OTRXMPPOAUTHLoginViewController

@synthesize connectButton,disconnectButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addCellinfoWithSection:0 row:0 labelText:LOGIN_AUTOMATICALLY_STRING cellType:kCellTypeSwitch userInputView:self.autoLoginSwitch];

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        if ([self.account.accessTokenString length] && ([self.account.username length] || [self.account.displayName length])) {
            return 2;
        }
        return 1;
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
        CGRect buttonFrame = CGRectMake(8, 8, tableView.frame.size.width-16, 45);
        UIButton * button = nil;
        
        if ([self.account.password length] && ([self.account.username length] || [self.account.displayName length])) {
            //disconnect button
            self.disconnectButton.frame = buttonFrame;
            button = self.disconnectButton;
        }
        else {
            //connect button
            self.connectButton.frame = buttonFrame;
            button = self.connectButton;
        }
        
        if (button) {
            button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [view addSubview:button];
        }
        
    }
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    if (indexPath.section == 0 && indexPath.row == 0 && [self.account.accessTokenString length] && [self.account.username length]) {
        if ([self.account.accessTokenString length] && [self.account.username length]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
            cell.textLabel.text = USERNAME_STRING;
            cell.detailTextLabel.text = self.account.username;
            if ([self.account.displayName length]) {
                cell.detailTextLabel.text = self.account.displayName;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else {
        cell = [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //[self loginButtonPressed:[tableView cellForRowAtIndexPath:indexPath]];
}

-(void)readInFields
{
    self.account.autologinValue = self.autoLoginSwitch.on;
    self.account.rememberPasswordValue = YES;
}

-(void)disconnectAccount:(id)sender {
    [self.account setPassword:nil];
    [self.loginViewTableView reloadData];
}

-(void)loginButtonPressed:(id)sender
{
    [self readInFields];
    [self.account refreshTokenIfNeeded:^(NSError * error) {
        if (!error) {
            if ([self.account.accessTokenString length]) {
                [self showHUDWithText:LOGGING_IN_STRING];
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
                [protocol connectWithPassword:self.account.accessTokenString];
                self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
            }
            else {
                [self connectAccount:sender];
            }
        }
    }];
    
    
}


-(void)connectAccount:(id)sender {
    DDLogError(@"Needs to be implemented in sublcasses");
}


@end
