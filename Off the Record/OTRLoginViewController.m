//
//  OTRLoginViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRLoginViewController.h"

@implementation OTRLoginViewController
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize protocolManager;
@synthesize aimButton;
@synthesize xmppButton;
@synthesize rememberUserNameSwitch;
@synthesize useXMPP;

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

- (void) viewDidLoad 
{
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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([[defaults objectForKey:@"saveUsername"] boolValue])
    {
        [rememberUserNameSwitch setOn:YES];
    }
    if(rememberUserNameSwitch.on) {
        if(useXMPP) {
            usernameTextField.text = [defaults objectForKey:@"xmppUsername"];
        }
        else {
            usernameTextField.text = [defaults objectForKey:@"aimUsername"];
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(rememberUserNameSwitch.on) {
        if(useXMPP) {
            [defaults setObject:usernameTextField.text forKey:@"xmppUsername"];
        }
        else {
            [defaults setObject:usernameTextField.text forKey:@"aimUsername"];
        }
    }
    [defaults setObject:[NSNumber numberWithBool:rememberUserNameSwitch.on] forKey:@"saveUsername"];
    [defaults synchronize];
}

- (void)viewDidUnload
{
    [self setUsernameTextField:nil];
    [self setPasswordTextField:nil];
    [self setAimButton:nil];
    [self setXmppButton:nil];
    [self setRememberUserNameSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidDisappear:(BOOL)animated
{
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

- (IBAction)loginPressed:(id)sender 
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Failed to start authenticating. Please try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}



- (IBAction)xmppLoginPressed:(id)sender 
{
    BOOL fields = [self checkFields];
    if(fields)
    {
        NSLog(@"show HUD");
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.delegate = self;
        HUD.labelText = @"Logging in...";
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

- (IBAction)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

-(BOOL)checkFields
{
    BOOL fields = ![usernameTextField.text isEqualToString:@""] && ![passwordTextField.text isEqualToString:@""];
    
    if(!fields)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"You must enter a username and a password to login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
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
