//
//  OTRXMPPOAUTHLoginViewController.h
//  Off the Record
//
//  Created by David on 9/13/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginViewController.h"
#import "OTRManagedOAuthAccount.h"

@interface OTRXMPPOAUTHLoginViewController : OTRXMPPLoginViewController

@property (nonatomic,strong)  OTRManagedOAuthAccount * account;

@property (nonatomic,strong) UIButton * connectButton;
@property (nonatomic,strong) UIButton * disconnectButton;

-(void)connectAccount:(id)sender;
-(void)disconnectAccount:(id)sender;

@end
