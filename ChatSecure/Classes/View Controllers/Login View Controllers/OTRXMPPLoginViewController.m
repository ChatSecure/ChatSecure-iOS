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
#import "OTRTorManager.h"
#import "OTRColors.h"
#import "OTRCertificatePinning.h"
#import "OTRXMPPTorAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPManager.h"
#import "OTRLog.h"
#import <KVOController/FBKVOController.h>


@interface OTRXMPPLoginViewController ()

@property (nonatomic,strong) SIAlertView * certAlertView;
@property (nonatomic, strong) OTRXMPPAccount *account;

@end

@implementation OTRXMPPLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.resourceTextField = [[UITextField alloc] init];
    self.resourceTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.resourceTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.resourceTextField.returnKeyType = UIReturnKeyDone;
    self.resourceTextField.textColor = self.textFieldTextColor;
    self.resourceTextField.text = self.account.resource;
    
    [self addCellinfoWithSection:1 row:0 labelText:RESOURCE_STRING cellType:kCellTypeTextField userInputView:self.resourceTextField];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillShowNotification object:nil];

}

-(void)keyboardWillHideOrShow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameForTableView = [self.loginViewTableView.superview convertRect:keyboardFrame fromView:nil];
    
    CGRect newTableViewFrame = CGRectMake(0, 0, self.loginViewTableView.frame.size.width, keyboardFrameForTableView.origin.y);
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.loginViewTableView.frame = newTableViewFrame;
    } completion:nil];
}

- (BOOL)isTorAccount{
    if ([self.account isKindOfClass:[OTRXMPPTorAccount class]]) {
        return YES;
    }
    return NO;
}

- (void)readInFields
{
    [super readInFields];
    if (self.resourceTextField.text.length) {
        self.account.resource = self.resourceTextField.text;
    }
    else {
        self.account.resource = [OTRXMPPAccount newResource];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideOrShow:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideOrShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    self.loginButtonPressed = NO;
    if (self.isTorAccount) {
        __weak typeof(self)weakSelf = self;
        [self.KVOController observe:[OTRTorManager sharedInstance].torManager keyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if ([OTRTorManager sharedInstance].torManager.isConnected && strongSelf.loginButtonPressed) {
                [strongSelf loginButtonPressed:nil];
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                              name:UIKeyboardWillHideNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                              name:UIKeyboardWillShowNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

- (void)protocolLoginFailed:(NSNotification *)notification {
    [self hideHUD];
    NSError * error = notification.userInfo[kOTRNotificationErrorKey];
    
    if (error.code == OTRXMPPSSLError) {
        NSData * certData = error.userInfo[OTRXMPPSSLCertificateDataKey];
        NSString * hostname = error.userInfo[OTRXMPPSSLHostnameKey];
        uint32_t trustResultType = [error.userInfo[OTRXMPPSSLTrustResultKey] unsignedIntValue];
        
        [self showCertWarningForCertificateData:certData withHostname:hostname trustResultType:trustResultType];
    }
    else if(!self.certAlertView.isVisible){
        [super protocolLoginFailed:notification];
    }
}

- (void)showCertWarningForCertificateData:(NSData *)certData withHostname:(NSString *)hostname trustResultType:(SecTrustResultType)resultType {
    
    SecCertificateRef certificate = [OTRCertificatePinning certForData:certData];
    NSString * fingerprint = [OTRCertificatePinning sha1FingerprintForCertificate:certificate];
    NSString * message = [NSString stringWithFormat:@"%@\nSHA1: %@",hostname,fingerprint];
    NSUInteger length = [message length];
    
    UIColor * sslMessageColor;
    NSMutableAttributedString * attributedString = nil;
    
    self.certAlertView = [[SIAlertView alloc] initWithTitle:NEW_CERTIFICATE_STRING andMessage:nil];
    
    self.certAlertView.buttonColor = [UIColor whiteColor];
    
    if (![OTRCertificatePinning publicKeyWithCertData:certData]) {
        //no public key not able to save because won't be able evaluate later
        
        self.certAlertView.messageAttributedString = nil;
        message = [message stringByAppendingString:[NSString stringWithFormat:@"\nX %@",PUBLIC_KEY_ERROR_STRING]];
        attributedString = [[NSMutableAttributedString alloc] initWithString:message];
        sslMessageColor = [OTRColors redErrorColor];
        
        [self.certAlertView addButtonWithTitle:OK_STRING type:SIAlertViewButtonTypeCancel handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
    }
    else {
        if (resultType == kSecTrustResultProceed || resultType == kSecTrustResultUnspecified) {
            //#52A352
            sslMessageColor = [OTRColors greenNoErrorColor];
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n✓ %@",VALID_CERTIFICATE_STRING]];
        }
        else {
            NSString * sslErrorMessage = [OTRXMPPError errorStringWithTrustResultType:resultType];
            sslMessageColor = [OTRColors redErrorColor];
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\nX %@",sslErrorMessage]];
        }
        
        attributedString = [[NSMutableAttributedString alloc] initWithString:message];
        
        [self.certAlertView addButtonWithTitle:REJECT_STRING type:SIAlertViewButtonTypeDestructive handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        __weak OTRXMPPLoginViewController * weakSelf = self;
        [self.certAlertView addButtonWithTitle:SAVE_STRING type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:weakSelf.account];
            if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
                [OTRCertificatePinning addCertificate:[OTRCertificatePinning certForData:certData] withHostName:hostname];
                [weakSelf loginButtonPressed:alertView];
            }
        }];
    }
    
    NSRange errorMessageRange = NSMakeRange(length, message.length-length);
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, message.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:sslMessageColor range:errorMessageRange];
    
    self.certAlertView.messageAttributedString = attributedString;
    
    [self.certAlertView show];
    
    // For some reason we must show the alert view first,
    // THEN change the button style, otherwise the button doesn't appear.
    UIImage * normalImage = [UIImage imageNamed:@"button-green"];
    CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	UIImage * buttonImage = [normalImage resizableImageWithCapInsets:insets];
    
    [self.certAlertView setDefaultButtonImage:buttonImage forState:UIControlStateNormal];
    [self.certAlertView setDefaultButtonImage:buttonImage forState:UIControlStateHighlighted];
}

- (void)loginButtonPressed:(id)sender
{
    self.loginButtonPressed = YES;
    if([self isTorAccount]) {
        if([OTRTorManager sharedInstance].torManager.isConnected) {
            [super loginButtonPressed:sender];
        } else {
            if ([OTRTorManager sharedInstance].torManager.status == CPAStatusConnecting) {
                return;
            }
            [self showHUDWithText:CONNECTING_TO_TOR_STRING];
            [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
                // TODO: handle Tor/SOCKS setup error
                if (error) {
                    DDLogError(@"Error setting up Tor: %@", error);
                } else {
                    // successfully connected to Tor
                    [super loginButtonPressed:sender];
                }
            } progress:^(NSInteger progress, NSString *summaryString) {
                self.HUD.mode = MBProgressHUDModeDeterminate;
                self.HUD.labelText = summaryString;
                self.HUD.progress = progress/100.0;
            }];
        }
    } else {
        [super loginButtonPressed:sender];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
