//
//  OTRXMPPLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginViewController.h"
#import "OTRConstants.h"


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
    self.domainTextField.returnKeyType = UIReturnKeyDone;
    
    self.sslMismatchSwitch = [[UISwitch alloc]init];
    self.sslMismatchSwitch.on = [[[self.account accountDictionary] objectForKey:kOTRXMPPAccountAllowSSLHostNameMismatch] boolValue];
    
    self.selfSignedSwitch = [[UISwitch alloc] init];
    self.selfSignedSwitch.on = [[[self.account accountDictionary] objectForKey:kOTRXMPPAccountAllowSelfSignedSSLKey] boolValue];
    
    self.portTextField = [[UITextField alloc] init];
    self.portTextField.delegate = self;
    self.portTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.portTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.portTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.portTextField.placeholder = [NSString stringWithFormat:@"%@",[[self.account accountDictionary] objectForKey:kOTRXMPPAccountPortNumber]];
    self.portTextField.returnKeyType = UIReturnKeyDone;
    
    [self addCellinfoWithSection:1 row:0 labelText:DOMAIN_STRING cellType:kCellTypeTextField userInputView:self.domainTextField];
    [self addCellinfoWithSection:1 row:1 labelText:SSL_MISMATCH_STRING cellType:kCellTypeSwitch userInputView:self.sslMismatchSwitch];
    [self addCellinfoWithSection:1 row:2 labelText:SELF_SIGNED_SSL_STRING cellType:kCellTypeSwitch userInputView:self.selfSignedSwitch];
    [self addCellinfoWithSection:1 row:3 labelText:PORT_STRING cellType:kCellTypeTextField userInputView:self.portTextField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillShowNotification object:nil];

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

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    selectedCell = (UITableViewCell*) [[textField superview] superview];
    [self.loginViewTableView scrollToRowAtIndexPath:[self.loginViewTableView indexPathForCell:selectedCell] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    
    if(selectedCell)
    {
        [self.loginViewTableView scrollToRowAtIndexPath:[self.loginViewTableView indexPathForCell:selectedCell] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.domainTextField = nil;
    self.sslMismatchSwitch = nil;
    self.selfSignedSwitch = nil;
    self.portTextField = nil;
}


@end
