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

#define kTextLabelTextKey @"textLabelTextKey"
#define kCellTypeKey @"cellTypeKey"
#define kUserInputViewKey @"userInputViewKey"
#define kCellTypeTextField @"cellTypeTextField"
#define kCellTypeSwitch @"cellTypeSwitch"
#define KCellTypeHelp @"cellTypeHelp"

@interface OTRLoginViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate, UIActionSheetDelegate, UITableViewDataSource,UITableViewDelegate> {
    MBProgressHUD *HUD;
    UIView *padding;
}

- (id) initWithAccountID:(NSManagedObjectID *)newAccountID;

@property (nonatomic, retain) OTRManagedAccount *account;

@property (nonatomic, retain) UISwitch *rememberPasswordSwitch;
@property (nonatomic, retain) UIImageView *logoView;
@property (nonatomic, retain) UITextField *usernameTextField;
@property (nonatomic, retain) UITextField *passwordTextField;

@property (nonatomic, retain) UIBarButtonItem *loginButton;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) NSTimer * timeoutTimer;

@property (nonatomic, strong) NSMutableArray * tableViewArray;

@property (nonatomic, strong) UITableView * loginViewTableView;
@property (nonatomic, strong) UIColor * textFieldTextColor;

@property (nonatomic) BOOL isNewAccount;

- (void)loginButtonPressed:(id)sender;
- (void)cancelPressed:(id)sender;

-(BOOL)checkFields;

-(void)addCellinfoWithSection:(NSInteger)section row:(NSInteger)row labelText:(id)text cellType:(NSString *)type userInputView:(UIView *)inputView;
-(void)readInFields;

+(OTRLoginViewController *)loginViewControllerWithAcccountID:(NSManagedObjectID *)accountID;

@end
