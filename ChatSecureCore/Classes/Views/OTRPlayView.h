//
//  OTRPlayView.h
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface OTRPlayView : UIView

//default black
@property (nonatomic, strong) UIColor *color;

//default pi/3 or 60 degrees for equalateral triangle
@property (nonatomic) CGFloat angle; // > 0 && < pi

@end
