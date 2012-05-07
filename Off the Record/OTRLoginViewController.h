//
//  OTRLoginViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRProtocolManager.h"
#import "MBProgressHUD.h"

@interface OTRLoginViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate> {
    UITextField *usernameTextField;
    UITextField *passwordTextField;
    
    OTRProtocolManager *protocolManager;
    MBProgressHUD *HUD;
}

@property (retain, nonatomic) UITextField *usernameTextField;
@property (retain, nonatomic) UITextField *passwordTextField;
@property (nonatomic, retain) OTRProtocolManager *protocolManager;
@property (retain, nonatomic) UISwitch *rememberUserNameSwitch;
@property (nonatomic) BOOL useXMPP;

@property (nonatomic, retain) UILabel *usernameLabel;
@property (nonatomic, retain) UILabel *passwordLabel;
@property (nonatomic, retain) UILabel *rememberUsernameLabel;
@property (nonatomic, retain) UIImageView *logoView;

@property (nonatomic, retain) UIBarButtonItem *loginButton;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;


- (void)loginPressed:(id)sender;
- (void)xmppLoginPressed:(id)sender;
- (void)cancelPressed:(id)sender;

-(void)aimLoginFailed;
-(void)xmppLoginFailed;
-(void)xmppLoginSuccess;
-(BOOL)checkFields;

@end
