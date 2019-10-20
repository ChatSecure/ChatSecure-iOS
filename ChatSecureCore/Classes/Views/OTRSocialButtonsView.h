//
//  OTRSocialButtonsView.h
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@class BButton;

@protocol OTRSocialButtonsViewDelegate <NSObject>

- (void)socialButton:(UIButton *)button openURLs:(NSArray *)urlArray;

@end

@interface OTRSocialButtonsView : UIView

@property (nonatomic, weak) id <OTRSocialButtonsViewDelegate> delegate;

@property (nonatomic, strong) BButton *twitterButton;
@property (nonatomic, strong) BButton *facebookButton;
@property (nonatomic, strong) BButton *githubButton;

@end
