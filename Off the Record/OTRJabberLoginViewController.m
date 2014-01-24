//
//  OTRJabberLoginViewController.m
//  Off the Record
//
//  Created by David on 10/20/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRJabberLoginViewController.h"

@interface OTRJabberLoginViewController ()

@property (nonatomic,strong) UITableViewCell * selectedCell;

@end

@implementation OTRJabberLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString * accountDomainString = self.account.domain;
	
    self.usernameTextField.placeholder = XMPP_USERNAME_EXAMPLE_STRING;
    self.usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
    
    self.domainTextField = [[UITextField alloc] init];
    self.domainTextField.delegate = self;
    self.domainTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.domainTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.domainTextField.placeholder = OPTIONAL_STRING;
    self.domainTextField.text = accountDomainString;
    self.domainTextField.returnKeyType = UIReturnKeyDone;
    self.domainTextField.keyboardType = UIKeyboardTypeURL;
    self.domainTextField.textColor = self.textFieldTextColor;
    
    self.portTextField = [[UITextField alloc] init];
    self.portTextField.delegate = self;
    self.portTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.portTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.portTextField.placeholder = [NSString stringWithFormat:@"%@",self.account.port];
    self.portTextField.returnKeyType = UIReturnKeyDone;
    self.portTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.portTextField.textColor = self.textFieldTextColor;
    
    [self addCellinfoWithSection:1 row:0 labelText:HOSTNAME_STRING cellType:kCellTypeTextField userInputView:self.domainTextField];
    [self addCellinfoWithSection:1 row:1 labelText:PORT_STRING cellType:kCellTypeTextField userInputView:self.portTextField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.portTextField) {
        return [string isEqualToString:@""] ||
        ([string stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].length > 0);
    }
    return YES;
}

-(void)readInFields
{
    [super readInFields];
        
    NSString * domainText = [self.domainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.account.domain = domainText;
        
    if([self.portTextField.text length])
    {
        int portNumber = [self.portTextField.text intValue];
        if (portNumber > 0 && portNumber <= 65535) {
            self.account.port = @(portNumber);
        } else {
            self.account.port = [OTRManagedXMPPAccount defaultPortNumber];
        }
    }
}

-(void)loginButtonPressed:(id)sender
{
    //If custom port set than a domain needs to be set to work with XMPPframework
    if([self.portTextField.text length] || self.account.portValue != [OTRManagedXMPPAccount defaultPortNumber].intValue)
    {
        int portNumber = [self.portTextField.text intValue];
        NSString * domainText = [self.domainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (portNumber == [OTRManagedXMPPAccount defaultPortNumber].intValue || [domainText length]) {
            [super loginButtonPressed:sender];
        }
        else {
            [self showAlertViewWithTitle:ERROR_STRING message:XMPP_PORT_FAIL_STRING error:nil];
        }
    }
    else
    {
        [super loginButtonPressed:sender];
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.selectedCell = (UITableViewCell*) [[textField superview] superview];
    [self.loginViewTableView scrollToRowAtIndexPath:[self.loginViewTableView indexPathForCell:self.selectedCell] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

-(void)keyboardWillHideOrShow:(NSNotification *)note
{
    [super keyboardWillHideOrShow:note];
    
    if(self.selectedCell)
    {
        [self.loginViewTableView scrollToRowAtIndexPath:[self.loginViewTableView indexPathForCell:self.selectedCell] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.domainTextField = nil;
    self.portTextField = nil;
    self.selectedCell = nil;
}


@end
