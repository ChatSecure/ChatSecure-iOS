//
//  JKParentTableViewCell.m
//  ExpandTableView
//
//  Created by Jack Kwok on 7/5/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import "JKParentTableViewCell.h"

@implementation JKParentTableViewCell

@synthesize label,iconImage,selectionIndicatorImgView,parentIndex,selectionIndicatorImg;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier; {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [[self contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    if(!self) {
        return self;
    }
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.iconImage = [[UIImageView alloc] initWithFrame:CGRectZero];
    //[self.iconImage setContentMode:UIViewContentModeCenter];
    [self.contentView addSubview:iconImage];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.textColor = [UIColor darkTextColor];
    label.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:label];
    
    self.selectionIndicatorImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    //[self.selectionIndicatorImgView setContentMode:UIViewContentModeCenter];
    [self.contentView addSubview:selectionIndicatorImgView];
    
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    [self setupDisplay];
}

- (void)setupDisplay {
    CGRect contentRect = [self bounds];
    CGFloat contentAreaWidth = self.contentView.bounds.size.width;
    CGFloat contentAreaHeight = self.contentView.bounds.size.height;
    CGFloat checkMarkHeight = 0.0;
    CGFloat checkMarkWidth = 0.0;
    CGFloat iconHeight = 0.0; //  set this according to icon
    CGFloat iconWidth = 0.0;
    if (self.iconImage.image) {
        iconWidth = MIN(contentAreaWidth, self.iconImage.image.size.width);
        iconHeight = MIN(contentAreaHeight, self.iconImage.image.size.height);
    }
    if (self.selectionIndicatorImgView.image) {
        checkMarkWidth = MIN(contentAreaWidth, self.selectionIndicatorImgView.image.size.width);
        checkMarkHeight = MIN(contentAreaHeight, self.selectionIndicatorImgView.image.size.height);
    }
    
    CGFloat sidePadding = 6.0;
    CGFloat icon2LabelPadding = 6.0;
    CGFloat checkMarkPadding = 16.0;
    [self.contentView setAutoresizesSubviews:YES];

    self.iconImage.frame = CGRectMake(sidePadding, (contentAreaHeight - iconHeight)/2, iconWidth, iconHeight);
    CGFloat XOffset = iconWidth + sidePadding + icon2LabelPadding;
    
    CGFloat labelWidth = contentAreaWidth - XOffset - checkMarkWidth - checkMarkPadding;
    self.label.frame = CGRectMake(XOffset, 0, labelWidth, contentAreaHeight);
    //self.label.backgroundColor = [UIColor redColor];
    self.selectionIndicatorImgView.frame = CGRectMake(contentAreaWidth - checkMarkWidth - checkMarkPadding,
                                                 (contentRect.size.height/2)-(checkMarkHeight/2),
                                                 checkMarkWidth,
                                                 checkMarkHeight);
}

- (void)rotateIconToExpanded {
    [UIView beginAnimations:@"rotateDisclosure" context:nil];
    [UIView setAnimationDuration:0.2];
    iconImage.transform = CGAffineTransformMakeRotation(M_PI * 2.5);
    [UIView commitAnimations];
}

- (void)rotateIconToCollapsed {
    [UIView beginAnimations:@"rotateDisclosure" context:nil];
    [UIView setAnimationDuration:0.2];
    iconImage.transform = CGAffineTransformMakeRotation(M_PI * 2);
    [UIView commitAnimations];
}

- (void)selectionIndicatorState:(BOOL) visible {
    //
    if (!self.selectionIndicatorImg) {
        self.selectionIndicatorImg = [UIImage imageNamed:@"checkmark"];
    }
    self.selectionIndicatorImgView.image = self.selectionIndicatorImg;  // probably better to init this elsewhere
    if (visible) {
        self.selectionIndicatorImgView.hidden = NO;
    } else {
        self.selectionIndicatorImgView.hidden = YES;
    }
}

- (void)setCellForegroundColor:(UIColor *) foregroundColor {
    self.label.textColor = foregroundColor;
}

- (void)setCellBackgroundColor:(UIColor *) backgroundColor {
    self.contentView.backgroundColor = backgroundColor;
}

@end
