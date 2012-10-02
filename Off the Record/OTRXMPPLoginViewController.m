//
//  OTRXMPPLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginViewController.h"


@interface OTRXMPPLoginViewController ()

@end

@implementation OTRXMPPLoginViewController

@synthesize domainTextField;
@synthesize sslMismatchSwitch;
@synthesize selfSignedSwitch;
@synthesize portTextField;

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
    
    NSString * accountDomainString = [[self.account accountDictionary] objectForKey:kOTRAccountDomainKey];
	
    self.usernameTextField.placeholder = @"user@example.com";
    
    self.domainTextField = [[UITextField alloc] init];
    self.domainTextField.delegate = self;
    self.domainTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.domainTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.domainTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.domainTextField.placeholder = OPTIONAL_STRING;
    self.domainTextField.text = accountDomainString;
    
    self.sslMismatchSwitch = [[UISwitch alloc]init];
    self.selfSignedSwitch = [[UISwitch alloc] init];
    
    self.portTextField = [[UITextField alloc] init];
    self.portTextField.delegate = self;
    self.portTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.portTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.portTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.portTextField.placeholder = [NSString stringWithFormat:@"%@",[[self.account accountDictionary] objectForKey:kOTRXMPPAccountPortNumber]];
    
    [self addCellinfoWithSection:1 row:0 labelText:DOMAIN_STRING cellType:kCellTypeTextField userInputView:self.domainTextField];
    [self addCellinfoWithSection:1 row:1 labelText:SSL_MISMATCH_STRING cellType:kCellTypeSwitch userInputView:self.sslMismatchSwitch];
    [self addCellinfoWithSection:1 row:2 labelText:SELF_SIGNED_SSL_STRING cellType:kCellTypeSwitch userInputView:self.selfSignedSwitch];
    [self addCellinfoWithSection:1 row:3 labelText:PORT_STRING cellType:kCellTypeTextField userInputView:self.portTextField];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == portTextField) {
        return [string isEqualToString:@""] ||
        ([string stringByTrimmingCharactersInSet:
          [[NSCharacterSet decimalDigitCharacterSet] invertedSet]].length > 0);
    }
    return YES;
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

-(void)readInFields
{
    [super readInFields];
    if([self.account isKindOfClass:[OTRXMPPAccount class]])
    {
        ((OTRXMPPAccount *)self.account).allowSelfSignedSSL = selfSignedSwitch.on;
        ((OTRXMPPAccount *)self.account).allowSSLHostNameMismatch = sslMismatchSwitch.on;
        
         NSString * domainText = [domainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        ((OTRXMPPAccount *)self.account).domain = domainText;
        int portNumber = [self.portTextField.text intValue];
        if (portNumber > 0 && portNumber <= 65535) {
             ((OTRXMPPAccount *)self.account).port = portNumber;
        } else {
             ((OTRXMPPAccount *)self.account).port = [OTRXMPPAccount defaultPortNumber];
        }
    }
}


@end
