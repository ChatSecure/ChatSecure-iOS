//
//  OTREncryptionDropdown.m
//  Off the Record
//
//  Created by David Chiles on 2/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRButtonView.h"
@import PureLayout;


CGFloat const kOTRButtonViewTopMargin = 3;

@interface OTRButtonView ()

@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) NSArray *spaces;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView * buttonView;
@property (nonatomic, strong) UIToolbar *backgroundToolbar;
@property (nonatomic) BOOL addedContraints;

@end

@implementation OTRButtonView

- (id)initWithTitle:(NSString *)title buttons:(NSArray *)buttons
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.addedContraints = NO;
        self.buttons = buttons;
        self.titleLabel = [[self class] defaultTitleLabel];
        self.titleLabel.text = title;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        self.backgroundToolbar.barStyle = UIBarStyleDefault;
        self.backgroundToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.backgroundToolbar];
        
        [self addSubview:self.titleLabel];
        self.buttonView = [self emptyView];
        [self addSubview:self.buttonView];
        
        NSMutableArray * tempSpaces = [NSMutableArray array];
        [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
            UIView * view = [self emptyView];
            [self.buttonView addSubview:view];
            [tempSpaces addObject:view];
            
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [self.buttonView addSubview:button];
        }];
        UIView * view = [self emptyView];
        [self.buttonView addSubview:view];
        [tempSpaces addObject:view];
        
        self.spaces = [NSArray arrayWithArray:tempSpaces];
    }
    return self;
}

- (UIView *)emptyView;
{
    UIView * view = [[UIView alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

- (NSArray *)constraintsWithButtons:(NSArray *)buttons
{
    NSMutableArray * constraints = [NSMutableArray array];
    __block UIButton * previousButton = nil;
    __block UIView * previousPadding = nil;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton * button, NSUInteger idx, BOOL *stop) {
        UIView * padding = self.spaces[idx];
        if (!previousButton) {
            //First Button
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[padding][button]"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(padding,button)]];
            [constraints addObject:[NSLayoutConstraint constraintWithItem:button
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.buttonView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0.0]];
        }
        else {
            //Middle Buttons
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousButton][padding(==previousPadding)][button]"
                                                                                     options:NSLayoutFormatAlignAllCenterY
                                                                                     metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(previousButton,padding,button,previousPadding)]];
            
        }
        previousPadding = padding;
        previousButton = button;
    }];
    
    UIView * lastPadding = [self.spaces lastObject];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousButton][lastPadding(==previousPadding)]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(previousButton,lastPadding,previousPadding)]];
    
    
    return constraints;
}

- (void)updateConstraints
{
    if (!self.addedContraints) {
        [self addConstraints:[self constraintsWithButtons:self.buttons]];
        
        [self.buttonView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        [self.titleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(kOTRButtonViewTopMargin, 0, 0, 0) excludingEdge:ALEdgeBottom];
        [self.buttonView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
        [self.backgroundToolbar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        
        self.addedContraints = YES;
    }
    [super updateConstraints];
   
}

#pragma - mark Class Methods

+ (UILabel *)defaultTitleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:13.0];
    label.textColor = [UIColor colorWithWhite:0.54 alpha:1.0];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

+ (CGFloat )heightForTitle:(NSString *)title width:(CGFloat)width buttons:(NSArray *)buttons;
{
    UILabel *titleLabel = [self defaultTitleLabel];
    titleLabel.text = title;
    CGRect labelRect = titleLabel.frame;
    labelRect.size.width = width;
    titleLabel.frame = labelRect;
    [titleLabel sizeToFit];
    
    __block CGFloat buttonHeight = 0;
    [buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button sizeToFit];
        if (button.frame.size.height > buttonHeight) {
            buttonHeight = button.frame.size.height;
        }
    }];
    
    return titleLabel.frame.size.height + kOTRButtonViewTopMargin + buttonHeight;
}


@end
