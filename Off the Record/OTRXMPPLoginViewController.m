//
//  OTRXMPPLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

#import "OTRXMPPLoginViewController.h"
#import "OTRConstants.h"
#import "OTRXMPPError.h"
#import "SIAlertView.h"
#import "HITorManager.h"
#import "OTRManagedXMPPTorAccount.h"



@interface OTRXMPPLoginViewController ()



@end

@implementation OTRXMPPLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)keyboardWillHideOrShow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameForTableView = [self.loginViewTableView.superview convertRect:keyboardFrame fromView:nil];
    
    CGRect newTableViewFrame = CGRectMake(0, 0, self.loginViewTableView.frame.size.width, keyboardFrameForTableView.origin.y);
    
    //keyboardFrameForTextField.origin.y - newTextFieldFrame.size.height;
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.loginViewTableView.frame = newTableViewFrame;
    } completion:nil];
}

- (BOOL)isTorAccount{
    if ([self.account isKindOfClass:[OTRManagedXMPPTorAccount class]]) {
        return YES;
    }
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillShowNotification object:nil];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    if ([self isTorAccount]) {
        self.loginButtonPressed = NO;
        [[HITorManager defaultManager] addObserver:self forKeyPath:NSStringFromSelector(@selector(isRunning)) options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if([self isTorAccount])
    {
        [[HITorManager defaultManager] removeObserver:self forKeyPath:NSStringFromSelector(@selector(isRunning))];
    }
    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isRunning))] && [object isEqual:[HITorManager defaultManager]]) {
        BOOL isRunning = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isRunning && self.loginButtonPressed) {
            [self loginButtonPressed:nil];
        }
    }
}

- (void)protocolLoginFailed:(NSNotification *)notification {
    [self hideHUD];
    NSError * error = notification.userInfo[kOTRNotificationErrorKey];
    
    if (error.code == OTRXMPPSSLError) {
        NSData * certData = error.userInfo[OTRXMPPSSLCertificateDataKey];
        NSString * hostname = error.userInfo[OTRXMPPSSLHostnameKey];
        NSNumber * statusNumber = error.userInfo[OTRXMPPSSLStatusKey];
        
        if ([statusNumber longLongValue] == errSSLPeerAuthCompleted) {
            //The cert was manually evaluated but did not anything that is saved so we have to recheck system and get interal validation status
            //((OTRXMPPManager *)protocol).certificatePinningModulesss
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
            ((OTRXMPPManager *)protocol).certificatePinningModule.doNotManuallyEvaluateOverride = YES;
            [self loginButtonPressed:nil];
        }
        else {
            [self showCertWarningForData:certData withHostName:hostname withStatus:[statusNumber longValue]];
        }
    }
    else{
        [super protocolLoginFailed:notification];
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
        NSString * sslErrorMessage = [OTRXMPPError errorStringWithSSLStatus:status];
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

- (void)loginButtonPressed:(id)sender
{
    self.loginButtonPressed = YES;
    if( [self.account isKindOfClass:[OTRManagedXMPPTorAccount class]]){
        if(![HITorManager defaultManager].isRunning) {
            [self showHUDWithText:@"Connecting to Tor"];
            [[HITorManager defaultManager] start];
        }
        else{
            [super loginButtonPressed:sender];
        }
    }
    else {
        [super loginButtonPressed:sender];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
