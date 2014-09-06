//
//  OTRSocialButtonsView.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRSocialButtonsView.h"
#import "PureLayout.h"
#import "BButton.h"
#import "NSURL+chatsecure.h"

static CGFloat kOTRSocialButtonHeight = 30.0f;
static CGFloat kOTRSocialButtonWidth = 93.0f;
static CGFloat kOTRSocialTotalWidth = 300.0f;

@interface OTRSocialButtonsView ()
@property (nonatomic) BOOL hasSetupConstraints;
@end

@implementation OTRSocialButtonsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        UIFont *buttonFont = [UIFont systemFontOfSize:15];
        self.facebookButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeFacebook style:BButtonStyleBootstrapV3];
        self.facebookButton.titleLabel.text = @"Facebook";
        self.facebookButton.titleLabel.font = buttonFont;
        [self.facebookButton addAwesomeIcon:FAFacebook beforeTitle:YES];
        [self.facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.githubButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDefault style:BButtonStyleBootstrapV3];
        self.githubButton.titleLabel.text = @"GitHub";
        self.githubButton.titleLabel.font = buttonFont;
        [self.githubButton addAwesomeIcon:FAGithub beforeTitle:YES];
        [self.githubButton addTarget:self action:@selector(githubButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.twitterButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeTwitter style:BButtonStyleBootstrapV3];
        self.twitterButton.titleLabel.text = @"Twitter";
        self.twitterButton.titleLabel.font = buttonFont;
        [self.twitterButton addAwesomeIcon:FATwitter beforeTitle:YES];
        [self.twitterButton addTarget:self action:@selector(twitterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.facebookButton];
        [self addSubview:self.twitterButton];
        [self addSubview:self.githubButton];
    }
    return self;
}

- (void) updateConstraints {
    [super updateConstraints];
    if (self.hasSetupConstraints) {
        return;
    }
    
    [self.facebookButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.facebookButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.twitterButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.twitterButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.facebookButton];
    [self.githubButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.facebookButton];
    [self.githubButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.facebookButton autoSetDimension:ALDimensionWidth toSize:kOTRSocialButtonWidth];
    [self.facebookButton autoSetDimension:ALDimensionHeight toSize:kOTRSocialButtonHeight];
    [self.facebookButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.githubButton];
    [self.githubButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.twitterButton];
    [self.twitterButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.facebookButton];
    [self.facebookButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.githubButton];
    [self.githubButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.twitterButton];
    [self.twitterButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.facebookButton];
    
    
    self.hasSetupConstraints = YES;
}

- (CGSize) intrinsicContentSize {
    return CGSizeMake(kOTRSocialTotalWidth, kOTRSocialButtonHeight);
}

- (void) twitterButtonPressed:(id)sender {
    NSURL *twitterURL = [NSURL otr_twitterAppURL];
    if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
        [[UIApplication sharedApplication] openURL:twitterURL];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL otr_twitterWebURL]];
    }
}

- (void) facebookButtonPressed:(id)sender {
    NSURL *facebookURL = [NSURL otr_facebookAppURL];
    if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
        [[UIApplication sharedApplication] openURL:facebookURL];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL otr_facebookWebURL]];
    }
}

- (void) githubButtonPressed:(id)sender {
    NSURL *githubURL = [NSURL otr_githubURL];
    [[UIApplication sharedApplication] openURL:githubURL];
}

@end
