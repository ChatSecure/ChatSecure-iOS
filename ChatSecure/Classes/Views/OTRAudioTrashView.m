//
//  OTRAudioTrashView.m
//  ChatSecure
//
//  Created by David Chiles on 4/8/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioTrashView.h"
#import "PureLayout.h"
#import "OTRColors.h"

CGFloat const kOTRAudioTrashMargin = 10;

@interface OTRAudioTrashView ()

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRAudioTrashView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        _trashButton = [[BButton alloc] initWithFrame:CGRectZero
                                                     type:BButtonTypeDefault
                                                    style:BButtonStyleBootstrapV3
                                                     icon:FAMicrophone
                                                 fontSize:25];
        [self.trashButton setTitle:[NSString fa_stringForFontAwesomeIcon:FATrash]
                          forState:UIControlStateHighlighted];
        [self.trashButton setTitleColor:[OTRColors redErrorColor]
                               forState:UIControlStateHighlighted];
        
        self.trashButton.buttonCornerRadius = @(25);
        
        _trashLabel = [[UILabel alloc] initForAutoLayout];
        self.trashLabel.textAlignment = NSTextAlignmentCenter;
        self.trashLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.trashLabel.text = @"Swipe up to delete";
        
        [self addSubview:self.trashButton];
        [self addSubview:self.trashLabel];
    }
    return self;
}


- (CGSize)intrinsicContentSize
{
    CGFloat width = MAX(self.trashButton.intrinsicContentSize.width, self.trashLabel.intrinsicContentSize.width);
    CGFloat height = self.trashButton.intrinsicContentSize.height + (self.trashLabel.intrinsicContentSize.height + kOTRAudioTrashMargin) *2;
    return CGSizeMake(width, height);
}

- (void)updateConstraints{
    if (!self.addedConstraints) {
        
        [self.trashButton autoCenterInSuperview];
        [self.trashButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:(self.trashLabel.intrinsicContentSize.height + kOTRAudioTrashMargin)];
        [self.trashButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.trashButton];
        [self.trashButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.trashLabel withOffset:kOTRAudioTrashMargin];
        
        [self.trashLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.trashLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    }
    [super updateConstraints];
}

@end
