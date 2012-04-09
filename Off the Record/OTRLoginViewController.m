//
//  OTRLoginViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRLoginViewController.h"
#import "Strings.h"

@implementation OTRLoginViewController
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize protocolManager;
@synthesize aimButton, xmppButton, cancelButton;
@synthesize rememberUserNameSwitch;
@synthesize useXMPP;
@synthesize usernameLabel, passwordLabel, rememberUsernameLabel;
@synthesize logoView;

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.logoView = nil;
    self.usernameLabel = nil;
    self.passwordLabel = nil;
    self.rememberUsernameLabel = nil;
    self.rememberUserNameSwitch = nil;
    self.usernameTextField = nil;
    self.passwordTextField = nil;
    self.xmppButton = nil;
    self.aimButton = nil;
    self.cancelButton = nil;
}


- (void )loadView {
    [super loadView];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    [self.view addSubview:logoView];
    
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.text = USERNAME_STRING;
    self.passwordLabel = [[UILabel alloc] init];
    self.passwordLabel.text = PASSWORD_STRING;
    self.rememberUsernameLabel = [[UILabel alloc] init];
    self.rememberUsernameLabel.text = REMEMBER_USERNAME_STRING;
    self.rememberUserNameSwitch = [[UISwitch alloc] init];
    [self.view addSubview:usernameLabel];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:rememberUsernameLabel];
    [self.view addSubview:rememberUserNameSwitch];
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.delegate = self;
    self.usernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.secureTextEntry = YES;
    [self.view addSubview:usernameTextField];
    [self.view addSubview:passwordTextField];
    
    self.xmppButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [xmppButton addTarget:self action:@selector(xmppLoginPressed:) forControlEvents:UIControlEventTouchUpInside];
    [xmppButton setTitle:[NSString stringWithFormat:@"%@ XMPP", LOGIN_TO_STRING] forState:UIControlStateNormal];
    self.aimButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [aimButton addTarget:self action:@selector(loginPressed:) forControlEvents:UIControlEventTouchUpInside];
    [aimButton setTitle:[NSString stringWithFormat:@"%@ AIM", LOGIN_TO_STRING] forState:UIControlStateNormal];
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setTitle:CANCEL_STRING forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:xmppButton];
    [self.view addSubview:aimButton];
    [self.view addSubview:cancelButton];
}

- (void) viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(aimLoginFailed)
     name:@"AimLoginFailedNotification"
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(xmppLoginFailed)
     name:@"XMPPLoginFailedNotification"
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(xmppLoginSuccess)
     name:@"XMPPLoginSuccessNotification"
     object:nil ];
    
    if (useXMPP) {
        aimButton.hidden = YES;
    }
    else {
        xmppButton.hidden = YES;
    }
}


#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([[defaults objectForKey:@"saveUsername"] boolValue])
    {
        [rememberUserNameSwitch setOn:YES];
    }
    if(rememberUserNameSwitch.on) 
    {
        if(useXMPP) 
        {
            usernameTextField.text = [defaults objectForKey:@"xmppUsername"];
        }
        else 
        {
            usernameTextField.text = [defaults objectForKey:@"aimUsername"];
        }
    }
    
    CGFloat logoViewFrameWidth = self.logoView.image.size.width;
    self.logoView.frame = CGRectMake(self.view.frame.size.width/2 - logoViewFrameWidth/2, 20, logoViewFrameWidth, self.logoView.image.size.height);
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    CGFloat usernameLabelFrameYOrigin = logoView.frame.origin.y + logoView.frame.size.height + 10;
    self.usernameLabel.frame = CGRectMake(10, usernameLabelFrameYOrigin, 80, 21);
    self.usernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.usernameTextField.frame = CGRectMake(usernameLabel.frame.origin.x + usernameLabel.frame.size.width + 5, usernameLabelFrameYOrigin, 203, 31);
    self.usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    CGFloat passwordLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height + 10;
    self.passwordLabel.frame = CGRectMake(10, passwordLabelFrameYOrigin, 80, 21);
    self.passwordLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    self.passwordTextField.frame = CGRectMake(passwordLabel.frame.origin.x + passwordLabel.frame.size.width + 5, passwordLabelFrameYOrigin, 203, 31);
    self.passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    CGFloat rememberUsernameLabelFrameYOrigin = passwordLabel.frame.origin.y + passwordLabel.frame.size.height + 30;
    self.rememberUsernameLabel.frame = CGRectMake(10, rememberUsernameLabelFrameYOrigin, 170, 21);
    self.rememberUsernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.rememberUserNameSwitch.frame = CGRectMake(rememberUsernameLabel.frame.origin.x + rememberUsernameLabel.frame.size.width + 20, rememberUsernameLabelFrameYOrigin, 79, 27);
    self.rememberUserNameSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    CGFloat loginButtonFrameWidth = 131;
    CGFloat loginButtonFrameHeight = 37;
    CGRect loginButtonFrame = CGRectMake(self.view.frame.size.width/2 - loginButtonFrameWidth/2, self.view.frame.size.height-loginButtonFrameHeight-60, loginButtonFrameWidth, loginButtonFrameHeight);
    self.aimButton.frame = loginButtonFrame;
    self.aimButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;

    self.xmppButton.frame = loginButtonFrame;
    self.xmppButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    CGFloat cancelButtonFrameHeight = loginButtonFrameHeight;
    CGFloat cancelButtonFrameYOrigin = self.view.frame.size.height - cancelButtonFrameHeight - 10;
    self.cancelButton.frame = CGRectMake(10, cancelButtonFrameYOrigin, 74, cancelButtonFrameHeight);
    self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
}

- (void) viewWillDisappear:(BOOL)animated 
{
    [super viewWillDisappear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(rememberUserNameSwitch.on) 
    {
        if(useXMPP) 
        {
            [defaults setObject:usernameTextField.text forKey:@"xmppUsername"];
        }
        else 
        {
            [defaults setObject:usernameTextField.text forKey:@"aimUsername"];
        }
    }
    [defaults setObject:[NSNumber numberWithBool:rememberUserNameSwitch.on] forKey:@"saveUsername"];
    [defaults synchronize];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if(HUD)
        [HUD hide:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (void)loginPressed:(id)sender 
{
    BOOL fields = [self checkFields];
    if(fields)
    {
        protocolManager.oscarManager.login = [[AIMLogin alloc] initWithUsername:usernameTextField.text password:passwordTextField.text];
        protocolManager.oscarManager.accountName = usernameTextField.text;
        [protocolManager.oscarManager.login setDelegate:protocolManager.oscarManager];
        
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.delegate = self;
        HUD.labelText = @"Logging in...";
        [HUD show:YES];
        
        
        if (![protocolManager.oscarManager.login beginAuthorization]) {
            [HUD hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:OSCAR_FAIL_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            [alert show];
        }
    }
}

-(void) aimLoginFailed
{
    if(HUD)
        [HUD hide:YES];
}

-(void) xmppLoginSuccess
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"XMPPLoginNotification"
     object:self];
}
-(void) xmppLoginFailed
{
    [HUD hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:XMPP_FAIL_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
    [alert show];
}



- (void)xmppLoginPressed:(id)sender 
{
    BOOL fields = [self checkFields];
    if(fields)
    {
        NSLog(@"show HUD");
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.delegate = self;
        HUD.labelText = LOGGING_IN_STRING;
            [HUD show:YES];
        
        BOOL connect = [protocolManager.xmppManager connectWithJID:usernameTextField.text password:passwordTextField.text];
        
        if (connect) {
            NSLog(@"xmppLogin attempt");
        }
        /*
        if(connect)
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"XMPPLoginNotification"
             object:self];
        }
        else
        {
            [HUD hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
        }*/
    }
}

- (void)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

-(BOOL)checkFields
{
    BOOL fields = ![usernameTextField.text isEqualToString:@""] && ![passwordTextField.text isEqualToString:@""];
    
    if(!fields)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
    
    return fields;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
}

@end
