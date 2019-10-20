//
//  OTRPauseView.m
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRPauseView.h"
@import PureLayout;

@interface OTRPauseView ()

@property (nonatomic, strong) UIView *leftBar;
@property (nonatomic, strong) UIView *rigtBar;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRPauseView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.leftBar = [[UIView alloc] initForAutoLayout];
        self.rigtBar = [[UIView alloc] initForAutoLayout];
        
        self.containerView = [[UIView alloc] initForAutoLayout];
        
        [self addSubview:self.containerView];
        [self.containerView addSubview:self.leftBar];
        [self.containerView addSubview:self.rigtBar];
    }
    return self;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.leftBar.backgroundColor = color;
    self.rigtBar.backgroundColor = color;
}

- (void)updateConstraints
{
    [super updateConstraints];
    if (!self.addedConstraints) {
        
        [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.containerView autoCenterInSuperview];
        [self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.9];
        
        [self.leftBar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
        [self.rigtBar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeading];
        
        [self.rigtBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:0.4];
        [self.leftBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:0.4];
        
        self.addedConstraints = YES;
    }
}

@end
