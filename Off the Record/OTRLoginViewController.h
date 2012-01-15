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

@property (retain, nonatomic) IBOutlet UITextField *usernameTextField;
@property (retain, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic, retain) OTRProtocolManager *protocolManager;
@property (retain, nonatomic) IBOutlet UIButton *aimButton;
@property (retain, nonatomic) IBOutlet UIButton *xmppButton;
@property (retain, nonatomic) IBOutlet UISwitch *rememberUserNameSwitch;
@property (nonatomic) BOOL useXMPP;


- (IBAction)loginPressed:(id)sender;
- (IBAction)xmppLoginPressed:(id)sender;
- (IBAction)cancelPressed:(id)sender;

-(BOOL)checkFields;

@end
