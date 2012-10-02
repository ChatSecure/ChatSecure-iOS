//
//  OTRXMPPLoginViewController.h
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLoginViewController.h"

@interface OTRXMPPLoginViewController : OTRLoginViewController

@property (nonatomic, strong) UITextField *domainTextField;
@property (nonatomic, strong) UISwitch *sslMismatchSwitch;
@property (nonatomic, strong) UISwitch *selfSignedSwitch;
@property (nonatomic, strong) UITextField *portTextField;

@end
