//
//  OTRImages+UIKit.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import OTRAssets;
#import "OTRImages+UIKit.h"
#import "OTRComposingImageView.h"
@import ChatSecureCore;

@implementation OTRImages (UIKit)

+ (UIImage *)image:(UIImage *)image maskWithColor:(UIColor *)maskColor
{
    CGRect imageRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    CGContextTranslateCTM(ctx, 0.0f, -(imageRect.size.height));
    
    CGContextClipToMask(ctx, imageRect, image.CGImage);
    CGContextSetFillColorWithColor(ctx, maskColor.CGColor);
    CGContextFillRect(ctx, imageRect);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)mirrorImage:(UIImage *)image {
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}


+ (UIView *)typingBubbleView
{
    UIImageView * bubbleImageView = nil;
    UIImage * bubbleImage = nil;
    bubbleImage = [UIImage imageNamed:@"bubble-min-tailless" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    
    bubbleImage = [self image:bubbleImage maskWithColor:[OTRColors bubbleLightGrayColor]];
    bubbleImage = [self mirrorImage:bubbleImage];
    
    CGPoint center = CGPointMake((bubbleImage.size.width / 2.0f), bubbleImage.size.height / 2.0f);
    UIEdgeInsets capInsets = UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
    
    bubbleImage = [bubbleImage resizableImageWithCapInsets:capInsets
                                              resizingMode:UIImageResizingModeStretch];
    
    bubbleImageView = [[OTRComposingImageView alloc] initWithImage:bubbleImage];
    CGRect rect = bubbleImageView.frame;
    rect.size.width = 60;
    bubbleImageView.frame = rect;
    
    return bubbleImageView;
}

@end
