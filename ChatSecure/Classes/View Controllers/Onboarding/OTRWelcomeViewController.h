//
//  OTRWelcomeViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRCircleView;



@interface OTRWelcomeViewController : UIViewController

@property (nonatomic, strong, readonly) UIImageView *brandImageView;
@property (nonatomic, strong, readonly) UILabel *createLabel;
@property (nonatomic, strong, readonly) UILabel *anonymousLabel;
@property (nonatomic, strong, readonly) UIButton *createButton;
@property (nonatomic, strong, readonly) UIButton *anonymousButton;
@property (nonatomic, strong, readonly) OTRCircleView *createView;
@property (nonatomic, strong, readonly) OTRCircleView *anonymousView;

@property (nonatomic) BOOL showNavigationBar;


@property (nonatomic, copy) void (^successBlock)(void);

@end
