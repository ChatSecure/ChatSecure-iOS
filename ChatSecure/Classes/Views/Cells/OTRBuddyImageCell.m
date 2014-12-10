//
//  OTRBuddyImageCell.m
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"
#import "OTRBuddy.h"
#import "OTRImages.h"
#import "OTRColors.h"
#import "PureLayout.h"

const CGFloat OTRBuddyImageCellPadding = 12.0;

@interface OTRBuddyImageCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic) BOOL addedConstraints;

@end


@implementation OTRBuddyImageCell

@synthesize imageViewBorderColor = _imageViewBorderColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.avatarImageView = [[UIImageView alloc] initWithImage:[self defaultImage]];
        self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        CALayer *cellImageLayer = self.avatarImageView.layer;
        [cellImageLayer setBorderWidth:2.0];
        
        [cellImageLayer setMasksToBounds:YES];
        [cellImageLayer setBorderColor:[self.imageViewBorderColor CGColor]];
        [self.contentView addSubview:self.avatarImageView];
        self.addedConstraints = NO;
    }
    return self;
}

- (UIColor *)imageViewBorderColor
{
    if (!_imageViewBorderColor) {
        _imageViewBorderColor = [UIColor blackColor];
    }
    return _imageViewBorderColor;
}

- (void)setImageViewBorderColor:(UIColor *)imageViewBorderColor
{
    _imageViewBorderColor = imageViewBorderColor;
    
    [self.avatarImageView.layer setBorderColor:[_imageViewBorderColor CGColor]];
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    if(buddy.avatarImage) {
        self.avatarImageView.image = buddy.avatarImage;
    }
    else {
        self.avatarImageView.image = [self defaultImage];
    }
    UIColor *statusColor =  [OTRColors colorWithStatus:buddy.status];
    self.imageViewBorderColor = statusColor;
    [self.contentView setNeedsUpdateConstraints];
}

- (UIImage *)defaultImage
{
    return [UIImage imageNamed:@"person"];
}

- (void)updateConstraints
{
    if (!self.addedConstraints) {
        [self.avatarImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(OTRBuddyImageCellPadding, OTRBuddyImageCellPadding, OTRBuddyImageCellPadding, OTRBuddyImageCellPadding) excludingEdge:ALEdgeTrailing];
        [self.avatarImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.avatarImageView];
        
        self.addedConstraints = YES;
    }
    [super updateConstraints];
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
