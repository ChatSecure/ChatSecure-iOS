//
//  OTRBuddyApprovalCell.m
//  ChatSecure
//
//  Created by Chris Ballinger on 6/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyApprovalCell.h"

@import OTRAssets;
@import PureLayout;

@implementation OTRBuddyApprovalCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGFloat fontSize = 20.0f;
        self.approveButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeSuccess style:BButtonStyleBootstrapV3 icon:FACheck fontSize:fontSize];
        self.denyButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDanger style:BButtonStyleBootstrapV3 icon:FATimes fontSize:fontSize];
        [self.contentView addSubview:self.approveButton];
        [self.contentView addSubview:self.denyButton];
        [self.approveButton addTarget:self action:@selector(approveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.denyButton addTarget:self action:@selector(denyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setThread:(id<OTRThreadOwner>)thread
{
    [super setThread:thread];
    
    NSString * name = [thread threadName];
    
    self.nameLabel.text = name;
    self.identifierLabel.text = [NSString stringWithFormat:@"%@ %@", name, WANTS_TO_CHAT_STRING()];
}

- (void)updateConstraints
{
    
    if (!self.addedConstraints) {
        CGSize size = CGSizeMake(35, 35);
        [self.approveButton autoSetDimensionsToSize:size];
        [self.approveButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.denyButton withOffset:-OTRBuddyImageCellPadding];
        [self.approveButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.denyButton autoSetDimensionsToSize:size];
        [self.denyButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:OTRBuddyImageCellPadding];
        [self.denyButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    }
    [super updateConstraints];
}

- (void) approveButtonPressed:(id)sender {
    if (self.actionBlock) {
        self.actionBlock(self, YES);
    }
}

- (void) denyButtonPressed:(id)sender {
    if (self.actionBlock) {
        self.actionBlock(self, NO);
    }
}

@end
