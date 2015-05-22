//
//  OTRXMPPServerListViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerListViewController.h"
#import "OTRXMPPServerTableViewCell.h"
#import "OTRImages.h"
#import "Strings.h"
#import "XLFormTextFieldCell.h"

NSString *const kOTROTRXMPPServerListViewControllerCustomTag = @"kOTROTRXMPPServerListViewControllerCustomTag";

@interface OTRXMPPServerListViewController ()

@property (nonatomic) BOOL selectedPreset;

@end

@implementation OTRXMPPServerListViewController

@synthesize rowDescriptor = _rowDescriptor;

- (instancetype)init
{
    return [self initWithForm:[[self class] defaultServerForm]];
}


- (void)didSelectFormRow:(XLFormRowDescriptor *)formRow
{
    if ([formRow.value isKindOfClass:[OTRXMPPServerTableViewCellInfo class]]) {
        self.rowDescriptor.value = formRow.value;
        self.selectedPreset = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSArray *rows = [[self.form formSectionAtIndex:0] formRows];
    BOOL foundMatch = NO;
    for (XLFormRowDescriptor *formRow in rows) {
        if ([self.rowDescriptor.value isEqual:formRow.value]) {
            foundMatch = YES;
            break;
        }
    }
    
    if (!foundMatch) {
        [self.form formRowWithTag:kOTROTRXMPPServerListViewControllerCustomTag].value = ((OTRXMPPServerTableViewCellInfo *)self.rowDescriptor.value).serverDomain;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!self.selectedPreset) {
        NSString *customDomain = [self.form formRowWithTag:kOTROTRXMPPServerListViewControllerCustomTag].value;
        if ([customDomain length]) {
            OTRXMPPServerTableViewCellInfo *info = (OTRXMPPServerTableViewCellInfo *)self.rowDescriptor.value;
            info.serverName = CUSTOM_STRING;
            info.serverDomain = customDomain;
            info.serverImage = nil;
        }
    }
    
}

#pragma - mark UITextFieldMethods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [super textFieldDidBeginEditing:textField];
    textField.returnKeyType = UIReturnKeyDone;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [self.tableView endEditing:YES];
    return YES;
}

#pragma - mark XLFromViewController

-(UIView *)inputAccessoryViewForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return nil;
}

#pragma - mark Class Methods

+ (XLFormDescriptor *)defaultServerForm
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"xmppServers" ofType:@"plist"];
    NSArray *domains = [NSArray arrayWithContentsOfFile:filePath];
    
    XLFormDescriptor *formDescriptor = [[XLFormDescriptor alloc] init];
    XLFormSectionDescriptor *sectionDescriptor = [[XLFormSectionDescriptor alloc] init];
    [formDescriptor addFormSection:sectionDescriptor];
    
    for (NSDictionary *domainDictionary in domains) {
        OTRXMPPServerTableViewCellInfo *cellInfo = [[OTRXMPPServerTableViewCellInfo alloc] init];
        cellInfo.serverName = domainDictionary[@"serverName"];
        cellInfo.serverDomain = domainDictionary[@"serverDomain"];
        cellInfo.serverImage = [OTRImages xmppServerImageWithName:domainDictionary[@"serverImage"]];
        
        XLFormRowDescriptor *rowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:nil rowType:kOTRFormRowDescriptorTypeXMPPServer];
        rowDescriptor.value = cellInfo;
        [sectionDescriptor addFormRow:rowDescriptor];
    }
    
    XLFormRowDescriptor *customRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTROTRXMPPServerListViewControllerCustomTag rowType:XLFormRowDescriptorTypeURL title:CUSTOM_STRING];
    
    [sectionDescriptor addFormRow:customRowDescriptor];
    
    
    return formDescriptor;
}

@end
