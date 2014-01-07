//
//  OTRXMPPCreateViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateViewController.h"
#import "Strings.h"

@interface OTRXMPPCreateViewController ()

@end

@implementation OTRXMPPCreateViewController

- (id)initWithHostnames:(NSArray *)newHostnames
{
    self = [super init];
    if (self) {
        hostnameArray = newHostnames;
        self.selectedHostname = [hostnameArray firstObject];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Create Account";
	self.usernameTextField.placeholder = USERNAME_STRING;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    self.loginButton.title = @"Create";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([hostnameArray count]) {
        return [super numberOfSectionsInTableView:tableView]+1;
    }
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return [hostnameArray count];
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return HOSTNAME_STRING;
    }
    return BASIC_STRING;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return 44.0f;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const domainCellIdentifier = @"domainCellIdentifer";
    UITableViewCell * cell = nil;
    if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:domainCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:domainCellIdentifier];
        }
        NSString * hostName = hostnameArray[indexPath.row];
        cell.textLabel.text = hostName;
        if ([hostName isEqualToString:self.selectedHostname]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        self.selectedHostname = hostnameArray[indexPath.row];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void) loginButtonPressed:(id)sender
{
    id protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
    OTRXMPPManager * xmppManager = nil;
    if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
        self.account.username = self.usernameTextField.text;
        self.account.domain = self.selectedHostname;
        xmppManager = (OTRXMPPManager *)protocol;
        [xmppManager registerNewAccountWithPassword:self.passwordTextField.text];
    }
    
    
}

+ (instancetype)createViewControllerWithHostnames:(NSArray *)hostNames
{
    return [[self alloc] initWithHostnames:hostNames];
}

@end
