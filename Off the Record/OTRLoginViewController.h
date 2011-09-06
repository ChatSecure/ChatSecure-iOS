//
//  OTRLoginViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
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


- (IBAction)loginPressed:(id)sender;

@end
