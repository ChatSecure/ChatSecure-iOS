//
//  UIImage+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 10/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIImage+ChatSecure.h"

@implementation UIImage (ChatSecure)

+ (UIImage *)otr_imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
