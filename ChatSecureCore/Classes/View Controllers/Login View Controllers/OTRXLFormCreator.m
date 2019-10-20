//
//  OTRXLFormCreator.m
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXLFormCreator.h"
@import XLForm;
#import "OTRXMPPAccount.h"
@import OTRAssets;
#import "XMPPServerInfoCell.h"
#import "OTRImages.h"
#import "OTRXMPPServerListViewController.h"
#import "OTRXMPPServerInfo.h"
#import "ChatSecureCoreCompat-Swift.h"

#import "OTRXMPPTorAccount.h"

NSString *const kOTRXLFormCustomizeUsernameSwitchTag        = @"kOTRXLFormCustomizeUsernameSwitchTag";
NSString *const kOTRXLFormNicknameTextFieldTag        = @"kOTRXLFormNicknameTextFieldTag";
NSString *const kOTRXLFormUsernameTextFieldTag        = @"kOTRXLFormUsernameTextFieldTag";
NSString *const kOTRXLFormPasswordTextFieldTag        = @"kOTRXLFormPasswordTextFieldTag";
NSString *const kOTRXLFormRememberPasswordSwitchTag   = @"kOTRXLFormRememberPasswordSwitchTag";
NSString *const kOTRXLFormLoginAutomaticallySwitchTag = @"kOTRXLFormLoginAutomaticallySwitchTag";
NSString *const kOTRXLFormHostnameTextFieldTag        = @"kOTRXLFormHostnameTextFieldTag";
NSString *const kOTRXLFormPortTextFieldTag            = @"kOTRXLFormPortTextFieldTag";
NSString *const kOTRXLFormResourceTextFieldTag        = @"kOTRXLFormResourceTextFieldTag";
NSString *const kOTRXLFormXMPPServerTag               = @"kOTRXLFormXMPPServerTag";

NSString *const kOTRXLFormShowAdvancedTag               = @"kOTRXLFormShowAdvancedTag";

NSString *const kOTRXLFormGenerateSecurePasswordTag               = @"kOTRXLFormGenerateSecurePasswordTag";

NSString *const kOTRXLFormUseTorTag               = @"kOTRXLFormUseTorTag";
NSString *const kOTRXLFormAutomaticURLFetchTag               = @"kOTRXLFormAutomaticURLFetchTag";


@implementation XLFormDescriptor (OTRAccount)

+ (instancetype) existingAccountFormWithAccount:(OTRAccount *)account
{
    XLFormDescriptor *descriptor = [self formForAccountType:account.accountType createAccount:NO];
    
    [[descriptor formRowWithTag:kOTRXLFormUsernameTextFieldTag] setValue:account.username];
    [[descriptor formRowWithTag:kOTRXLFormPasswordTextFieldTag] setValue:account.password];
    [[descriptor formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] setValue:@(account.rememberPassword)];
    [[descriptor formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] setValue:@(account.autologin)];
    
    if([account isKindOfClass:[OTRXMPPAccount class]]) {
        OTRXMPPAccount *xmppAccount = (OTRXMPPAccount *)account;
        [[descriptor formRowWithTag:kOTRXLFormNicknameTextFieldTag] setValue:xmppAccount.displayName];
        [[descriptor formRowWithTag:kOTRXLFormHostnameTextFieldTag] setValue:xmppAccount.domain];
        [[descriptor formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:@(xmppAccount.port)];
        [[descriptor formRowWithTag:kOTRXLFormResourceTextFieldTag] setValue:xmppAccount.resource];
        if (account.accountType == OTRAccountTypeJabber) {
            XLFormRowDescriptor *torRow = [descriptor formRowWithTag:kOTRXLFormUseTorTag];
            torRow.hidden = @YES;
        }
        [[descriptor formRowWithTag:kOTRXLFormAutomaticURLFetchTag] setValue:@(!xmppAccount.disableAutomaticURLFetching)];
    }
    if (account.accountType == OTRAccountTypeXMPPTor) {
        XLFormRowDescriptor *torRow = [descriptor formRowWithTag:kOTRXLFormUseTorTag];
        torRow.value = @YES;
        torRow.disabled = @YES;
        XLFormRowDescriptor *autologin = [descriptor formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag];
        autologin.value = @NO;
        autologin.disabled = @YES;
        XLFormRowDescriptor *autofetch = [descriptor formRowWithTag:kOTRXLFormAutomaticURLFetchTag];
        autofetch.value = @NO;
        autofetch.disabled = @YES;
    }
    
    return descriptor;
}

+ (instancetype) registerNewAccountFormWithAccountType:(OTRAccountType)accountType {
    return [self formForAccountType:accountType createAccount:YES];
}

+ (instancetype) existingAccountFormWithAccountType:(OTRAccountType)accountType {
    return [self formForAccountType:accountType createAccount:NO];
}

+ (XLFormDescriptor *)formForAccountType:(OTRAccountType)accountType createAccount:(BOOL)createAccount
{
    XLFormDescriptor *descriptor = nil;
    XLFormRowDescriptor *nicknameRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormNicknameTextFieldTag rowType:XLFormRowDescriptorTypeText title:Nickname_String()];
    
    if (createAccount) {
        descriptor = [XLFormDescriptor formDescriptorWithTitle:SIGN_UP_STRING()];
        descriptor.assignFirstResponderOnShow = YES;
        
        XLFormSectionDescriptor *basicSection = [XLFormSectionDescriptor formSectionWithTitle:Basic_Setup()];
        basicSection.footerTitle = Basic_Setup_Hint();
        nicknameRow.required = YES;
        [basicSection addFormRow:nicknameRow];
        
        XLFormSectionDescriptor *showAdvancedSection = [XLFormSectionDescriptor formSectionWithTitle:nil];
        XLFormRowDescriptor *showAdvancedRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormShowAdvancedTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:Show_Advanced_Options()];
        showAdvancedRow.value = @0;
        [showAdvancedSection addFormRow:showAdvancedRow];
        
        XLFormSectionDescriptor *accountSection = [XLFormSectionDescriptor formSectionWithTitle:ACCOUNT_STRING()];
        accountSection.footerTitle = Generate_Secure_Password_Hint();
        accountSection.hidden = [NSString stringWithFormat:@"$%@==0", kOTRXLFormShowAdvancedTag];
        XLFormRowDescriptor *generatePasswordRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormGenerateSecurePasswordTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:Generate_Secure_Password()];
        generatePasswordRow.value = @1;
        XLFormRowDescriptor *customizeUsernameRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormCustomizeUsernameSwitchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:Customize_Username()];
        customizeUsernameRow.value = @0;
        XLFormRowDescriptor *passwordRow = [self passwordTextFieldRowDescriptorWithValue:nil];
        passwordRow.hidden = [NSString stringWithFormat:@"$%@==1", kOTRXLFormGenerateSecurePasswordTag];
        XLFormRowDescriptor *usernameRow = [self usernameTextFieldRowDescriptorWithValue:nil];
        usernameRow.hidden = [NSString stringWithFormat:@"$%@==0", kOTRXLFormCustomizeUsernameSwitchTag];
        [accountSection addFormRow:customizeUsernameRow];
        [accountSection addFormRow:usernameRow];
        [accountSection addFormRow:generatePasswordRow];
        [accountSection addFormRow:passwordRow];
        
        XLFormSectionDescriptor *serverSection = [XLFormSectionDescriptor formSectionWithTitle:Server_String()];
        if (![OTRBranding shouldShowServerCell]) {
            serverSection.hidden = [NSString stringWithFormat:@"$%@==0", kOTRXLFormShowAdvancedTag];
        }

        serverSection.footerTitle = Server_String_Hint();
        [serverSection addFormRow:[self serverRowDescriptorWithValue:nil]];
        
        XLFormSectionDescriptor *torSection = [XLFormSectionDescriptor formSectionWithTitle:@"Tor"];
        torSection.footerTitle = TOR_WARNING_MESSAGE_STRING();
        torSection.hidden = [NSString stringWithFormat:@"$%@==0", kOTRXLFormShowAdvancedTag];
        [torSection addFormRow:[self torRowDescriptorWithValue:NO]];
        
        XLFormSectionDescriptor *otherSection = [XLFormSectionDescriptor formSectionWithTitle:OTHER_STRING()];
        otherSection.footerTitle = AUTO_URL_FETCH_WARNING_STRING();
        otherSection.hidden = [NSString stringWithFormat:@"$%@==0", kOTRXLFormShowAdvancedTag];
        [otherSection addFormRow:[self autoFetchRowDescriptorWithValue:YES]];
        
        [descriptor addFormSection:basicSection];
        [descriptor addFormSection:serverSection];
        [descriptor addFormSection:showAdvancedSection];
        [descriptor addFormSection:accountSection];
        if (OTRBranding.torEnabled) {
            [descriptor addFormSection:torSection];
        }
        [descriptor addFormSection:otherSection];
    } else {
        descriptor = [XLFormDescriptor formDescriptorWithTitle:LOGIN_STRING()];
        XLFormSectionDescriptor *basicSection = [XLFormSectionDescriptor formSectionWithTitle:BASIC_STRING()];
        XLFormSectionDescriptor *advancedSection = [XLFormSectionDescriptor formSectionWithTitle:ADVANCED_STRING()];
        
        [nicknameRow.cellConfigAtConfigure setObject:OPTIONAL_STRING() forKey:@"textField.placeholder"];
        [basicSection addFormRow:nicknameRow];
        
        switch (accountType) {
            case OTRAccountTypeJabber:
            case OTRAccountTypeXMPPTor:{
                [basicSection addFormRow:[self jidTextFieldRowDescriptorWithValue:nil]];
                [basicSection addFormRow:[self passwordTextFieldRowDescriptorWithValue:nil]];
                [basicSection addFormRow:[self rememberPasswordRowDescriptorWithValue:YES]];
                [basicSection addFormRow:[self loginAutomaticallyRowDescriptorWithValue:YES]];
                
                [advancedSection addFormRow:[self hostnameRowDescriptorWithValue:nil]];
                [advancedSection addFormRow:[self portRowDescriptorWithValue:@([OTRXMPPAccount defaultPort])]];
                [advancedSection addFormRow:[self resourceRowDescriptorWithValue:[OTRXMPPAccount newResource]]];
                if (OTRBranding.torEnabled) {
                    [advancedSection addFormRow:[self torRowDescriptorWithValue:NO]];
                }
                [advancedSection addFormRow:[self autoFetchRowDescriptorWithValue:YES]];
                
                break;
            }
            case OTRAccountTypeGoogleTalk: {
                XLFormRowDescriptor *usernameRow = [self jidTextFieldRowDescriptorWithValue:nil];
                usernameRow.disabled = @(YES);
                
                [basicSection addFormRow:usernameRow];
                [basicSection addFormRow:[self loginAutomaticallyRowDescriptorWithValue:YES]];
                
                [advancedSection addFormRow:[self resourceRowDescriptorWithValue:nil]];
                [advancedSection addFormRow:[self autoFetchRowDescriptorWithValue:YES]];
                
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

+ (XLFormRowDescriptor *)textfieldFormDescriptorType:(NSString *)type withTag:(NSString *)tag title:(NSString *)title placeHolder:(NSString *)placeholder value:(id)value
{
    XLFormRowDescriptor *textFieldDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:tag rowType:type title:title];
    textFieldDescriptor.value = value;
    if (placeholder) {
        [textFieldDescriptor.cellConfigAtConfigure setObject:placeholder forKey:@"textField.placeholder"];
    }
    
    return textFieldDescriptor;
}

+ (XLFormRowDescriptor *)jidTextFieldRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *usernameDescriptor = [self textfieldFormDescriptorType:XLFormRowDescriptorTypeEmail withTag:kOTRXLFormUsernameTextFieldTag title:USERNAME_STRING() placeHolder:XMPP_USERNAME_EXAMPLE_STRING() value:value];
    usernameDescriptor.value = value;
    usernameDescriptor.required = YES;
    [usernameDescriptor addValidator:[[OTRUsernameValidator alloc] init]];
    return usernameDescriptor;
}

+ (XLFormRowDescriptor *)usernameTextFieldRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *usernameDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormUsernameTextFieldTag rowType:[OTRUsernameCell defaultRowDescriptorType] title:USERNAME_STRING()];
    usernameDescriptor.value = value;
    usernameDescriptor.required = YES;
    [usernameDescriptor addValidator:[[OTRUsernameValidator alloc] init]];
    return usernameDescriptor;
}

+ (XLFormRowDescriptor *)passwordTextFieldRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *passwordDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormPasswordTextFieldTag rowType:XLFormRowDescriptorTypePassword title:PASSWORD_STRING()];
    passwordDescriptor.value = value;
    passwordDescriptor.required = YES;
    [passwordDescriptor.cellConfigAtConfigure setObject:REQUIRED_STRING() forKey:@"textField.placeholder"];
    
    return passwordDescriptor;
}

+ (XLFormRowDescriptor *)rememberPasswordRowDescriptorWithValue:(BOOL)value
{
    XLFormRowDescriptor *switchDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormRememberPasswordSwitchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:REMEMBER_PASSWORD_STRING()];
    switchDescriptor.value = @(value);
    
    return switchDescriptor;
}

+ (XLFormRowDescriptor *)loginAutomaticallyRowDescriptorWithValue:(BOOL)value
{
    XLFormRowDescriptor *loginDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormLoginAutomaticallySwitchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:LOGIN_AUTOMATICALLY_STRING()];
    loginDescriptor.value = @(value);
    
    return loginDescriptor;
}

+ (XLFormRowDescriptor *)hostnameRowDescriptorWithValue:(NSString *)value
{
    return [self textfieldFormDescriptorType:XLFormRowDescriptorTypeURL withTag:kOTRXLFormHostnameTextFieldTag title:HOSTNAME_STRING() placeHolder:OPTIONAL_STRING() value:value];
}

+ (XLFormRowDescriptor *)portRowDescriptorWithValue:(NSNumber *)value
{
    NSString *defaultPortNumberString = [NSString stringWithFormat:@"%d",[OTRXMPPAccount defaultPort]];
    
    XLFormRowDescriptor *portRowDescriptor = [self textfieldFormDescriptorType:XLFormRowDescriptorTypeInteger withTag:kOTRXLFormPortTextFieldTag title:PORT_STRING() placeHolder:defaultPortNumberString value:value];
    
    //Regex between 0 and 65536 for valid ports or empty
    [portRowDescriptor addValidator:[XLFormRegexValidator formRegexValidatorWithMsg:@"Incorect port number" regex:@"^$|^([1-9][0-9]{0,3}|[1-5][0-9]{0,4}|6[0-5]{0,2}[0-3][0-5])$"]];
    
    return portRowDescriptor;
}

+ (XLFormRowDescriptor*) autoFetchRowDescriptorWithValue:(BOOL)value {
    XLFormRowDescriptor *autoFetchRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormAutomaticURLFetchTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:AUTO_URL_FETCH_STRING()];
    autoFetchRow.value = @(value);
    return autoFetchRow;
}

+ (XLFormRowDescriptor*) torRowDescriptorWithValue:(BOOL)value {
    XLFormRowDescriptor *torRow = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormUseTorTag rowType:XLFormRowDescriptorTypeBooleanSwitch title:Enable_Tor_String()];
    torRow.value = @(value);
    return torRow;
}

+ (XLFormRowDescriptor *)resourceRowDescriptorWithValue:(NSString *)value
{
    XLFormRowDescriptor *resourceRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormResourceTextFieldTag rowType:XLFormRowDescriptorTypeText title:RESOURCE_STRING()];
    resourceRowDescriptor.value = value;
    
    return resourceRowDescriptor;
}

+ (XLFormRowDescriptor *)serverRowDescriptorWithValue:(OTRXMPPServerInfo *)value
{
    XLFormRowDescriptor *xmppServerDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTRXLFormXMPPServerTag rowType:kOTRFormRowDescriptorTypeXMPPServer];
    if (!value) {
        value = [[OTRXMPPServerInfo defaultServerList] firstObject];
    }
    xmppServerDescriptor.value = value;
    xmppServerDescriptor.action.viewControllerClass = [OTRXMPPServerListViewController class];
    
    return xmppServerDescriptor;
}


@end
