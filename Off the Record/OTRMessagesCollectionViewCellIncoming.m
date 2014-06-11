//
//  OTRMessagesCollectionViewCellIncoming.m
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesCollectionViewCellIncoming.h"

@implementation OTRMessagesCollectionViewCellIncoming

#pragma mark - Overrides

- (void)setupConstraints
{
    [super setupConstraints];
    
    NSDictionary *views = @{@"errorImageView":self.errorImageView,@"deliveredImageView":self.deliveredImageView,@"lockImageView":self.lockImageView};
    NSDictionary *metrics = @{@"margin":@(6)};
    
    [self.leftRightView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(margin)-[lockImageView][deliveredImageView][errorImageView]-(>=0)-|" options:0 metrics:metrics views:views]];
    
    
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([OTRMessagesCollectionViewCellIncoming class])
                          bundle:[NSBundle mainBundle]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([OTRMessagesCollectionViewCellIncoming class]);
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentLeft;
    self.cellBottomLabel.textAlignment = NSTextAlignmentLeft;
}

@end
