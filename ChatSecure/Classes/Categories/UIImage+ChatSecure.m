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

+ (UIImage *)otr_squareCropImage:(UIImage *)image
{
    
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    if (width == height) {
        return image;
    }
    
    //This is the new width and height
    CGFloat size = MIN(width, height);
    
    //Find x and y for the rect to crop
    CGFloat x = roundf((width - size) / 2.0);
    CGFloat y = roundf((height - size) / 2.0);
    //Create rect to crop with
    CGRect cropRect = CGRectMake(x, y, size, size);
    
    //Do the actual crop
    CGImageRef newImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    //Create new image from cropped CGImageRef
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(newImageRef);
    
    return newImage;
}

+ (UIImage *)otr_prepareForAvatarUpload:(UIImage *)image maxSize:(CGFloat)size
{
    UIImage *croppedImage = [self otr_squareCropImage:image];
    //Check if the width (which is equal to the height now) is greater than the expected size
    if (croppedImage.size.height > size) {
        return [self otr_imageWithImage:croppedImage scaledToSize:CGSizeMake(size, size)];
    }
    return croppedImage;
}

@end
