//
//  OTRCircleButtonView.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRCircleButtonView.h"
@import PureLayout;

@interface OTRCircleButtonView()
@property (nonatomic) BOOL hasAddedConstraints;
@end

@implementation OTRCircleButtonView

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupButtonsWithTitle:nil image:nil];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
                         title:(NSString*)title
                         image:(UIImage*)image
                     imageSize:(CGSize)imageSize
                    circleSize:(CGSize)circleSize
                   actionBlock:(dispatch_block_t)actionBlock {
    if (self = [super initWithFrame:frame]) {
        _circleSize = circleSize;
        _imageSize = imageSize;
        if (actionBlock) {
            _actionBlock = [actionBlock copy];
        }
        [self setupButtonsWithTitle:title image:image];
        [self addDefaultConstraints];
    }
    return self;
}

- (void) setupButtonsWithTitle:(NSString*)title image:(UIImage*)image {
    [self setupImageButtonWithImage:image circleSize:self.circleSize];
    
    _labelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.labelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.labelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    UIFont *font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline] size:0];
    [self.labelButton.titleLabel setFont:font];
    [self.labelButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.labelButton setTitle:title forState:UIControlStateNormal];
    [self addSubview:self.labelButton];
}

- (void) setupImageButtonWithImage:(UIImage*)image circleSize:(CGSize)circleSize {
    _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.imageButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.imageButton.imageView setContentMode: UIViewContentModeScaleAspectFit];
    self.imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.imageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    self.circleView = [[UIView alloc] initForAutoLayout];
    self.circleView.layer.mask = [self layerForCircleMaskWithSize:circleSize];
    self.circleView.backgroundColor = [UIColor lightGrayColor];
    [self.imageButton setImage:image forState:UIControlStateNormal];
    [self addSubview:self.circleView];
    [self.circleView addSubview:self.imageButton];
}

- (void) addDefaultConstraints {
    if (self.hasAddedConstraints) {
        return;
    }
    NSParameterAssert(self.imageButton);
    NSParameterAssert(self.labelButton);
    NSParameterAssert(self.circleView);
    [self.circleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.circleView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.labelButton];
    [self.circleView autoSetDimensionsToSize:self.circleSize];
    [self.imageButton autoSetDimensionsToSize:self.imageSize];
    [self.imageButton autoCenterInSuperview];
    [self.labelButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.circleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.labelButton withOffset:0];
    self.hasAddedConstraints = YES;
}

- (void) buttonPressed:(id)sender {
    if (self.actionBlock) {
        self.actionBlock();
    }
}

- (CAShapeLayer*) layerForCircleMaskWithSize:(CGSize)size {
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGFloat diameter = MIN(width, height);
    
    CGFloat x = (width - diameter) / 2;
    CGFloat y = (height - diameter) / 2;
    
    CAShapeLayer *circleShapeLayer = [[CAShapeLayer alloc] init];
    circleShapeLayer.path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(x, y, diameter, diameter)].CGPath;
    return circleShapeLayer;
}

- (CGSize) intrinsicContentSize {
    CGSize labelButtonSize = [self.labelButton systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGSize circleSize = [self.circleView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat width = MAX(labelButtonSize.width, circleSize.width);
    CGFloat height = labelButtonSize.height + circleSize.height;
    CGSize size = CGSizeMake(width, height);
    return size;
}

@end
