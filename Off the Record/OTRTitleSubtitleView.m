//
//  OTRTitleSubtitleView.m
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRTitleSubtitleView.h"
#import "OTRUtilities.h"

@implementation OTRTitleSubtitleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = YES;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.subtitleLabel.backgroundColor = [UIColor clearColor];
        
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
            self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            self.subtitleLabel.font = [UIFont boldSystemFontOfSize:12];
        }
        else {
            self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
            self.titleLabel.textColor = [UIColor whiteColor];
            self.titleLabel.shadowColor = [UIColor darkGrayColor];
            self.titleLabel.shadowOffset = CGSizeMake(0, -1);
            
            self.subtitleLabel.font = [UIFont boldSystemFontOfSize:13];
            self.subtitleLabel.textColor = [UIColor whiteColor];
            self.subtitleLabel.shadowColor = [UIColor darkGrayColor];
            self.subtitleLabel.shadowOffset = CGSizeMake(0, -1);
            self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
        }
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.subtitleLabel];
        
        [self setupContraints];
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)setupContraints {
    
    /////////TITLE LABEL ////////////////
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:0.6
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:0.9
                                               constant:0.0];
    [self addConstraint:constraint];
    
    ///////////// SUBTITLE LABEL /////////////
    
    constraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.titleLabel
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
