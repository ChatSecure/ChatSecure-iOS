//
//  OTRBuddyImageCell.m
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"
#import "OTRManagedBuddy.h"
#import "OTRImages.h"
#import "OTRColors.h"

const CGFloat OTRBuddyImageCellPadding = 12.0;

@interface OTRBuddyImageCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;

@end


@implementation OTRBuddyImageCell

@synthesize imageViewBorderColor = _imageViewBorderColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.avatarImageView = [[UIImageView alloc] initWithImage:[self defaultImage]];
        self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        CALayer *cellImageLayer = self.avatarImageView.layer;
        [cellImageLayer setBorderWidth:1.0];
        
        [cellImageLayer setMasksToBounds:YES];
        [cellImageLayer setBorderColor:[self.imageViewBorderColor CGColor]];
        [self.contentView addSubview:self.avatarImageView];
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

- (void)setBuddy:(OTRManagedBuddy *)buddy
{
    if(buddy.photo) {
        self.avatarImageView.image = buddy.photo;
    }
    else {
        self.avatarImageView.image = [self defaultImage];
    }
    UIColor *statusColor =  [OTRColors colorWithStatus:buddy.currentStatusValue];
    self.imageViewBorderColor = statusColor;
    
}

- (UIImage *)defaultImage
{
    return [UIImage imageNamed:@"person"];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    NSDictionary *views = @{@"imageView":self.avatarImageView};
    NSDictionary *metrics = @{@"margin":@(OTRBuddyImageCellPadding)};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[imageView]" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[imageView]-margin-|" options:0 metrics:metrics views:views]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarImageView
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.avatarImageView
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1.0
                                                                  constant:0.0]];
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
