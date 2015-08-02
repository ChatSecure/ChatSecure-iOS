//
//  OTRXLFormCreator.m
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXLFormCreator.h"
#import "XLForm.h"
#import "OTRXMPPAccount.h"
#import "Strings.h"
#import "XMPPServerInfoCell.h"
#import "OTRImages.h"
#import "OTRXMPPServerListViewController.h"
#import "OTRXMPPServerInfo.h"

NSString *const kOTRXLFormUsernameTextFieldTag        = @"kOTRXLFormUsernameTextFieldTag";
NSString *const kOTRXLFormPasswordTextFieldTag        = @"kOTRXLFormPasswordTextFieldTag";
NSString *const kOTRXLFormRememberPasswordSwitchTag   = @"kOTRXLFormRememberPasswordSwitchTag";
NSString *const kOTRXLFormLoginAutomaticallySwitchTag = @"kOTRXLFormLoginAutomaticallySwitchTag";
NSString *const kOTRXLFormHostnameTextFieldTag        = @"kOTRXLFormHostnameTextFieldTag";
NSString *const kOTRXLFormPortTextFieldTag            = @"kOTRXLFormPortTextFieldTag";
NSString *const kOTRXLFormResourceTextFieldTag        = @"kOTRXLFormResourceTextFieldTag";
NSString *const kOTRXLFormXMPPServerTag               = @"kOTRXLFormXMPPServerTag";

@implementation OTRXLFormCreator

+ (XLFormDescriptor *)formForAccount:(OTRAccount *)account
{
    XLFormDescriptor *descriptor = [self formForAccountType:account.accountType createAccount:NO];
    
    [[descriptor formRowWithTag:kOTRXLFormUsernameTextFieldTag] setValue:account.username];
    [[descriptor formRowWithTag:kOTRXLFormPasswordTextFieldTag] setValue:account.password];
    [[descriptor formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] setValue:@(account.rememberPassword)];
    [[descriptor formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] setValue:@(account.autologin)];
    
    if([account isKindOfClass:[OTRXMPPAccount class]]) {
        OTRXMPPAccount *xmppAccount = (OTRXMPPAccount *)account;
        [[descriptor formRowWithTag:kOTRXLFormHostnameTextFieldTag] setValue:xmppAccount.domain];
        [[descriptor formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:@(xmppAccount.port)];
        [[descriptor formRowWithTag:kOTRXLFormResourceTextFieldTag] setValue:xmppAccount.resource];
    }
    
    return descriptor;
}

+ (XLFormDescriptor *)formForAccountType:(OTRAccountType)accountType createAccount:(BOOL)createAccount;
{
    XLFormDescriptor *descriptor = nil;
    if (createAccount) {
        descriptor = [[XLFormDescriptor alloc] initWithTitle:NSLocalizedString(@"Sign Up", @"title for creating a new account")];
        XLFormSectionDescriptor *basicSection = [XLFormSectionDescriptor formSectionWithTitle:nil];
        [basicSection addFormRow:[self usernameTextFieldRowDescriptorWithValue:nil]];
        [basicSection addFormRow:[self passwordTextFieldRowDescriptorWithValue:nil]];
        
        
        XLFormSectionDescriptor *serverSection = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Server", @"server selection section title")];
        serverSection.footerTitle = NSLocalizedString(@"Choose from our list of trusted servers, or bring your own.", @"server selection footer");
        [serverSection addFormRow:[self serverRowDescriptorWithValue:nil]];
        
        
        [descriptor addFormSection:basicSection];
        [descriptor addFormSection:serverSection];
        
        
    } else {
        descriptor = [[XLFormDescriptor alloc] initWithTitle:NSLocalizedString(@"Log In", @"title for logging in")];
        XLFormSectionDescriptor *basicSection = [XLFormSectionDescriptor formSectionWithTitle:BASIC_STRING];
        XLFormSectionDescriptor *advancedSection = [XLFormSectionDescriptor formSectionWithTitle:ADVANCED_STRING];
        
        switch (accountType) {
            case OTRAccountTypeJabber:
            case OTRAccountTypeXMPPTor:{
                [basicSection addFormRow:[self usernameTextFieldRowDescriptorWithValue:nil]];
                [basicSection addFormRow:[self passwordTextFieldRowDescriptorWithValue:nil]];
                [basicSection addFormRow:[self rememberPasswordRowDescriptorWithValue:YES]];
                [basicSection addFormRow:[self loginAutomaticallyRowDescriptorWithValue:NO]];
                
                [advancedSection addFormRow:[self hostnameRowDescriptorWithValue:nil]];
                [advancedSection addFormRow:[self portRowDescriptorWithValue:nil]];
                [advancedSection addFormRow:[self resourceRowDescriptorWithValue:nil]];
                
                break;
            }
            case OTRAccountTypeGoogleTalk: {
                XLFormRowDescriptor *usernameRow = [self usernameTextFieldRowDescriptorWithValue:nil];
                usernameRow.disabled = @(YES);
                
                [basicSection addFormRow:usernameRow];
                [basicSection addFormRow:[self loginAutomaticallyRowDescriptorWithValue:YES]];
                
                [advancedSection addFormRow:[self resourceRowDescriptorWithValue:nil]];
                
                break;
            }
                
            default:
                break;
        }
        
        [descriptor addFormSection:basicSection];
        [descriptor addFormSection:advancedSection];
    }
    return descriptor;
}

+ (XLFormDescriptor *)ChatSecureIDForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    XLFormRowDescriptor *usernameRow = [self usernameTextFieldRowDescriptorWithValue:nil];
    [usernameRow.cellConfigAtConfigure setObject:@"ChatSecure ID" forKey:@"textField.placeholder"];
    
    [section addFormRow:usernameRow];
    [form addFormSection:section];
    
    return form;
}

+ (XLFormRowDescriptor *)textfieldFormDescriptorType:(NSString *)type withTag:(NSString *)tag title:(NSString *)title placeHolder:(NSString *)placeholder value:(id)value
{
    XLFormRowDescriptor *textFieldDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:tag rowType:type title:title];
    textFieldDescriptor.value = value;
    if (placeholder) {
        [textFieldDescriptor.cellConfigAtConfigure setObject:placeholder forKey:@"textField.placeholder"];
    }
    
    return textFieldDescriptor;
}

+ (XLFormRowDescriptor *)usernameTextFieldRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *usernameDescriptor = [self textfieldFormDescriptorType:XLFormRowDescriptorTypeEmail withTag:kOTRXLFormUsernameTextFieldTag title:USERNAME_STRING placeHolder:XMPP_USERNAME_EXAMPLE_STRING value:value];
    usernameDescriptor.required = YES;
    return usernameDescriptor;
}

+ (XLFormRowDescriptor *)passwordTextFieldRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *passwordDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormPasswordTextFieldTag rowType:XLFormRowDescriptorTypePassword title:PASSWORD_STRING];
    passwordDescriptor.value = value;
    passwordDescriptor.required = YES;
    [passwordDescriptor.cellConfigAtConfigure setObject:REQUIRED_STRING forKey:@"textField.placeholder"];
    
    return passwordDescriptor;
}

+ (XLFormRowDescriptor *)rememberPasswordRowDescriptorWithValue:(BOOL)value
{
    XLFormRowDescriptor *switchDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormRememberPasswordSwitchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:REMEMBER_PASSWORD_STRING];
    switchDescriptor.value = @(value);
    
    return switchDescriptor;
}

+ (XLFormRowDescriptor *)loginAutomaticallyRowDescriptorWithValue:(BOOL)value
{
    XLFormRowDescriptor *loginDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormLoginAutomaticallySwitchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:LOGIN_AUTOMATICALLY_STRING];
    loginDescriptor.value = @(value);
    
    return loginDescriptor;
}

+ (XLFormRowDescriptor *)hostnameRowDescriptorWithValue:(NSString *)value
{
    return [self textfieldFormDescriptorType:XLFormRowDescriptorTypeURL withTag:kOTRXLFormHostnameTextFieldTag title:HOSTNAME_STRING placeHolder:OPTIONAL_STRING value:value];
}

+ (XLFormRowDescriptor *)portRowDescriptorWithValue:(NSNumber *)value
{
    NSString *defaultPortNumberString = [NSString stringWithFormat:@"%d",[OTRXMPPAccount defaultPort]];
    
    XLFormRowDescriptor *portRowDescriptor = [self textfieldFormDescriptorType:XLFormRowDescriptorTypeInteger withTag:kOTRXLFormPortTextFieldTag title:PORT_STRING placeHolder:defaultPortNumberString value:value];
    
    //Regex between 0 and 65536 for valid ports or empty
    [portRowDescriptor addValidator:[XLFormRegexValidator formRegexValidatorWithMsg:@"Incorect port number" regex:@"^$|^([1-9][0-9]{0,3}|[1-5][0-9]{0,4}|6[0-5]{0,2}[0-3][0-5])$"]];
    
    return portRowDescriptor;
}

+ (XLFormRowDescriptor *)resourceRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *resourceRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormResourceTextFieldTag rowType:XLFormRowDescriptorTypeText title:RESOURCE_STRING];
    resourceRowDescriptor.value = value;
    
    return resourceRowDescriptor;
}

+ (XLFormRowDescriptor *)serverRowDescriptorWithValue:(id)value
{
    XLFormRowDescriptor *xmppServerDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormXMPPServerTag rowType:kOTRFormRowDescriptorTypeXMPPServer];
    
    xmppServerDescriptor.value = [[OTRXMPPServerInfo defaultServerList] firstObject];
    xmppServerDescriptor.action.viewControllerClass = [OTRXMPPServerListViewController class];
    
    return xmppServerDescriptor;
}


@end
