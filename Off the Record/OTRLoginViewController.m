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
#import "OTRConstants.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedOscarAccount.h"


#import "OTRXMPPLoginViewController.h"
#import "OTRJabberLoginViewController.h"
#import "OTRFacebookLoginViewController.h"
#import "OTROscarLoginViewController.h"
#import "OTRGoogleTalkLoginViewController.h"
#import "OTRInLineTextEditTableViewCell.h"
#import "OTRErrorManager.h"
#import "OTRProtocolManager.h"

#import "SIAlertView.h"
#import "UIAlertView+Blocks.h"
#import "OTRCertificatePinning.h"

#define kFieldBuffer 20;

@implementation OTRLoginViewController

- (void) dealloc {
    _logoView = nil;
    _rememberPasswordSwitch = nil;
    _usernameTextField = nil;
    _passwordTextField = nil;
    _loginButton = nil;
    _cancelButton = nil;
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
    _account = nil;
    _textFieldTextColor = nil;
}

- (id) initWithAccountID:(NSManagedObjectID *)newAccountID {
    if (self = [super init]) {
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        self.account = (OTRManagedAccount *)[context existingObjectWithID:newAccountID error:nil];
        
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            self.textFieldTextColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
        }
        else {
            self.textFieldTextColor = [UIColor colorWithRed:0 green:0.47843137 blue:1 alpha:1];
        }
        
    }
    return self;
}

-(void)setUpFields
{
    //tableViewArray = [[NSMutableArray alloc] init];
        
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.delegate = self;
    //self.usernameTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.text = self.account.username;
    self.usernameTextField.returnKeyType = UIReturnKeyDone;
    self.usernameTextField.textColor = self.textFieldTextColor;
    
    [self addCellinfoWithSection:0 row:0 labelText:USERNAME_STRING cellType:kCellTypeTextField userInputView:self.usernameTextField];
    
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    //self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.textColor = self.textFieldTextColor;
    self.passwordTextField.placeholder = REQUIRED_STRING;
    
    [self addCellinfoWithSection:0 row:1 labelText:PASSWORD_STRING cellType:kCellTypeTextField userInputView:self.passwordTextField];
    
    self.rememberPasswordSwitch = [[UISwitch alloc] init];
    [self.rememberPasswordSwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
    [self addCellinfoWithSection:0 row:2 labelText:REMEMBER_PASSWORD_STRING cellType:kCellTypeSwitch userInputView:self.rememberPasswordSwitch];
    
    [self createAutoLoginSwitch];
    [self addCellinfoWithSection:0 row:3 labelText:LOGIN_AUTOMATICALLY_STRING cellType:kCellTypeSwitch userInputView:self.autoLoginSwitch];

    
    
    
    NSString *loginButtonString = LOGIN_STRING;
    self.title = [self.account providerName];
    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:loginButtonString style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.navigationItem.rightBarButtonItem = self.loginButton;
    
    if (!self.isNewAccount) {
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }
    
}

- (void)createAutoLoginSwitch
{
    self.autoLoginSwitch = [[UISwitch alloc] init];
    [self.autoLoginSwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)switchDidChange:(id)sender
{
    if ([sender isEqual:self.autoLoginSwitch]) {
        if (self.autoLoginSwitch.on) {
            [self.rememberPasswordSwitch setOn:YES animated:YES];
        }
    }
    else if ([sender isEqual:self.rememberPasswordSwitch]) {
        if (!self.rememberPasswordSwitch.on) {
            [self.autoLoginSwitch setOn:NO animated:YES];
        }
    }
    
}

-(void)addCellinfoWithSection:(NSInteger)section row:(NSInteger)row labelText:(id)text cellType:(NSString *)type userInputView:(UIView *)inputView;
{
    if (!self.tableViewArray) {
        self.tableViewArray = [[NSMutableArray alloc] init];
    }
    
    if ([self.tableViewArray count]<(section+1)) {
        [self.tableViewArray setObject:[[NSMutableArray alloc] init] atIndexedSubscript:section];
    }
    
    NSDictionary * cellDictionary = [NSDictionary dictionaryWithObjectsAndKeys:text,kTextLabelTextKey,type,kCellTypeKey,inputView,kUserInputViewKey, nil];
    
    [[self.tableViewArray objectAtIndex:section] insertObject:cellDictionary atIndex:row];
    
}

- (void) viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setUpFields];
    
    
    self.loginViewTableView= [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.loginViewTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.loginViewTableView setDelegate:self];
    [self.loginViewTableView setDataSource:self];
    [self.view addSubview:self.loginViewTableView];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewArray count];
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return [[self.tableViewArray objectAtIndex:section] count];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([self.tableViewArray count] > 1)
    {
        if(section == 0)
            return BASIC_STRING;
        else if (section == 1)
            return ADVANCED_STRING;
    }
    return @"";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[[[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:kCellTypeKey] isEqualToString:KCellTypeHelp])
    {
        CGFloat height = ((UILabel *)[[[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:kTextLabelTextKey]).frame.size.height+10;
        return height;
    }
    return 44.0f;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary * cellDictionary = [[self.tableViewArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString * cellType = [cellDictionary objectForKey:kCellTypeKey];
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    if( [cellType isEqualToString:kCellTypeSwitch])
    {
        if(cell==nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
        }
        cell.textLabel.text = [cellDictionary objectForKey:kTextLabelTextKey];
        cell.accessoryView=[cellDictionary objectForKey:kUserInputViewKey];
        
    }
    else if( [cellType isEqualToString:KCellTypeHelp])
    {
        if(cell==nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
            
            [cell.contentView addSubview:[cellDictionary objectForKey:kTextLabelTextKey]];
            cell.accessoryView = [cellDictionary objectForKey:kUserInputViewKey];
        }
        
    }
    else if([cellType isEqualToString:kCellTypeTextField])
    {
        if(cell == nil)
        {
            cell = [[OTRInLineTextEditTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
        }
        cell.textLabel.text = [cellDictionary objectForKey:kTextLabelTextKey];
        [cell layoutIfNeeded];
        ((OTRInLineTextEditTableViewCell *)cell).textField = [cellDictionary objectForKey:kUserInputViewKey];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}




#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginFailed:)
     name:kOTRProtocolLoginFail
     object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account]];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoginSuccess:)
     name:kOTRProtocolLoginSuccess
     object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account]];
    
    if(!self.usernameTextField.text || [self.usernameTextField.text isEqualToString:@""])
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
    
    self.autoLoginSwitch.on = self.account.autologinValue;
    self.rememberPasswordSwitch.on = self.account.rememberPasswordValue;
    if (self.account.rememberPassword) {
        self.passwordTextField.text = self.account.password;
    } else {
        self.passwordTextField.text = @"";
    }
}
- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self readInFields];
    
    if([self.account.username length] && [self.account.password length] )
    {
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    }
    [self.view resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginFail object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLoginSuccess object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account]];

}

-(void)readInFields
{
    [self.account setUsername:[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    [self.account setRememberPasswordValue:self.rememberPasswordSwitch.on];
    
    self.account.autologinValue = self.autoLoginSwitch.on;
    
    if (self.account.rememberPasswordValue) {
        self.account.password = self.passwordTextField.text;
    } else {
        self.account.password = nil;
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
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    if([self.account.protocol isEqualToString:kOTRProtocolTypeXMPP])
    {
        NSDictionary * userInfo = notification.userInfo;
        id error = userInfo[kOTRProtocolLoginFailErrorKey];
        NSData * certData = userInfo[kOTRProtocolLoginFailSSLCertificateDataKey];
        NSString * hostname = userInfo[kOTRProtocolLoginFailHostnameKey];
        NSNumber * statusNumber = userInfo[kOTRProtocolLoginFailSSLStatusKey];
        
        
        RIButtonItem * okButtonItem = [RIButtonItem itemWithLabel:OK_STRING];
        if (certData) {
            if ([statusNumber longLongValue] == errSSLPeerAuthCompleted) {
                
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
                ((OTRXMPPManager *)protocol).certificatePinningModule.doNotManuallyEvaluateOverride = YES;
                [self loginButtonPressed:nil];
            }
            else {
                [self showCertWarningForData:certData withHostName:hostname withStatus:[statusNumber longValue]];
            }
        }
        else if ([error isKindOfClass:[NSError class]]) {
            recentError = (NSError *)error;
            
            if([recentError.domain isEqualToString:@"kCFStreamErrorDomainSSL"] && recentError.code == errSSLPeerBadCert) {
                return;
            }
            else {
                RIButtonItem * infoButton = [RIButtonItem itemWithLabel:INFO_STRING action:^{
                    NSString * errorDescriptionString = [NSString stringWithFormat:@"%@ : %@",[recentError domain],[recentError localizedDescription]];
                    
                    RIButtonItem * copyButtonItem = [RIButtonItem itemWithLabel:COPY_STRING action:^{
                        NSString * errorDescriptionString = [NSString stringWithFormat:@"Domain: %@\nCode: %d\nUserInfo: %@",[recentError domain],[recentError code],[recentError userInfo]];
                        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                        [pasteBoard setString:errorDescriptionString];
                    }];
                    
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:INFO_STRING message:errorDescriptionString cancelButtonItem:nil otherButtonItems:okButtonItem,copyButtonItem, nil];
                    
                    [alert show];
                }];
                
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:XMPP_FAIL_STRING cancelButtonItem:nil otherButtonItems:okButtonItem,infoButton, nil];
                [alertView show];
            }
            
        }
        else {
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:XMPP_FAIL_STRING cancelButtonItem:nil otherButtonItems:okButtonItem, nil];
            [alertView show];
        }
    }
    else if ([self.account.protocol isEqualToString:kOTRProtocolTypeAIM]) {
        NSDictionary * userInfo = notification.userInfo;
        NSError *error = userInfo[kOTRProtocolLoginFailErrorKey];
        NSString *errorTitle = nil;
        NSString *errorMessage = nil;
        if (error) {
            errorTitle = error.localizedDescription;
            errorMessage = error.localizedFailureReason;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
}
             
- (void)showCertWarningForData:(NSData *)certData withHostName:(NSString *)hostname withStatus:(OSStatus)status {
    
    SecCertificateRef certificate = [OTRCertificatePinning certForData:certData];
    NSString * fingerprint = [OTRCertificatePinning sha1FingerprintForCertificate:certificate];
    NSString * message = [NSString stringWithFormat:@"%@\nSHA1: %@\n",hostname,fingerprint];
    NSUInteger length = [message length];
    
    UIColor * sslMessageColor;
    
    if (status == noErr) {
        //#52A352
        sslMessageColor = [UIColor colorWithRed:0.32f green:0.64f blue:0.32f alpha:1.00f];
        message = [message stringByAppendingString:[NSString stringWithFormat:@"✓ %@",VALID_CERTIFICATE_STRING]];
    }
    else {
        NSString * sslErrorMessage = [OTRErrorManager errorStringWithSSLStatus:status];
        sslMessageColor = [UIColor colorWithRed:0.89f green:0.42f blue:0.36f alpha:1.00f];;
        message = [message stringByAppendingString:[NSString stringWithFormat:@"X %@",sslErrorMessage]];
    }
    NSRange errorMessageRange = NSMakeRange(length, message.length-length);
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:message];
    
    SIAlertView * alertView = [[SIAlertView alloc] initWithTitle:NEW_CERTIFICATE_STRING andMessage:nil];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, message.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:sslMessageColor range:errorMessageRange];
    
    alertView.messageAttributedString = attributedString;
    alertView.buttonColor = [UIColor whiteColor];
    
    [alertView addButtonWithTitle:REJECT_STRING type:SIAlertViewButtonTypeDestructive handler:^(SIAlertView *alertView) {
        [alertView dismissAnimated:YES];
    }];
    [alertView addButtonWithTitle:SAVE_STRING type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
            [((OTRXMPPManager *)protocol).certificatePinningModule addCertificate:[OTRCertificatePinning certForData:certData] withHostName:hostname];
            [self loginButtonPressed:alertView];
        }
    }];

    [alertView show];
    
    UIImage * normalImage = [UIImage imageNamed:@"button-green"];
    CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	UIImage * buttonImage = [normalImage resizableImageWithCapInsets:insets];
    
    [alertView setDefaultButtonImage:buttonImage forState:UIControlStateNormal];
    [alertView setDefaultButtonImage:buttonImage forState:UIControlStateHighlighted];
}

-(void)protocolLoginSuccess:(NSNotification*)notification
{
    if(HUD)
        [HUD hide:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}  



- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        [self showLoginProgress];
        
        [self readInFields];

        self.account.password = self.passwordTextField.text;
        
        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
        [protocol connectWithPassword:self.passwordTextField.text];
    }
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
}
-(void)showLoginProgress
{
    [self.view endEditing:YES];
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    HUD.delegate = self;
    HUD.labelText = LOGGING_IN_STRING;
    [HUD show:YES];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
}

- (void)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

-(BOOL)checkFields
{
    BOOL fields = self.usernameTextField.text && ![self.usernameTextField.text isEqualToString:@""] && self.passwordTextField.text && ![self.passwordTextField.text isEqualToString:@""];
    
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

-(void) didMoveToParentViewController:(UIViewController *)parent
{
    //Delete Account because user went back to choose different account type
    if(!parent)
    {
        [OTRAccountsManager removeAccount:self.account];
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
}

+(OTRLoginViewController *)loginViewControllerWithAcccountID:(NSManagedObjectID *)accountID
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedAccount * account = (OTRManagedAccount *)[context existingObjectWithID:accountID error:nil];
    switch (account.accountType) {
        case OTRAccountTypeAIM:
            return [[OTROscarLoginViewController alloc] initWithAccountID:accountID];
        case OTRAccountTypeJabber:
            return [[OTRJabberLoginViewController alloc] initWithAccountID:accountID];
        case OTRAccountTypeFacebook:
            return [[OTRFacebookLoginViewController alloc] initWithAccountID:accountID];
        case OTRAccountTypeGoogleTalk:
            return [[OTRGoogleTalkLoginViewController alloc] initWithAccountID:accountID];
        default:
            break;
    }
}

@end
