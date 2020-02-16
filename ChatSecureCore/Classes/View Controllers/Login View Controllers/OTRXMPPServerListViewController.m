//
//  OTRXMPPServerListViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerListViewController.h"
#import "XMPPServerInfoCell.h"
#import "OTRImages.h"
@import OTRAssets;
@import XLForm;
#import "OTRXMPPServerInfo.h"
#import "NSURL+ChatSecure.h"

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
    if ([formRow.value isKindOfClass:[OTRXMPPServerInfo class]]) {
        self.rowDescriptor.value = formRow.value;
        self.selectedPreset = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark View Lifecycle

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
        [self.form formRowWithTag:kOTROTRXMPPServerListViewControllerCustomTag].value = ((OTRXMPPServerInfo *)self.rowDescriptor.value).domain;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!self.selectedPreset) {
        NSString *customDomain = [self.form formRowWithTag:kOTROTRXMPPServerListViewControllerCustomTag].value;
        if ([customDomain length]) {
            OTRXMPPServerInfo *info = [[OTRXMPPServerInfo alloc] initWithDomain:customDomain];
            self.rowDescriptor.value = info;
        }
    }
}

#pragma - mark UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    XMPPServerInfoCell *infoCell = nil;
    // This is required for the XMPPServerInfoCell buttons to work
    if ([cell isKindOfClass:[XMPPServerInfoCell class]]) {
        infoCell = (XMPPServerInfoCell*)cell;
        [infoCell setupWithParentViewController:self];
    }
    return cell;
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
    NSArray *serverList = [OTRXMPPServerInfo defaultServerList];
    
    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptorWithTitle:Choose_Server_String()];
    XLFormSectionDescriptor *sectionDescriptor = [[XLFormSectionDescriptor alloc] init];
    [formDescriptor addFormSection:sectionDescriptor];
    
    for (OTRXMPPServerInfo *serverInfo in serverList) {
        XLFormRowDescriptor *rowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:nil rowType:kOTRFormRowDescriptorTypeXMPPServer];
        rowDescriptor.value = serverInfo;
        [sectionDescriptor addFormRow:rowDescriptor];
    }
    
    XLFormRowDescriptor *customRowDescriptor = [XLFormRowDescriptor formRowDescriptorWithTag:kOTROTRXMPPServerListViewControllerCustomTag rowType:XLFormRowDescriptorTypeURL title:CUSTOM_STRING()];
    [customRowDescriptor.cellConfigAtConfigure setObject:@"example.com" forKey:@"textField.placeholder"];
    
    [sectionDescriptor addFormRow:customRowDescriptor];
    
    
    return formDescriptor;
}

@end
