//
//  OTRSocialButtonsView.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRSocialButtonsView.h"
@import PureLayout;
@import BButton;
#import "NSURL+ChatSecure.h"
#import "OTRAppDelegate.h"
@import OTRAssets;


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
        self.facebookButton.titleLabel.text = FACEBOOK_STRING();
        self.facebookButton.titleLabel.font = buttonFont;
        [self.facebookButton addAwesomeIcon:FAFacebook beforeTitle:YES];
        [self.facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.githubButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDefault style:BButtonStyleBootstrapV3];
        self.githubButton.titleLabel.text = GITHUB_STRING();
        self.githubButton.titleLabel.font = buttonFont;
        [self.githubButton addAwesomeIcon:FAGithub beforeTitle:YES];
        [self.githubButton addTarget:self action:@selector(githubButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.twitterButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeTwitter style:BButtonStyleBootstrapV3];
        self.twitterButton.titleLabel.text = TWITTER_STRING();
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
    
    NSURL *twitterAppURL = [NSURL otr_twitterAppURL];
    NSURL *twitterWebURL = [NSURL otr_twitterWebURL];
    
    [self openActivityUrls:@[twitterAppURL,twitterWebURL] withButton:sender];
}

- (void) facebookButtonPressed:(id)sender {
    
    NSURL *facebookAppURL = [NSURL otr_facebookAppURL];
    NSURL *facebookWebURL = [NSURL otr_facebookWebURL];
    
    [self openActivityUrls:@[facebookAppURL,facebookWebURL] withButton:sender];
}

- (void) githubButtonPressed:(id)sender {
    [self openActivityUrls:@[[NSURL otr_githubURL]] withButton:sender];
}

- (void)openActivityUrls:(NSArray *)activityURLs withButton:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(socialButton:openURLs:)]) {
        [self.delegate socialButton:button openURLs:activityURLs];
    }
}

@end
