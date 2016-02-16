//
//  OTRBaseLoginViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBaseLoginViewController.h"
#import "OTRStrings.h"
#import "OTRColors.h"
#import "OTRCertificatePinning.h"
#import "OTRConstants.h"
#import "OTRXMPPError.h"
#import "OTRDatabaseManager.h"
#import "OTRAccount.h"
#import "MBProgressHUD.h"
#import "OTRXLFormCreator.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRXMPPServerInfo.h"
#import "OTRXMPPAccount.h"
@import OTRAssets;
#import "OTRLanguageManager.h"
#import "OTRInviteViewController.h"

@interface OTRBaseLoginViewController ()
@end

@implementation OTRBaseLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *checkImage = [UIImage imageNamed:@"ic-check" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    UIBarButtonItem *checkButton = [[UIBarButtonItem alloc] initWithImage:checkImage style:UIBarButtonItemStylePlain target:self action:@selector(loginButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = checkButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.showsCancelButton) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
    [self.createLoginHandler moveAccountValues:self.account intoForm:self.form];
    
    // We need to refresh the username row with the default selected server
    [self updateUsernameRow];
}

- (void)setAccount:(OTRAccount *)account
{
    _account = account;
    [self.createLoginHandler moveAccountValues:self.account intoForm:self.form];
}

- (void) cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginButtonPressed:(id)sender
{
    if ([self validForm]) {
        self.form.disabled = YES;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.backBarButtonItem.enabled = NO;
        [self.createLoginHandler performActionWithValidForm:self.form account:self.account completion:^(OTRAccount *account, NSError *error) {
            self.form.disabled = NO;
            self.navigationItem.rightBarButtonItem.enabled = YES;
            self.navigationItem.backBarButtonItem.enabled = YES;
            self.navigationItem.leftBarButtonItem.enabled = YES;
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (error) {
                [self handleError:error];
            } else {
                self.account = account;
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [self.account saveWithTransaction:transaction];
                }];
                
                // If push isn't enabled, prompt to enable it
                if ([PushController getPushPreference] == PushPreferenceEnabled) {
                    [self pushInviteViewController];
                } else {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:[OTRAssets resourcesBundle]];
                    EnablePushViewController *pushVC = [storyboard instantiateViewControllerWithIdentifier:@"enablePush"];
                    if (pushVC) {
                        pushVC.account = account;
                        [self.navigationController pushViewController:pushVC animated:YES];
                    } else {
                        [self pushInviteViewController];
                    }
                }
            }
        }];
    }
}

- (void) pushInviteViewController {
    OTRInviteViewController *inviteVC = [[OTRInviteViewController alloc] init];
    inviteVC.account = self.account;
    [self.navigationController pushViewController:inviteVC animated:YES];
}

- (BOOL)validForm
{
    BOOL validForm = YES;
    NSArray *formValidationErrors = [self formValidationErrors];
    if ([formValidationErrors count]) {
        validForm = NO;
    }
    
    [formValidationErrors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        XLFormValidationStatus * validationStatus = [[obj userInfo] objectForKey:XLValidationStatusErrorKey];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[self.form indexPathOfFormRow:validationStatus.rowDescriptor]];
        cell.backgroundColor = [UIColor orangeColor];
        [UIView animateWithDuration:0.3 animations:^{
            cell.backgroundColor = [UIColor whiteColor];
        }];
        
    }];
    return validForm;
}

- (void) updateUsernameRow {
    XLFormRowDescriptor *usernameRow = [self.form formRowWithTag:kOTRXLFormUsernameTextFieldTag];
    if (!usernameRow) {
        return;
    }
    NSMutableDictionary *username = [usernameRow.value mutableCopy];
    XLFormRowDescriptor *serverRow = [self.form formRowWithTag:kOTRXLFormXMPPServerTag];
    NSString *domain = nil;
    if (serverRow) {
        OTRXMPPServerInfo *serverInfo = serverRow.value;
        domain = serverInfo.domain;
    } else {
        OTRXMPPAccount *xmppAccount = (OTRXMPPAccount*)self.account;
        domain = xmppAccount.domain;
    }
    if (domain) {
        [username setObject:domain forKey:[OTRUsernameCell DomainKey]];
        usernameRow.value = username;
        [self updateFormRow:usernameRow];
    }
}

#pragma mark XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue
{
    [super formRowDescriptorValueHasChanged:formRow oldValue:oldValue newValue:newValue];
    if (formRow.tag == kOTRXLFormXMPPServerTag) {
        [self updateUsernameRow];
    }
}

 #pragma - mark Errors and Alert Views

- (void)handleError:(NSError *)error
{
    //show xmpp erors, cert errors, tor errors, oauth errors.
    if (error.code == OTRXMPPSSLError) {
        NSData * certData = error.userInfo[OTRXMPPSSLCertificateDataKey];
        NSString * hostname = error.userInfo[OTRXMPPSSLHostnameKey];
        uint32_t trustResultType = [error.userInfo[OTRXMPPSSLTrustResultKey] unsignedIntValue];
        
        [self showCertWarningForCertificateData:certData withHostname:hostname trustResultType:trustResultType];
    }
    else {
        [self handleXMPPError:error];
    }
}

- (void)handleXMPPError:(NSError *)error
{
    [self showAlertViewWithTitle:ERROR_STRING message:XMPP_FAIL_STRING error:error];
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertAction * okButtonItem = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertController * alertController = nil;
        if (error) {
            UIAlertAction * infoButton = [UIAlertAction actionWithTitle:INFO_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString * errorDescriptionString = [NSString stringWithFormat:@"%@ : %@",[error domain],[error localizedDescription]];
                NSString *xmlErrorString = error.userInfo[OTRXMPPXMLErrorKey];
                if (xmlErrorString) {
                    errorDescriptionString = [errorDescriptionString stringByAppendingFormat:@"\n\n%@", xmlErrorString];
                }
                
                if ([[error domain] isEqualToString:@"kCFStreamErrorDomainSSL"]) {
                    NSString * sslString = [OTRXMPPError errorStringWithSSLStatus:(OSStatus)error.code];
                    if ([sslString length]) {
                        errorDescriptionString = [errorDescriptionString stringByAppendingFormat:@"\n%@",sslString];
                    }
                }
                
                
                UIAlertAction * copyButtonItem = [UIAlertAction actionWithTitle:COPY_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString * copyString = [NSString stringWithFormat:@"Domain: %@\nCode: %ld\nUserInfo: %@",[error domain],(long)[error code],[error userInfo]];
                    
                    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                    [pasteBoard setString:copyString];
                }];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:INFO_STRING message:errorDescriptionString preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:okButtonItem];
                [alert addAction:copyButtonItem];
                [self presentViewController:alert animated:YES completion:nil];
            }];
            
            alertController = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:okButtonItem];
            [alertController addAction:infoButton];
        }
        else {
            alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:okButtonItem];
        }
        
        if (alertController) {
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
}


- (void)showCertWarningForCertificateData:(NSData *)certData withHostname:(NSString *)hostname trustResultType:(SecTrustResultType)resultType {
    
    SecCertificateRef certificate = [OTRCertificatePinning certForData:certData];
    NSString * fingerprint = [OTRCertificatePinning sha256FingerprintForCertificate:certificate];
    NSString * message = [NSString stringWithFormat:@"%@\n\nSHA256\n%@",hostname,fingerprint];
    
    UIAlertController *certAlert = [UIAlertController alertControllerWithTitle:NEW_CERTIFICATE_STRING message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    if (![OTRCertificatePinning publicKeyWithCertData:certData]) {
        //no public key not able to save because won't be able evaluate later
        
        message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\nX %@",PUBLIC_KEY_ERROR_STRING]];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleCancel handler:nil];
        [certAlert addAction:action];
    }
    else {
        if (resultType == kSecTrustResultProceed || resultType == kSecTrustResultUnspecified) {
            //#52A352
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n✓ %@",VALID_CERTIFICATE_STRING]];
        }
        else {
            NSString * sslErrorMessage = [OTRXMPPError errorStringWithTrustResultType:resultType];
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\nX %@",sslErrorMessage]];
        }
        
        UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:REJECT_STRING style:UIAlertActionStyleDestructive handler:nil];
        [certAlert addAction:rejectAction];
        
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:SAVE_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [OTRCertificatePinning addCertificate:[OTRCertificatePinning certForData:certData] withHostName:hostname];
            [self loginButtonPressed:nil];
        }];
        [certAlert addAction:saveAction];
    }
    
    certAlert.message = message;
    
    [self presentViewController:certAlert animated:YES completion:nil];
}

#pragma - mark Class Methods

+ (instancetype)loginViewControllerForAccount:(OTRAccount *)account
{
    OTRBaseLoginViewController *baseLoginViewController = [[self alloc] initWithForm:[OTRXLFormCreator formForAccount:account] style:UITableViewStyleGrouped];
    baseLoginViewController.account = account;
    baseLoginViewController.createLoginHandler = [OTRLoginHandler loginHandlerForAccount:account];
    
    return baseLoginViewController;
}

@end
