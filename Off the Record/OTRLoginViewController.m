//
//  OTRLoginViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRLoginViewController.h"
#import "Strings.h"
#import "OTRUIKeyboardListener.h"

@implementation OTRLoginViewController
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize protocolManager;
@synthesize loginButton, cancelButton;
@synthesize rememberPasswordSwitch;
@synthesize useXMPP;
@synthesize usernameLabel, passwordLabel, rememberPasswordLabel;
@synthesize logoView;
@synthesize timeoutTimer;
@synthesize account;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AimLoginFailedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"XMPPLoginFailedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"XMPPLoginSuccessNotification" object:nil];
    self.logoView = nil;
    self.usernameLabel = nil;
    self.passwordLabel = nil;
    self.rememberPasswordLabel = nil;
    self.rememberPasswordSwitch = nil;
    self.usernameTextField = nil;
    self.passwordTextField = nil;
    self.loginButton = nil;
    self.cancelButton = nil;
    [timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.account = nil;
}

- (id) initWithAccount:(OTRAccount*)newAccount {
    if (self = [super init]) {
        self.account = newAccount;
    }
    return self;
}


- (void )loadView {
    [super loadView];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    [self.view addSubview:logoView];
    
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.text = USERNAME_STRING;
    self.passwordLabel = [[UILabel alloc] init];
    self.passwordLabel.text = PASSWORD_STRING;
    self.rememberPasswordLabel = [[UILabel alloc] init];
    self.rememberPasswordLabel.text = REMEMBER_USERNAME_STRING;
    self.rememberPasswordSwitch = [[UISwitch alloc] init];
    [self.view addSubview:usernameLabel];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:rememberPasswordLabel];
    [self.view addSubview:rememberPasswordSwitch];
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.delegate = self;
    self.usernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.text = account.username;
    if (useXMPP)
    {
        self.usernameTextField.placeholder = @"user@example.com";
    }
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.secureTextEntry = YES;
    if (account.rememberPassword) {
        self.passwordTextField.text = account.password;
    } else {
        self.passwordTextField.text = @"";
    }
    [self.view addSubview:usernameTextField];
    [self.view addSubview:passwordTextField];
    
    
    NSString *loginButtonString = LOGIN_STRING;
    if (useXMPP) 
    {
        self.title = @"XMPP";
    } 
    else 
    {
        self.title = @"AIM";
    }
    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:loginButtonString style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    
    self.navigationItem.rightBarButtonItem = loginButton;
    self.navigationItem.leftBarButtonItem = cancelButton;
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
    
    double scale = 0.75;
    CGFloat logoViewFrameWidth = (int)(self.logoView.image.size.width * scale);
    self.logoView.frame = CGRectMake(self.view.frame.size.width/2 - logoViewFrameWidth/2, 5, logoViewFrameWidth, (int)(self.logoView.image.size.height * scale));
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    CGFloat usernameLabelFrameYOrigin = logoView.frame.origin.y + logoView.frame.size.height + 5;
    CGSize usernameLabelTextSize = [self textSizeForLabel:usernameLabel];
    CGSize passwordLabelTextSize = [self textSizeForLabel:passwordLabel];
    CGFloat labelWidth = MAX(usernameLabelTextSize.width, passwordLabelTextSize.width);

    self.usernameLabel.frame = CGRectMake(10, usernameLabelFrameYOrigin, labelWidth, 21);
    self.usernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.usernameTextField.frame = [self textFieldFrameForLabel:usernameLabel];
    self.usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    if (useXMPP) {
        self.usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    self.usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    
    CGFloat passwordLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height + 15;
    self.passwordLabel.frame = CGRectMake(10, passwordLabelFrameYOrigin, labelWidth, 21);
    self.passwordLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.passwordTextField.frame = [self textFieldFrameForLabel:passwordLabel];
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    
    CGFloat rememberUsernameLabelFrameYOrigin = passwordLabel.frame.origin.y + passwordLabel.frame.size.height + 15;
    self.rememberPasswordLabel.frame = CGRectMake(10, rememberUsernameLabelFrameYOrigin, 170, 21);
    self.rememberPasswordLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat rememberUserNameSwitchFrameWidth = 79;
    self.rememberPasswordSwitch.frame = CGRectMake(self.view.frame.size.width-rememberUserNameSwitchFrameWidth-5, rememberUsernameLabelFrameYOrigin, rememberUserNameSwitchFrameWidth, 27);
    self.rememberPasswordSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    if([self.usernameTextField.text isEqualToString:@""])
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [account save];
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
        //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
        return NO;
    }
}

- (void)aimLoginPressed:(id)sender 
{
    BOOL fields = [self checkFields];
    if(fields)
    {
        protocolManager.oscarManager.login = [[AIMLogin alloc] initWithUsername:usernameTextField.text password:passwordTextField.text];
        protocolManager.oscarManager.accountName = usernameTextField.text;
        [protocolManager.oscarManager.login setDelegate:protocolManager.oscarManager];
        
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        float hudOffsetY = [self getMidpointOffsetforHUD];
        
        HUD.yOffset = hudOffsetY;
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

-(void) timeout:(NSTimer *) timer
{
    //[timeoutTimer invalidate];
    if (HUD) {
        [HUD hide:YES];
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
    [timeoutTimer invalidate];
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
        float hudOffsetY = [self getMidpointOffsetforHUD];
        HUD.yOffset = hudOffsetY;
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

- (void)loginButtonPressed:(id)sender {
    if (useXMPP) 
    {
        [self xmppLoginPressed:sender];
    } 
    else 
    {
        [self aimLoginPressed:sender];
    }
    timeoutTimer = [NSTimer timerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];


    
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
    if (self.usernameTextField.isFirstResponder)
        [self.passwordTextField becomeFirstResponder];
    else
        [self loginButtonPressed:nil];
    
    return NO;
}

-(float)getMidpointOffsetforHUD
{
    OTRUIKeyboardListener * keyboardListenter = [OTRUIKeyboardListener shared];
    CGSize keyboardSize = [keyboardListenter getFrameWithView:self.view].size;
    
    
    
    float viewHeight = self.view.frame.size.height;
    return (viewHeight - keyboardSize.height)/2.0-(viewHeight/2.0);
}


#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
}

@end
