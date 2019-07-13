//
//  OTRTitleSubtitleView.h
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface OTRTitleSubtitleView : UIView


@property (nonatomic, strong, readonly) UILabel * titleLabel;
@property (nonatomic, strong, readonly) UILabel * subtitleLabel;

@property (nonatomic, strong, readonly) UIImageView *titleImageView;
@property (nonatomic, strong, readonly) UIImageView *subtitleImageView;

@end
