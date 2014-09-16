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
#import "UIActionSheet+Blocks.h"
#import "OTRAppDelegate.h"
#import "Strings.h"
#import "OTRSafariActionSheet.h"

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
        self.facebookButton.titleLabel.text = FACEBOOK_STRING;
        self.facebookButton.titleLabel.font = buttonFont;
        [self.facebookButton addAwesomeIcon:FAFacebook beforeTitle:YES];
        [self.facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.githubButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDefault style:BButtonStyleBootstrapV3];
        self.githubButton.titleLabel.text = GITHUB_STRING;
        self.githubButton.titleLabel.font = buttonFont;
        [self.githubButton addAwesomeIcon:FAGithub beforeTitle:YES];
        [self.githubButton addTarget:self action:@selector(githubButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.twitterButton = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeTwitter style:BButtonStyleBootstrapV3];
        self.twitterButton.titleLabel.text = TWITTER_STRING;
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
    UIActionSheet *actionSheet = nil;
    NSURL *twitterAppURL = [NSURL otr_twitterAppURL];
    if ([[UIApplication sharedApplication] canOpenURL:twitterAppURL]) {
        RIButtonItem *facebookAppButtonItem = [RIButtonItem itemWithLabel:OPEN_IN_TWITTER_STRING action:^{
            [[UIApplication sharedApplication] openURL:twitterAppURL];
        }];
        actionSheet = [[UIActionSheet alloc]  initWithTitle:TWITTER_STRING cancelButtonItem:[RIButtonItem itemWithLabel:CANCEL_STRING] destructiveButtonItem:nil otherButtonItems:facebookAppButtonItem,nil];
    } else {
        actionSheet = [[OTRSafariActionSheet alloc] initWithUrl:[NSURL otr_twitterWebURL]];
    }
    [OTRAppDelegate presentActionSheet:actionSheet inView:self];
}

- (void) facebookButtonPressed:(id)sender {
    
    NSURL *facebookAppURL = [NSURL otr_facebookAppURL];
    
    UIActionSheet *actionSheet = nil;
    
    if ([[UIApplication sharedApplication] canOpenURL:facebookAppURL]) {
        RIButtonItem *facebookAppButtonItem = [RIButtonItem itemWithLabel:OPEN_IN_FACEBOOK_STRING action:^{
            [[UIApplication sharedApplication] openURL:facebookAppURL];
        }];
        actionSheet = [[UIActionSheet alloc]  initWithTitle:FACEBOOK_STRING cancelButtonItem:[RIButtonItem itemWithLabel:CANCEL_STRING] destructiveButtonItem:nil otherButtonItems:facebookAppButtonItem,nil];
    } else {
        actionSheet = [[OTRSafariActionSheet alloc] initWithUrl:[NSURL otr_facebookWebURL]];
    }
    
    [OTRAppDelegate presentActionSheet:actionSheet inView:self];
}

- (void) githubButtonPressed:(id)sender {
    UIActionSheet *actionSheet = [[OTRSafariActionSheet alloc] initWithUrl:[NSURL otr_githubURL]];
    [OTRAppDelegate presentActionSheet:actionSheet inView:self];
}

@end
