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
#import "Strings.h"
#import "OTRConstants.h"

extern NSString *const kTextLabelTextKey;
extern NSString *const kCellTypeKey;
extern NSString *const kUserInputViewKey;
extern NSString *const kCellTypeTextField;
extern NSString *const kCellTypeSwitch;
extern NSString *const KCellTypeHelp;

extern NSUInteger const kErrorAlertViewTag;
extern NSUInteger const kErrorInfoAlertViewTag;
extern NSUInteger const kNewCertAlertViewTag;

@interface OTRLoginViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UITableViewDataSource,UITableViewDelegate, UIAlertViewDelegate> {
    UIView *padding;
}

- (id) initWithAccountID:(NSManagedObjectID *)newAccountID;

@property (nonatomic, strong) OTRManagedAccount *account;
@property (nonatomic, strong) MBProgressHUD * HUD;
@property (nonatomic, strong) NSError * recentError;

@property (nonatomic, strong) UISwitch *rememberPasswordSwitch;
@property (nonatomic, strong) UISwitch * autoLoginSwitch;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;

@property (nonatomic, strong) UIBarButtonItem *loginButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) NSTimer * timeoutTimer;

@property (nonatomic, strong) NSMutableArray * tableViewArray;

@property (nonatomic, strong) UITableView * loginViewTableView;
@property (nonatomic, strong) UIColor * textFieldTextColor;

@property (nonatomic) BOOL isNewAccount;

- (void)loginButtonPressed:(id)sender;
- (void)cancelPressed:(id)sender;

- (BOOL)checkFields;
- (void)showHUDWithText:(NSString *)text;

- (void)setupFields;

- (void)addCellinfoWithSection:(NSInteger)section
                           row:(NSInteger)row
                     labelText:(id)text
                      cellType:(NSString *)type
                 userInputView:(UIView *)inputView;

- (void)readInFields;
- (void)hideHUD;

- (void)protocolLoginFailed:(NSNotification*)notification;
- (void)protocolLoginSuccess:(NSNotification*)notification;

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message error:(NSError *)error;

+(OTRLoginViewController *)loginViewControllerWithAcccountID:(NSManagedObjectID *)accountID;

@end
