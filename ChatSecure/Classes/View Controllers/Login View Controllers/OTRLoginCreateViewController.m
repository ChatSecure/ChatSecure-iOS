//
//  OTRLoginCreateViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/7/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRLoginCreateViewController.h"
#import "JVFloatLabeledTextField.h"
#import "Strings.h"
#import "OTRLoginCreateTableViewDataSource.h"

@implementation OTRLoginCellInfo

@end

@interface OTRLoginCreateViewController ()

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) OTRLoginCreateTableViewDataSource *tableViewDataSource;

@property (nonatomic, strong) UISwitch *rememberPasswordSwitch;
@property (nonatomic, strong) UISwitch * autoLoginSwitch;
@property (nonatomic, strong) JVFloatLabeledTextField *usernameTextField;
@property (nonatomic, strong) JVFloatLabeledTextField *passwordTextField;
@property (nonatomic, strong) JVFloatLabeledTextField *hostnameTextField;
@property (nonatomic, strong) JVFloatLabeledTextField *portTextField;
@property (nonatomic, strong) JVFloatLabeledTextField *resourceTextField;

@end

@implementation OTRLoginCreateViewController

@end
