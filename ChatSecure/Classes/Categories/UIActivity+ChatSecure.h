//
//  UIActivity+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 10/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface UIActivity (ChatSecure)

+ (CGSize)otr_defaultImageSize;

/** Activities relevant for links */
@property (nonatomic, class, readonly) NSArray<UIActivity*> *otr_linkActivities;


@end
