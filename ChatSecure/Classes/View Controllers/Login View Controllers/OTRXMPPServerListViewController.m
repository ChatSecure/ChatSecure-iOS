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

@implementation OTRXMPPServerListViewController

@synthesize rowDescriptor = _rowDescriptor;

- (instancetype)init
{
    return [self initWithForm:[[self class] defaultServerForm]];
}


- (void)didSelectFormRow:(XLFormRowDescriptor *)formRow
{
    self.rowDescriptor.value = formRow.value;
    [self.navigationController popViewControllerAnimated:YES];
}

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
    
    
    return formDescriptor;
}

@end
