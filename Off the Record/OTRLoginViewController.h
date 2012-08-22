//
//  OTRLoginViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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

#import <UIKit/UIKit.h>
#import "OTRProtocolManager.h"
#import "MBProgressHUD.h"

@interface OTRLoginViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate, UIActionSheetDelegate> {
    MBProgressHUD *HUD;
    UIView *padding;
    UILabel *facebookHelpLabel;
}

- (id) initWithAccount:(OTRAccount*)newAccount;

@property (nonatomic, retain) OTRAccount *account;

@property (nonatomic, retain) UILabel *usernameLabel;
@property (nonatomic, retain) UILabel *passwordLabel;
@property (nonatomic, strong) UILabel *domainLabel;
@property (nonatomic, retain) UILabel *rememberPasswordLabel;
@property (nonatomic, retain) UISwitch *rememberPasswordSwitch;
@property (nonatomic, retain) UIImageView *logoView;
@property (nonatomic, retain) UITextField *usernameTextField;
@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *domainTextField;
@property (nonatomic, strong) UISegmentedControl *basicAdvancedSegmentedControl;
@property (nonatomic, strong) UILabel *sslMismatchLabel;
@property (nonatomic, strong) UISwitch *sslMismatchSwitch;
@property (nonatomic, strong) UILabel *selfSignedLabel;
@property (nonatomic, strong) UISwitch *selfSignedSwitch;

@property (nonatomic, strong) UIButton *facebookInfoButton;

@property (nonatomic, retain) UIBarButtonItem *loginButton;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) NSTimer * timeoutTimer;

@property (nonatomic) BOOL isNewAccount;

- (void)loginButtonPressed:(id)sender;
- (void)cancelPressed:(id)sender;

-(BOOL)checkFields;

@end
