//
//  OTRLoginViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRLoginViewController.h"

@implementation OTRLoginViewController
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize protocolManager;
@synthesize aimButton;
@synthesize xmppButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setUsernameTextField:nil];
    [self setPasswordTextField:nil];
    [self setAimButton:nil];
    [self setXmppButton:nil];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [usernameTextField release];
    [passwordTextField release];
    [aimButton release];
    [xmppButton release];
    [super dealloc];
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
            [alert release];
        }
    }
}

- (IBAction)xmppLoginPressed:(id)sender 
{
    BOOL fields = [self checkFields];
    if(fields)
    {
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.delegate = self;
        HUD.labelText = @"Logging in...";
        
        [HUD show:YES];
        
        BOOL connect = [protocolManager.xmppManager connectWithJID:usernameTextField.text password:passwordTextField.text];
        
        if(connect)
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"XMPPLoginNotification"
             object:self];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
        }
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
        [alert release];
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
    [HUD release];
	HUD = nil;
}

@end
