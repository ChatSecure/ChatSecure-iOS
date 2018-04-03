//
//  OTRTitleSubtitleView.m
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRTitleSubtitleView.h"
#import "OTRUtilities.h"

@import PureLayout;

static const CGFloat kOTRMaxImageViewHeight = 6;

@interface OTRTitleSubtitleView ()

@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UILabel * subtitleLabel;

@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *subtitleImageView;

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRTitleSubtitleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.addedConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = YES;
        
        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
        self.subtitleLabel.backgroundColor = [UIColor clearColor];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.subtitleLabel.font = [UIFont systemFontOfSize:11];
        
        self.titleImageView = [[UIImageView alloc] initForAutoLayout];
        self.subtitleImageView = [[UIImageView alloc] initForAutoLayout];
        
        [self addSubview:self.titleImageView];
        [self addSubview:self.subtitleImageView];
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.subtitleLabel];
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)updateConstraints {
    if (!self.addedConstraints) {
        [self setupContraints];
        self.addedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setupContraints {
    
    /////////TITLE LABEL ////////////////
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.6];
    [self.titleLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.9 relation:NSLayoutRelationLessThanOrEqual];
    
    ///////////// SUBTITLE LABEL /////////////
    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:-4];
    
    ////// TITLE IMAGEVIEW //////
    [self setupConstraintsWithImageView:self.titleImageView withLabel:self.titleLabel];
    
    ////// SUBTITILE IMAGEVIEW //////
    [self setupConstraintsWithImageView:self.subtitleImageView withLabel:self.subtitleLabel];
    
    //Keeps imgeviews the same or simlar with titleImageView > subtitleImageView
    [self.subtitleImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleImageView withMultiplier:1.0 relation:NSLayoutRelationLessThanOrEqual];
}

- (void)setupConstraintsWithImageView:(UIImageView *)imageView withLabel:(UILabel *)label
{

    //Keeps trailing edge off of leading edge of label by at least 2
    [imageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:label withOffset:-5.0];
    //Keep centered horizontaly
    [imageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:label];
    
    //Keep leading edge inside superview
    [imageView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    
    //Less than equal to height of label
    [imageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:label withOffset:0 relation:NSLayoutRelationLessThanOrEqual];
    //Less than equal to max height
    [imageView autoSetDimension:ALDimensionHeight toSize:kOTRMaxImageViewHeight relation:NSLayoutRelationLessThanOrEqual];
    
    //Square ImageView
    [imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:imageView];
}

@end
