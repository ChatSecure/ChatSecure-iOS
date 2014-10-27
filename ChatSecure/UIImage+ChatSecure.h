//
//  UIImage+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 10/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ChatSecure)

+ (UIImage *)otr_imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
