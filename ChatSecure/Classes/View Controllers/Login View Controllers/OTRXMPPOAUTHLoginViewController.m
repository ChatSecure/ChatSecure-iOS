//
//  OTRXMPPOAUTHLoginViewController.m
//  Off the Record
//
//  Created by David on 9/13/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPOAUTHLoginViewController.h"
#import "OTROAuthXMPPAccount.h"
#import "OTRLog.h"
#import "OTROAuthRefresher.h"

@interface OTRXMPPOAUTHLoginViewController ()

@property (nonatomic,strong)  OTROAuthXMPPAccount *account;

@end

@implementation OTRXMPPOAUTHLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addCellinfoWithSection:0 row:0 labelText:LOGIN_AUTOMATICALLY_STRING cellType:kCellTypeSwitch userInputView:self.autoLoginSwitch];

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        if ([self.account.password length] && ([self.account.username length] || [self.account.displayName length])) {
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
    return 0;
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
    if (indexPath.section == 0 && indexPath.row == 0 && [self.account.password length] && [self.account.username length]) {
        if ([self.account.password length] && [self.account.username length]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
            cell.textLabel.text = USERNAME_STRING;
            cell.detailTextLabel.text = self.account.username;
            if ([self.account.displayName length]) {
                cell.detailTextLabel.text = self.account.displayName;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if(indexPath.section == 0) {
        cell = [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    else if (indexPath.section == 1) {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)readInFields
{
    self.account.autologin = self.autoLoginSwitch.on;
    self.account.rememberPassword = YES;
    if (self.resourceTextField.text.length) {
        self.account.resource = self.resourceTextField.text;
    }
    else {
        self.account.resource = [OTRXMPPAccount newResource];
    }
}

-(void)disconnectAccount:(id)sender {
    [self.account setPassword:nil];
    [self.loginViewTableView reloadData];
}

-(void)loginButtonPressed:(id)sender
{
    [self readInFields];
    
    [OTROAuthRefresher refreshAccount:self.account completion:^(id token, NSError *error) {
        if (!error) {
            self.account.accountSpecificToken = token;
            [self showHUDWithText:LOGGING_IN_STRING];
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
            [protocol connectWithPassword:self.account.password];
        } else {
            [self connectAccount:sender];
        }
    }];
}


-(void)connectAccount:(id)sender {
    DDLogError(@"Needs to be implemented in sublcasses");
}


@end
