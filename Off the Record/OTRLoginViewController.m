//
//  OTRLoginViewController.m
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

#import "OTRLoginViewController.h"
#import "Strings.h"
#import "OTRUIKeyboardListener.h"
#import "OTRConstants.h"
#import "OTRXMPPAccount.h"
#import "OTRAppDelegate.h"

#define kFieldBuffer 20;

@implementation OTRLoginViewController
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize loginButton, cancelButton;
@synthesize rememberPasswordSwitch;
@synthesize usernameLabel, passwordLabel, rememberPasswordLabel;
@synthesize logoView;
@synthesize timeoutTimer;
@synthesize account;
@synthesize domainLabel,domainTextField;
@synthesize facebookInfoButton;
@synthesize isNewAccount;
@synthesize basicAdvancedSegmentedControl;
@synthesize sslMismatchLabel,sslMismatchSwitch,selfSignedLabel,selfSignedSwitch;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginFail object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginSuccess object:nil];
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
    self.domainTextField = nil;
    self.domainLabel = nil;
    self.basicAdvancedSegmentedControl = nil;
    self.selfSignedLabel = nil;
    self.selfSignedSwitch = nil;
    self.sslMismatchLabel = nil;
    self.sslMismatchSwitch = nil;
}

- (id) initWithAccount:(OTRAccount*)newAccount {
    if (self = [super init]) {
        self.account = newAccount;
    }
    return self;
}


- (void )loadView {
    [super loadView];
    
    //self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    //[self.view addSubview:logoView];
    
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.text = USERNAME_STRING;
    self.passwordLabel = [[UILabel alloc] init];
    self.passwordLabel.text = PASSWORD_STRING;
    self.rememberPasswordLabel = [[UILabel alloc] init];
    self.rememberPasswordLabel.text = REMEMBER_PASSWORD_STRING;
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
    
    
    if ([account isKindOfClass:[OTRXMPPAccount class]]) {
        OTRXMPPAccount *xmppAccount = (OTRXMPPAccount*) account;
        if ([xmppAccount.domain isEqualToString:kOTRGoogleTalkDomain]) {
            self.usernameTextField.placeholder = @"user@gmail.com";
        }
        else if ([xmppAccount.domain isEqualToString:kOTRFacebookDomain])
        {
            facebookHelpLabel = [[UILabel alloc] init];
            facebookHelpLabel.text = FACEBOOK_HELP_STRING;
            facebookHelpLabel.textAlignment = UITextAlignmentLeft;
            facebookHelpLabel.lineBreakMode = UILineBreakModeWordWrap;
            facebookHelpLabel.numberOfLines = 0;
            facebookHelpLabel.font = [UIFont systemFontOfSize:14];
            
            self.facebookInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            [self.facebookInfoButton addTarget:self action:@selector(facebookInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.view addSubview:facebookHelpLabel];
            [self.view addSubview:facebookInfoButton];
            
            self.usernameTextField.placeholder = @"";
        }
        else if ([account.protocol isEqualToString:kOTRProtocolTypeXMPP] && ![xmppAccount.domain isEqualToString:kOTRGoogleTalkDomain])  //Jabber domain fields
        {
            self.usernameTextField.placeholder = @"user@example.com";

            self.domainLabel = [[UILabel alloc] init];
            self.domainLabel.text = DOMAIN_STRING;
            
            [self.view addSubview:domainLabel];
            
            self.domainTextField = [[UITextField alloc] init];
            self.domainTextField.delegate = self;
            self.domainTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.domainTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.domainTextField.borderStyle = UITextBorderStyleRoundedRect;
            self.domainTextField.placeholder = OPTIONAL_STRING;
            [self.view addSubview:domainTextField];
            
            self.basicAdvancedSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:BASIC_STRING,ADVANCED_STRING, nil]];
            [self.basicAdvancedSegmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];
            self.basicAdvancedSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            self.basicAdvancedSegmentedControl.selectedSegmentIndex = 0;
            
            self.sslMismatchLabel = [[UILabel alloc]init];
            self.sslMismatchLabel.text = SSL_MISMATCH_STRING;
            [self.view addSubview:sslMismatchLabel];
            
            self.sslMismatchSwitch = [[UISwitch alloc]init];
            [self.view addSubview:sslMismatchSwitch];
            
            self.selfSignedLabel = [[UILabel alloc]init];
            self.selfSignedLabel.text = SELF_SIGNED_SSL_STRING;
            [self.view addSubview:selfSignedLabel];
            
            self.selfSignedSwitch = [[UISwitch alloc]init];
            [self.view addSubview:selfSignedSwitch];
            
            
            [self.view addSubview:basicAdvancedSegmentedControl];
            
        }
    }
    

    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.secureTextEntry = YES;
    
    padding = [[UIView alloc] init];
    
    [self.view addSubview:usernameTextField];
    [self.view addSubview:passwordTextField];
    
    

    
    NSString *loginButtonString = LOGIN_STRING;
    self.title = [account providerName];
    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:loginButtonString style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.navigationItem.rightBarButtonItem = loginButton;

    if (!isNewAccount) {
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButton;

    }
}

- (void) viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginFailed:)
     name:kOTRProtocolLoginFail
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginSuccess:)
     name:kOTRProtocolLoginSuccess
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
    
    //double scale = 0.75;
    //CGFloat logoViewFrameWidth = (int)(self.logoView.image.size.width * scale);
    //self.logoView.frame = CGRectMake(self.view.frame.size.width/2 - logoViewFrameWidth/2, 5, logoViewFrameWidth, (int)(self.logoView.image.size.height * scale));
    //self.logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    padding.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    
    if (self.basicAdvancedSegmentedControl) {
        self.basicAdvancedSegmentedControl.frame = CGRectMake(1, 1, 200, 28);
        self.basicAdvancedSegmentedControl.center = CGPointMake(self.view.center.x, self.basicAdvancedSegmentedControl.center.y);
        //padding.frame = CGRectMake(0, 0, self.view.frame.size.width, 32)
    }
    
    CGFloat usernameLabelFrameYOrigin = padding.frame.origin.y + padding.frame.size.height;
    CGSize usernameLabelTextSize = [self textSizeForLabel:usernameLabel];
    CGSize passwordLabelTextSize = [self textSizeForLabel:passwordLabel];
    CGSize domainLabelTextSize = [self textSizeForLabel:domainLabel];
    CGFloat labelWidth = MAX( MAX(usernameLabelTextSize.width, passwordLabelTextSize.width),domainLabelTextSize.width);

    self.usernameLabel.frame = CGRectMake(10, usernameLabelFrameYOrigin, labelWidth, 21);
    self.usernameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.usernameTextField.frame = [self textFieldFrameForLabel:usernameLabel];
    self.usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    if ([account.protocol isEqualToString:kOTRProtocolTypeXMPP]) {
        self.usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    self.usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    
    CGFloat passwordLabelFrameYOrigin;
    if(self.domainLabel && self.domainTextField && self.basicAdvancedSegmentedControl)
    {
        //CGFloat domainLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height +kFieldBuffer;
        self.domainLabel.frame = CGRectMake(10, usernameLabelFrameYOrigin, labelWidth, 21);
        self.domainLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.domainLabel setHidden:YES];
        
        self.domainTextField.frame = [self textFieldFrameForLabel:domainLabel];
        self.domainTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.domainTextField.keyboardType = UIKeyboardTypeURL;
        self.domainTextField.returnKeyType = UIReturnKeyGo;
        self.domainTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self.domainTextField setHidden:YES];
        
        CGFloat sslMismatchLabelFrameYOrigin = domainLabel.frame.origin.y + domainLabel.frame.size.height + kFieldBuffer;
        self.sslMismatchLabel.frame = CGRectMake(10, sslMismatchLabelFrameYOrigin, 200, 21);
        self.sslMismatchLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.sslMismatchLabel setHidden:YES];
        
        
        CGFloat sslMismatchSwitchFrameWidth = 79;
        self.sslMismatchSwitch.frame = CGRectMake(self.view.frame.size.width-sslMismatchSwitchFrameWidth-5, sslMismatchLabelFrameYOrigin, sslMismatchSwitchFrameWidth, 27);
        self.sslMismatchSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.sslMismatchSwitch setHidden:YES];
        
        
        CGFloat selfSignedFrameYOrigin = sslMismatchLabel.frame.origin.y + sslMismatchLabel.frame.size.height + kFieldBuffer;
        self.selfSignedLabel.frame = CGRectMake(10, selfSignedFrameYOrigin, 180, 21);
        self.selfSignedLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.selfSignedLabel setHidden:YES];
        
        
        CGFloat selfSignedSwitchFrameWidth = 79;
        self.selfSignedSwitch.frame = CGRectMake(self.view.frame.size.width-selfSignedSwitchFrameWidth-5, selfSignedFrameYOrigin, selfSignedSwitchFrameWidth, 27);
        self.selfSignedSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.selfSignedSwitch setHidden:YES];
        
        self.domainTextField.text = ((OTRXMPPAccount*)self.account).domain;
        self.sslMismatchSwitch.on = ((OTRXMPPAccount*)self.account).allowSSLHostNameMismatch;
        self.selfSignedSwitch.on = ((OTRXMPPAccount*)self.account).allowSelfSignedSSL;
        
        
        //passwordLabelFrameYOrigin = domainLabelFrameYOrigin + self.domainLabel.frame.size.height +kFieldBuffer;
        passwordLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height + kFieldBuffer;
        
    }
    else if (facebookHelpLabel)
    {
        CGFloat facebookHelpLabeFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height +kFieldBuffer;
        
        facebookHelpLabel.frame = CGRectMake(10, facebookHelpLabeFrameYOrigin, self.view.frame.size.width-40, 21);
        
        CGSize maximumLabelSize = CGSizeMake(296,9999);
        
        CGSize expectedLabelSize = [facebookHelpLabel.text sizeWithFont:facebookHelpLabel.font constrainedToSize:maximumLabelSize lineBreakMode:facebookHelpLabel.lineBreakMode];   
        
        //adjust the label the the new height.
        CGRect newFrame = facebookHelpLabel.frame;
        newFrame.size.height = expectedLabelSize.height;
        facebookHelpLabel.frame = newFrame;
        
        
        
        facebookHelpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        CGSize infoButtonSize = self.facebookInfoButton.frame.size;
        CGFloat facebookInfoButtonFrameYOrigin = floorf(facebookHelpLabeFrameYOrigin + (expectedLabelSize.height - infoButtonSize.height)/2);
        
        self.facebookInfoButton.frame = CGRectMake(facebookHelpLabel.frame.origin.x + facebookHelpLabel.frame.size.width, facebookInfoButtonFrameYOrigin, infoButtonSize.width, infoButtonSize.height);
        
        passwordLabelFrameYOrigin = facebookHelpLabeFrameYOrigin +facebookHelpLabel.frame.size.height +kFieldBuffer;
    }
    else {
        passwordLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height + kFieldBuffer;
    }
    
    self.passwordLabel.frame = CGRectMake(10, passwordLabelFrameYOrigin, labelWidth, 21);
    self.passwordLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.passwordTextField.frame = [self textFieldFrameForLabel:passwordLabel];
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    
    CGFloat rememberUsernameLabelFrameYOrigin = passwordLabel.frame.origin.y + passwordLabel.frame.size.height + kFieldBuffer;
    self.rememberPasswordLabel.frame = CGRectMake(10, rememberUsernameLabelFrameYOrigin, 170, 21);
    self.rememberPasswordLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat rememberUserNameSwitchFrameWidth = 79;
    self.rememberPasswordSwitch.frame = CGRectMake(self.view.frame.size.width-rememberUserNameSwitchFrameWidth-5, rememberUsernameLabelFrameYOrigin, rememberUserNameSwitchFrameWidth, 27);
    self.rememberPasswordSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    if(!self.usernameTextField.text || [self.usernameTextField.text isEqualToString:@""])
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
    
    
    self.rememberPasswordSwitch.on = self.account.rememberPassword;
    if (account.rememberPassword) {
        self.passwordTextField.text = account.password;
    } else {
        self.passwordTextField.text = @"";
    }
}

-(void) segmentedControlChanged
{
    //baseic setup
    if([basicAdvancedSegmentedControl selectedSegmentIndex]==0)
    {
        [self.domainLabel setHidden:YES];
        [self.domainTextField setHidden:YES];
        [self.usernameTextField becomeFirstResponder];
        [self.sslMismatchSwitch setHidden:YES];
        [self.sslMismatchLabel setHidden:YES];
        [self.selfSignedLabel setHidden:YES];
        [self.selfSignedSwitch setHidden:YES];
        
        
        [self.usernameLabel setHidden:NO];
        [self.usernameTextField setHidden:NO];
        [self.rememberPasswordLabel setHidden:NO];
        [self.rememberPasswordSwitch setHidden:NO];
        [self.passwordLabel setHidden:NO];
        [self.passwordTextField setHidden:NO];
        
    }
    else //advanced setup
    {
        [self.domainLabel setHidden:NO];
        [self.domainTextField setHidden:NO];
        [self.domainTextField becomeFirstResponder];
        [self.sslMismatchSwitch setHidden:NO];
        [self.sslMismatchLabel setHidden:NO];
        [self.selfSignedLabel setHidden:NO];
        [self.selfSignedSwitch setHidden:NO];
        
        
        [self.usernameLabel setHidden:YES];
        [self.usernameTextField setHidden:YES];
        [self.rememberPasswordLabel setHidden:YES];
        [self.rememberPasswordSwitch setHidden:YES];
        [self.passwordLabel setHidden:YES];
        [self.passwordTextField setHidden:YES];
    }
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    account.username = self.usernameTextField.text;
    account.rememberPassword = rememberPasswordSwitch.on;
    
    if([account isKindOfClass:[OTRXMPPAccount class]])
    {
        ((OTRXMPPAccount *)account).allowSelfSignedSSL = selfSignedSwitch.on;
        ((OTRXMPPAccount *)account).allowSSLHostNameMismatch = sslMismatchSwitch.on;
    }
    
    
    if (account.rememberPassword) {
        account.password = self.passwordTextField.text;
    } else {
        account.password = nil;
    }
    
    if([account.username length]!=0 && [account.password length] !=0 )
    {
        [account save];
        [[[OTRProtocolManager sharedInstance] accountsManager] addAccount:account];
    }
    
    
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

-(void) timeout:(NSTimer *) timer
{
    //[timeoutTimer invalidate];
    if (HUD) {
        [HUD hide:YES];
    }
}

-(void)protocolLoginFailed:(NSNotification*)notification
{
    if(HUD)
        [HUD hide:YES];
    if([account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:XMPP_FAIL_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
}

-(void)protocolLoginSuccess:(NSNotification*)notification
{
    if(HUD)
        [HUD hide:YES];
    [self dismissModalViewControllerAnimated:YES];
    /* not sure why this was ever needed
    if([account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"XMPPLoginNotification"
         object:self];
        [timeoutTimer invalidate];
    }
     */
}  


- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.delegate = self;
        HUD.labelText = LOGGING_IN_STRING;
        float hudOffsetY = [self getMidpointOffsetforHUD];
        HUD.yOffset = hudOffsetY;
        [HUD show:YES];
        
        NSString * usernameText = [usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString * domainText = [domainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([account isKindOfClass:[OTRXMPPAccount class]]) {
            OTRXMPPAccount *xmppAccount = (OTRXMPPAccount*) account;
            if([xmppAccount.domain isEqualToString:kOTRFacebookDomain])
            {
                usernameText = [NSString stringWithFormat:@"%@@%@",usernameText,kOTRFacebookDomain];
            }
            if([domainText length])
            {
                xmppAccount.domain = domainText;
            }
        }


        
        self.account.username = usernameText;
        self.account.password = passwordTextField.text;
        

        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol connectWithPassword:self.passwordTextField.text];
    }
    self.timeoutTimer = [NSTimer timerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
    [[[OTRProtocolManager sharedInstance] accountsManager] addAccount:account];
    [account save];
}

- (void)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

-(BOOL)checkFields
{
    BOOL fields = usernameTextField.text && ![usernameTextField.text isEqualToString:@""] && passwordTextField.text && ![passwordTextField.text isEqualToString:@""];
    
    if(!fields)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
    
    return fields;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.usernameTextField.isFirstResponder) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (self.domainTextField.isFirstResponder) {
        [self.passwordTextField becomeFirstResponder];
    }
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

-(void)facebookInfoButtonPressed:(id)sender
{
    UIActionSheet * urlActionSheet = [[UIActionSheet alloc] initWithTitle:kOTRFacebookUsernameLink delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
    [urlActionSheet showInView:[OTR_APP_DELEGATE window]];
}


#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        NSURL *url = [ [ NSURL alloc ] initWithString: kOTRFacebookUsernameLink ];
        [[UIApplication sharedApplication] openURL:url];
        
    }
}

@end
