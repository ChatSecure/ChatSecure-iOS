//
//  OTRAudioTrashView.m
//  ChatSecure
//
//  Created by David Chiles on 4/8/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioTrashView.h"
@import PureLayout;
#import "OTRColors.h"
#import "OTRCircleView.h"

CGFloat const kOTRAudioTrashMargin = 10;

@interface OTRAudioTrashView ()

@property (nonatomic, strong) NSLayoutConstraint *animatingViewSizeConstraint;

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRAudioTrashView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _animatingSoundView = [[OTRCircleView alloc] initForAutoLayout];
        _animatingSoundView.backgroundColor = [UIColor grayColor];
        
        _trashButton = [[BButton alloc] initWithFrame:CGRectZero
                                                 type:BButtonTypeDefault
                                                style:BButtonStyleBootstrapV3];
        
        _trashLabel = [[UILabel alloc] initForAutoLayout];
        self.trashLabel.textAlignment = NSTextAlignmentCenter;
        self.trashLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.trashLabel.text = NSLocalizedString(@"Swipe up to delete", @"");
        
        CGFloat fontSize = 25;
        
        _trashIconLabel = [[UILabel alloc] initForAutoLayout];
        self.trashIconLabel.textAlignment = NSTextAlignmentCenter;
        self.trashIconLabel.text = [NSString fa_stringForFontAwesomeIcon:FATrash];
        self.trashIconLabel.font = [UIFont fontWithName:kFontAwesomeFont size:fontSize];
        self.trashIconLabel.textColor = [OTRColors redErrorColor];
        self.trashIconLabel.alpha = 0;
        
        _microphoneIconLabel = [[UILabel alloc] initForAutoLayout];
        self.microphoneIconLabel.textAlignment = NSTextAlignmentCenter;
        self.microphoneIconLabel.text = [NSString fa_stringForFontAwesomeIcon:FAMicrophone];
        self.microphoneIconLabel.font = [UIFont fontWithName:kFontAwesomeFont size:fontSize];
        
        [self addSubview:self.animatingSoundView];
        [self addSubview:self.trashButton];
        [self addSubview:self.trashIconLabel];
        [self addSubview:self.microphoneIconLabel];
        [self addSubview:self.trashLabel];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGFloat width = MAX(self.trashButton.intrinsicContentSize.width, self.trashLabel.intrinsicContentSize.width);
    CGFloat height = self.trashButton.intrinsicContentSize.height + (self.trashLabel.intrinsicContentSize.height + kOTRAudioTrashMargin*2) *2;
    return CGSizeMake(width, height);
}

- (void)updateConstraints{
    if (!self.addedConstraints) {
        [self.animatingSoundView autoCenterInSuperview];
        self.animatingViewSizeConstraint = [self.animatingSoundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.trashButton withOffset:kOTRAudioTrashMargin];
        [self.animatingSoundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.animatingSoundView];
        
        [self.trashButton autoCenterInSuperview];
        [self.trashButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:(self.trashLabel.intrinsicContentSize.height + kOTRAudioTrashMargin *2)];
        [self.trashButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.trashButton];
        
        [self.trashLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.trashLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        
        [self.trashIconLabel autoCenterInSuperview];
        [self.microphoneIconLabel autoCenterInSuperview];
        
        self.addedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.animatingSoundView.layer.cornerRadius = CGRectGetWidth(self.animatingSoundView.bounds)/ 2;
    self.trashButton.buttonCornerRadius = @(CGRectGetWidth(self.trashButton.bounds)/2);
}

- (void)setAnimationChange:(double)change
{
    self.animatingViewSizeConstraint.constant = kOTRAudioTrashMargin + change;
    [self setNeedsUpdateConstraints];
}

@end
