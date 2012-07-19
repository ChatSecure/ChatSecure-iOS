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
#import "OTRConstants.h"

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
    
    if ([account.domain isEqualToString:kOTRGoogleTalkDomain]) {
        self.usernameTextField.placeholder = @"user@gmail.com";
    }
    else if ([account.domain isEqualToString:kOTRFacebookDomain])
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
    else if ([account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        self.usernameTextField.placeholder = @"user@example.com";
    }
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.secureTextEntry = YES;
    
    padding = [[UIView alloc] init];
    
    [self.view addSubview:usernameTextField];
    [self.view addSubview:passwordTextField];
    
    
    //Jabber domain fields
    if([account.domain isEqualToString:@""] && [account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
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
        
    }
    
    NSString *loginButtonString = LOGIN_STRING;
    self.title = [account providerName];
    
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
    if(self.domainLabel && self.domainTextField)
    {
        CGFloat domainLabelFrameYOrigin = usernameLabelFrameYOrigin + self.usernameLabel.frame.size.height +kFieldBuffer;
        self.domainLabel.frame = CGRectMake(10, domainLabelFrameYOrigin, labelWidth, 21);
        self.domainLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.domainTextField.frame = [self textFieldFrameForLabel:domainLabel];
        self.domainTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.domainTextField.returnKeyType = UIReturnKeyNext;
        self.domainTextField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        
        passwordLabelFrameYOrigin = domainLabelFrameYOrigin + self.domainLabel.frame.size.height +kFieldBuffer;
        
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
        CGFloat facebookInfoButtonFrameYOrigin = facebookHelpLabeFrameYOrigin + (expectedLabelSize.height - infoButtonSize.height)/2;
        
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

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    account.username = self.usernameTextField.text;
    account.rememberPassword = rememberPasswordSwitch.on;
    
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
        
        if([self.account.domain isEqualToString:kOTRFacebookDomain])
        {
            usernameText = [NSString stringWithFormat:@"%@@%@",usernameText,kOTRFacebookDomain];
        }
        
        self.account.username = usernameText;
        self.account.password = passwordTextField.text;
        
        if([domainText length])
        {
            self.account.domain = domainText;
        }
        
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
    if (self.usernameTextField.isFirstResponder && self.domainTextField)
        [self.domainTextField becomeFirstResponder];
    else if (self.usernameTextField.isFirstResponder) {
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
    [urlActionSheet showInView:self.view];
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
