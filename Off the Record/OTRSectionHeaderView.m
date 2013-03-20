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
        titleLabelFrame.size.width -= 5.0;
        CGRectInset(titleLabelFrame, 0.0, 5.0);
        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        label.text = title;
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [label setShadowOffset:CGSizeMake(0, -2)];
        [self addSubview:label];
        _titleLabel = label;
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        // Create and configure the disclosure button.
        CGFloat viewHeight = self.bounds.size.height;
        CGFloat viewY = viewHeight/2-10.0;
        CGFloat viewX = self.bounds.size.width - 20 - viewY;
        
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(viewX, viewY, 20.0, 20.0);
        [button setImage:[OTRImages closeCaratImage] forState:UIControlStateNormal];
        [button setImage:[OTRImages openCaratImage] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        button.userInteractionEnabled = NO;
        [self addSubview:button];
        _disclosureButton = button;
        
        
        static NSMutableArray *colors = nil;
        if (colors == nil) {
            colors = [[NSMutableArray alloc] initWithCapacity:3];
            UIColor *color = nil;
            //color = [UIColor colorWithRed:0.82 green:0.84 blue:0.87 alpha:1.0];
            color = [UIColor colorWithWhite:.7 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
            //color = [UIColor colorWithRed:0.41 green:0.41 blue:0.59 alpha:1.0];
            color = [UIColor colorWithWhite:.4 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
            //color = [UIColor colorWithRed:0.41 green:0.41 blue:0.59 alpha:1.0];
            color = [UIColor colorWithWhite:.2 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
        }
        [(CAGradientLayer *)self.layer setColors:colors];
        [(CAGradientLayer *)self.layer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:1.0], nil]];
        
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
