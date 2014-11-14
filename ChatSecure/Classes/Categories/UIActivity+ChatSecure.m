//
//  UIActivity+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 10/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIActivity+ChatSecure.h"

@implementation UIActivity (ChatSecure)

+ (CGSize)otr_defaultImageSize
{
    CGSize size = CGSizeZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        size = CGSizeMake(43, 43);
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        size = CGSizeMake(55, 55);
    }
    return size;
}

@end
