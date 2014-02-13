//
//  OTRSectionHeaderView.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRImages.h"
#import "OTRBuddyListSectionInfo.h"

@implementation OTRSectionHeaderView

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {

        self.userInteractionEnabled = YES;
        
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        
        self.discolureImageView = [[UIImageView alloc] initWithImage:[OTRSectionHeaderView caratImage]];
        self.frame = CGRectMake(0,0,12,12);
        self.discolureImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.discolureImageView];
        
        [self setupContraints];
    }
    return self;
}

- (void) setSectionInfo:(OTRBuddyListSectionInfo *)sectionInfo {
    _sectionInfo = sectionInfo;
    self.textLabel.text = sectionInfo.title;
    [self refreshDiscolureImageViewWithAnimation:NO];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1.0];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self toggle:self];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
}

- (void)refreshDiscolureImageViewWithAnimation:(BOOL)animation
{
    __weak OTRSectionHeaderView * weakSelf = self;
    NSTimeInterval interval = 0;
    if (animation) {
        interval = .2;
    }
    
    [UIView animateWithDuration:interval
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if (weakSelf.sectionInfo.isOpen) {
                             weakSelf.discolureImageView.transform = CGAffineTransformMakeRotation(0);
                         }
                         else {
                             weakSelf.discolureImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                         }
                     }
                     completion:nil];
}

- (void)toggle:(id)sender
{
    _sectionInfo.isOpen = !_sectionInfo.isOpen;
    
    [self refreshDiscolureImageViewWithAnimation:YES];
    
    __weak OTRSectionHeaderView * weakSelf = self;
    [UIView animateWithDuration:.2
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         weakSelf.contentView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
                         
                     }
                     completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(sectionHeaderViewChanged:)]) {
        [self.delegate sectionHeaderViewChanged:self];
    }
}

- (void)setupContraints
{
    ////////// DISCLOSURE BUTTON ///////////
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.discolureImageView
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:-12.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.discolureImageView
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

+ (NSString*) reuseIdentifier {
    return NSStringFromClass([self class]);
}

+ (UIImage*) caratImage {
    static UIImage *caratImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        caratImage = [OTRImages closeCaratImage];
    });
    return caratImage;
}

@end
