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

@implementation OTRSectionHeaderView

@synthesize titleLabel=_titleLabel;
@synthesize disclosureButton=_disclosureButton;
@synthesize delegate=_delegate;
@synthesize section=_section;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame title:(NSString *)title section:(NSUInteger)sectionNumber delegate:(id<OTRSectionHeaderViewDelegate>)delegate
{
    if(self = [super initWithFrame:frame])
    {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle:)];
        [self addGestureRecognizer:tapGesture];
        self.userInteractionEnabled = YES;
        
        _delegate = delegate;
        _section = sectionNumber;
        
        CGRect titleLabelFrame = self.bounds;
        titleLabelFrame.origin.x += 10.0;
        titleLabelFrame.size.width -= 30.0;
        titleLabelFrame.size.height -= 4;
        titleLabelFrame.origin.y = roundf((self.bounds.size.height - titleLabelFrame.size.height)/2.0)-2;
        CGRectInset(titleLabelFrame, 0.0, 5.0);
        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        label.text = title;
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [label setShadowOffset:CGSizeMake(0, 1)];
        [label setShadowColor:[UIColor whiteColor]];
        [self addSubview:label];
        _titleLabel = label;
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        // Create and configure the disclosure button.
        CGFloat viewY = self.center.y-10;
        CGFloat viewX = self.bounds.size.width - 20 - viewY;
        
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(viewX, viewY, 20.0, 20.0);
        [button setImage:[OTRImages closeCaratImage] forState:UIControlStateNormal];
        [button setImage:[OTRImages openCaratImage] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        button.userInteractionEnabled = NO;
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:button];
        _disclosureButton = button;
        
        UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
        UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
        UIColor* fillColor2 = [UIColor colorWithRed: 0.769 green: 0.769 blue: 0.769 alpha: 1];
        NSArray* gradientColors = [NSArray arrayWithObjects:
                                   (id)fillColor.CGColor,
                                   (id)[UIColor colorWithRed: 0.884 green: 0.884 blue: 0.884 alpha: 1].CGColor,
                                   (id)fillColor2.CGColor,
                                   (id)[UIColor colorWithRed: 0.384 green: 0.384 blue: 0.384 alpha: 1].CGColor,
                                   (id)strokeColor.CGColor, nil];
        [(CAGradientLayer *)self.layer setColors:gradientColors];
        [(CAGradientLayer *)self.layer setLocations:@[[NSNumber numberWithFloat:0.03],[NSNumber numberWithFloat:0.03],[NSNumber numberWithFloat:0.97],[NSNumber numberWithFloat:0.97],[NSNumber numberWithFloat:0.99]]];
        
    }
    return self;
}

-(void)toggle:(id)sender
{
    self.disclosureButton.selected = !self.disclosureButton.selected;
    
    if ([self.delegate respondsToSelector:@selector(sectionHeaderView:section:opened:)]) {
        [self.delegate sectionHeaderView:self section:self.section opened:!self.disclosureButton.selected];
    }
    
}

+ (Class)layerClass {
    
    return [CAGradientLayer class];
}

@end
