//
//  OTRCircleButtonView.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface OTRCircleButtonView : UIView

@property (nonatomic, strong) UIButton *imageButton;

@property (nonatomic, strong) UIButton *labelButton;
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic) CGSize circleSize;
@property (nonatomic) CGSize imageSize;

/** executed when either button is pressed */
@property (nonatomic, copy) dispatch_block_t actionBlock;

- (instancetype) initWithFrame:(CGRect)frame
                         title:(NSString*)title
                         image:(UIImage*)image
                     imageSize:(CGSize)imageSize
                   circleSize:(CGSize)circleSize
                   actionBlock:(dispatch_block_t)actionBlock;

@end
