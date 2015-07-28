//
//  OTRWelcomeViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRCircleView;
@class OTRCircleButtonView;


@interface OTRWelcomeViewController : UIViewController

@property (nonatomic, strong, readonly) UIImageView *brandImageView;
@property (nonatomic, strong, readonly) OTRCircleButtonView *anonymousButton;
@property (nonatomic, strong, readonly) OTRCircleButtonView *createButton;

@property (nonatomic) BOOL showNavigationBar;

@property (nonatomic, copy) void (^successBlock)(void);

@end
