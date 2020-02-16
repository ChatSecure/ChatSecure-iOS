//
//  OTRRememberPasswordView.m
//  Off the Record
//
//  Created by David Chiles on 5/6/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRRememberPasswordView.h"
@import OTRAssets;
@import PureLayout;


@interface OTRRememberPasswordView ()

@property (nonatomic, strong) UISwitch *rememberPasswordSwitch;
@property (nonatomic, strong) UILabel *rememberPasswordLabel;

@property (nonatomic) BOOL addedConstraints;


@end

@implementation OTRRememberPasswordView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
         ////// label //////
        self.rememberPasswordLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.rememberPasswordLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.rememberPasswordLabel.text = REMEMBER_PASSPHRASE_STRING();
        
        ////// switch //////
        self.rememberPasswordSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.rememberPasswordSwitch.on = YES;
        self.rememberPasswordSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.addedConstraints = NO;
        
        [self addSubview:self.rememberPasswordLabel];
        [self addSubview:self.rememberPasswordSwitch];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGFloat height = MAX(self.rememberPasswordLabel.frame.size.height, self.rememberPasswordSwitch.frame.size.height);
    CGFloat width = self.rememberPasswordSwitch.frame.size.width + self.rememberPasswordSwitch.frame.size.width + 2.0;
    return CGSizeMake(width, height);
}

- (BOOL)rememberPassword
{
    return self.rememberPasswordSwitch.on;
}

- (void)setRememberPassword:(BOOL)rememberPassword
{
    self.rememberPasswordSwitch.on = rememberPassword;
}

- (void)updateConstraints
{
    if (!self.addedConstraints) {
        
        [self.rememberPasswordLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rememberPasswordSwitch autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        [self.rememberPasswordLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.rememberPasswordSwitch autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.rememberPasswordLabel withOffset:0.0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.rememberPasswordSwitch autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0.0];
        self.addedConstraints = YES;
    }
    [super updateConstraints];
    
}

@end
