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
    CGAffineTransform rectTransform = [self otr_imageTransform:image];
    cropRect = CGRectApplyAffineTransform(cropRect, rectTransform);
    //Issues with floats being ever so slightly off and then CGRectIntegral changing our size to non-square
    cropRect = CGRectMake(roundf(cropRect.origin.x), roundf(cropRect.origin.y), roundf(cropRect.size.width), roundf(cropRect.size.height));
    
    //Do the actual crop
    CGImageRef newImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    //Create new image from cropped CGImageRef
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(newImageRef);
    
    return newImage;
}

//https://github.com/gekitz/GKImagePicker/blob/e788d9f3fba5595c98dfa0bbbc1dd4e897c1ccf8/GKClasses/GKImageCropView.m#L149
+ (CGAffineTransform)otr_imageTransform:(UIImage *)image {
    CGAffineTransform rectTransform;
    switch (image.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -image.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -image.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI), -image.size.width, -image.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    return CGAffineTransformScale(rectTransform, image.scale, image.scale);
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
