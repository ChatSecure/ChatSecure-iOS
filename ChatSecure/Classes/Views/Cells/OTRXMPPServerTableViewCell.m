//
//  OTRXMPPServerTableViewCell.m
//  ChatSecure
//
//  Created by David Chiles on 5/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerTableViewCell.h"
#import "PureLayout.h"

NSString *const kOTRFormRowDescriptorTypeXMPPServer = @"kOTRFormRowDescriptorTypeXMPPServer";

@implementation OTRXMPPServerTableViewCellInfo

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OTRXMPPServerTableViewCellInfo class]]) {
        OTRXMPPServerTableViewCellInfo *info = object;
        if ([self.serverName isEqualToString:info.serverName] && [self.serverDomain isEqualToString:info.serverDomain]) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation OTRXMPPServerTableViewCell

+ (void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[self class] forKey:kOTRFormRowDescriptorTypeXMPPServer];
}

+ (CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 60;
}

- (void)configure
{
    [super configure];
    _serverImageView = [[UIImageView alloc] initForAutoLayout];
    _serverNameLabel = [[UILabel alloc] initForAutoLayout];
    _serverDomainLabel = [[UILabel alloc] initForAutoLayout];
    
    [self.contentView addSubview:self.serverImageView];
    [self.contentView addSubview:self.serverNameLabel];
    [self.contentView addSubview:self.serverDomainLabel];
    [self configureAutoLayout];
}

- (void)update
{
    [super update];
    OTRXMPPServerTableViewCellInfo *info = self.rowDescriptor.value;
    self.serverImageView.image = info.serverImage;
    self.serverNameLabel.text = info.serverName;
    self.serverDomainLabel.text = info.serverDomain;
}

- (void)formDescriptorCellDidSelectedWithFormController:(XLFormViewController *)controller
{
    UIViewController *controllerToPresent = [[self.rowDescriptor.action.viewControllerClass alloc] init];
    
    UIViewController<XLFormRowDescriptorViewController> *selectorViewController = (UIViewController<XLFormRowDescriptorViewController> *)controllerToPresent;
    selectorViewController.rowDescriptor = self.rowDescriptor;
    
    [controller.navigationController pushViewController:selectorViewController animated:YES];
    [controller.tableView deselectRowAtIndexPath:[controller.tableView indexPathForCell:self] animated:YES];
}

- (void)configureAutoLayout
{
    [self.serverImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
    [self.serverImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.serverImageView];
    
    CGFloat offset = 10;
    
    [self.serverNameLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.serverImageView withOffset:offset];
    [self.serverNameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.serverNameLabel.superview withOffset:offset];
    [self.serverNameLabel autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.serverNameLabel.superview withMultiplier:0.9];
    
    [self.serverDomainLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.serverImageView withOffset:offset];
    [self.serverDomainLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.serverNameLabel withOffset:offset/2];
    [self.serverDomainLabel autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.serverDomainLabel.superview withMultiplier:0.9];
}


@end
