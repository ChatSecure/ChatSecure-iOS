//
//  OTRSectionHeaderView.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSectionHeaderView.h"

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
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _titleLabel = label;
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        // Create and configure the disclosure button.
        CGFloat viewHeight = self.bounds.size.height;
        CGFloat viewY = viewHeight/2-10.0;
        CGFloat viewX = self.bounds.size.width - 20 - viewY;
        
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(viewX, viewY, 20.0, 20.0);
        [button setImage:[UIImage imageNamed:@"carat.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"carat-open.png"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        _disclosureButton = button;
        
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
