//
//  OTRColorFadingDotImageView.m
//  Off the Record
//
//  Created by David Chiles on 1/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRColorFadingDotView.h"
#import "OTRImages.h"

@interface OTRColorFadingDotView ()

@property (nonatomic) CGFloat radius;
@property (nonatomic,strong) UIColor * originalColor;

@end

@implementation OTRColorFadingDotView

- (instancetype)initWithColor:(UIColor *)color radius:(CGFloat)radius
{
    
    if (self = [self initWithFrame:CGRectMake(0, 0, radius*2, radius*2)]) {
        UIImage * circle = [OTRImages circleWithRadius:radius];
        self.backgroundColor = self.originalColor = color;
        self.radius = radius;
        CALayer *maskLayer = [CALayer layer];
        [maskLayer setBounds:[self bounds]];
        [maskLayer setPosition:CGPointMake([self bounds].size.width/2.0,
                                           [self bounds].size.height/2.0)];
        UIImage *mask = circle;
        maskLayer.contents = (id)mask.CGImage;
        
        self.layer.mask = maskLayer;
    }
    return self;
}

- (void)startColorAnimationWithDelay:(NSTimeInterval)delay
{
    [UIView animateWithDuration:self.animationDuration
                          delay:delay
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionBeginFromCurrentState
                     animations:^
    {
        self.backgroundColor = self.animateToColor;
    }
                     completion:nil
     ];
}

- (void)stopColorAnimation
{
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:self.animationDuration
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^
     {
         self.backgroundColor = self.originalColor;
     }
                     completion:nil
     ];
}

-(void)updateConstraints
{
    [super updateConstraints];
    
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0
                                                                    constant:self.radius*2];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1.0
                                               constant:self.radius*2];
    [self addConstraint:constraint];
}

@end
