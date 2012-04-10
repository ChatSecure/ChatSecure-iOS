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
@synthesize loginButton, cancelButton;
@synthesize rememberUserNameSwitch;
@synthesize useXMPP;
@synthesize usernameLabel, passwordLabel, rememberUsernameLabel;
@synthesize logoView;
@synthesize bottomToolbar;

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AimLoginFailedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"XMPPLoginFailedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"XMPPLoginSuccessNotification" object:nil];
    self.logoView = nil;
    self.usernameLabel = nil;
    self.passwordLabel = nil;
    self.rememberUsernameLabel = nil;
    self.rememberUserNameSwitch = nil;
    self.usernameTextField = nil;
    self.passwordTextField = nil;
    self.loginButton = nil;
    self.cancelButton = nil;
    self.bottomToolbar = nil;
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
    
    self.bottomToolbar = [[UIToolbar alloc] init];
    
    NSString *loginButtonString;
    SEL loginButtonAction;
    if (useXMPP) 
    {
        loginButtonString = [NSString stringWithFormat:@"%@ XMPP", LOGIN_TO_STRING];
        loginButtonAction = @selector(xmppLoginPressed:);
    } 
    else 
    {
        loginButtonString = [NSString stringWithFormat:@"%@ AIM", LOGIN_TO_STRING];
        loginButtonAction = @selector(loginPressed:);
    }
    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:loginButtonString style:UIBarButtonItemStyleDone target:self action:loginButtonAction];
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    
    self.bottomToolbar.items = [NSArray arrayWithObjects:cancelButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], loginButton, nil];
    
    [self.view addSubview:bottomToolbar];
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
}

- (CGSize) textSizeForLabel:(UILabel*)label {
    return [label.text sizeWithFont:label.font];
}

- (CGRect) textFieldFrameForLabel:(UILabel*)label {
    return CGRectMake(label.frame.origin.x + label.frame.size.width + 5, label.frame.origin.y, self.view.frame.size.width - label.frame.origin.x - label.frame.size.width - 10, 31);
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
    
    CGFloat usernameLabelFrameYOrigin = logoView.frame.origin.y + logoView.frame.size.height + 15;
    CGSize usernameLabelTextSize = [self textSizeForLabel:usernameLabel];
    self.usernameLabel.frame = CGRectMake(10, usernameLabelFrameYOrigin, usernameLabelTextSize.width, 21);
    self.usernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.usernameTextField.frame = [self textFieldFrameForLabel:usernameLabel];
    self.usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    
    CGFloat passwordLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height + 15;
    CGSize passwordLabelTextSize = [self textSizeForLabel:passwordLabel];
    self.passwordLabel.frame = CGRectMake(10, passwordLabelFrameYOrigin, passwordLabelTextSize.width, 21);
    self.passwordLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    self.passwordTextField.frame = [self textFieldFrameForLabel:passwordLabel];
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    CGFloat rememberUsernameLabelFrameYOrigin = passwordLabel.frame.origin.y + passwordLabel.frame.size.height + 15;
    self.rememberUsernameLabel.frame = CGRectMake(10, rememberUsernameLabelFrameYOrigin, 170, 21);
    self.rememberUsernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat rememberUserNameSwitchFrameWidth = 79;
    self.rememberUserNameSwitch.frame = CGRectMake(self.view.frame.size.width-rememberUserNameSwitchFrameWidth-5, rememberUsernameLabelFrameYOrigin, rememberUserNameSwitchFrameWidth, 27);
    self.rememberUserNameSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    CGFloat bottomToolbarFrameHeight = 45;
    self.bottomToolbar.frame = CGRectMake(0, self.view.frame.size.height - bottomToolbarFrameHeight, self.view.frame.size.width, bottomToolbarFrameHeight);
    self.bottomToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
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
