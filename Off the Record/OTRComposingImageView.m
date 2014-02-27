//
//  OTRComposingImageView.m
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRComposingImageView.h"

#import "OTRImages.h"
#import "OTRColors.h"
#import "OTRColorFadingDotView.h"

@interface OTRComposingImageView ()

@property (nonatomic) BOOL blinking;

@property (nonatomic,strong) NSArray * dots;
@property (nonatomic,strong) NSArray * spaces;

@end

@implementation OTRComposingImageView

- (id)initWithImage:(UIImage *)image
{
    if (self = [super initWithImage:image]) {
        CGFloat radius = 4.0;
        NSInteger numDots = 3;
        NSTimeInterval animationDuration = .5;
        UIColor * startColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1];
        UIColor * endColor = [UIColor colorWithRed:0.59 green:0.59 blue:0.59 alpha:1];
        
        NSMutableArray * tempArray = [NSMutableArray array];
        for (NSInteger index = 0; index < numDots; index++) {
            OTRColorFadingDotView * dot = [[OTRColorFadingDotView alloc] initWithColor:startColor radius:radius];
            dot.animateToColor = endColor;
            dot.animationDuration = animationDuration;
            dot.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:dot];
            [tempArray addObject:dot];
        }
        self.dots = [NSArray arrayWithArray:tempArray];

        tempArray = [NSMutableArray array];
        for (NSInteger index = 0; index < numDots-1; index++) {
            UIView * space = [[UIView alloc] initWithFrame:CGRectZero];
            space.backgroundColor = [UIColor clearColor];
            space.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:space];
            [tempArray addObject:space];
        }
        self.spaces = [NSArray arrayWithArray:tempArray];
      
        [self setupConstraints];
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (NSLayoutConstraint *)centerConstraintForView:(UIView *)view
{
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    return constraint;
}

- (void)startBlinking {
    
    [self.dots enumerateObjectsUsingBlock:^(OTRColorFadingDotView * dot, NSUInteger idx, BOOL *stop) {
        [dot startColorAnimationWithDelay:idx*.3];
    }];
    self.blinking = YES;
}

- (void)stopBlinking {
    
    [self.dots enumerateObjectsUsingBlock:^(OTRColorFadingDotView * dot, NSUInteger idx, BOOL *stop) {
        [dot stopColorAnimation];
    }];
    self.blinking = NO;
}

- (void)setupConstraints
{
    CGFloat rightSideBuffer = 12;
    CGFloat leftSideBuffer = rightSideBuffer + 6.0;
    
    NSLayoutConstraint * constraint;
    if (self.dots.count > 1 && self.spaces.count == self.dots.count-1) {
        [self.dots enumerateObjectsUsingBlock:^(UIView * dot, NSUInteger idx, BOOL *stop) {
            NSLayoutConstraint * constraint;
            
            
            if (idx == 0) {
                //First Dot on left buffer
                constraint = [NSLayoutConstraint constraintWithItem:dot
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:leftSideBuffer];
                [self addConstraint:constraint];
            }
            else if (idx == self.dots.count-1) {
                //Last Dot on right buffer
                constraint = [NSLayoutConstraint constraintWithItem:dot
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:-1*rightSideBuffer];
                [self addConstraint:constraint];
                
            }
            
            //Center dot on Y-axis
            constraint = [self centerConstraintForView:dot];
            [self addConstraint:constraint];
            
            if (idx<self.spaces.count) {
                UIView * space = self.spaces[idx];
                //center space on Y-Axis
                NSLayoutConstraint * constraint = [self centerConstraintForView:space];
                [self addConstraint:constraint];
                
                constraint = [NSLayoutConstraint constraintWithItem:space
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:dot
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0];
                [self addConstraint:constraint];
                
                constraint = [NSLayoutConstraint constraintWithItem:space
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.dots[idx+1]
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0];
                [self addConstraint:constraint];
                
                if (idx<self.spaces.count-1) {
                    //all spaces should be equal
                    constraint = [NSLayoutConstraint constraintWithItem:space
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.spaces[idx+1]
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:1.0
                                                               constant:0.0];
                    [self addConstraint:constraint];
                }
                
            }
            
            
            
        }];
    }
    else if(self.dots.count){
        //only one dot
        UIView * dot = [self.dots firstObject];
        constraint = [self centerConstraintForView:dot];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:dot
                                                  attribute:NSLayoutAttributeCenterX
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self
                                                  attribute:NSLayoutAttributeCenterX
                                                 multiplier:1.0
                                                   constant:6.0];
        [self addConstraint:constraint];
        
    }
}





@end
