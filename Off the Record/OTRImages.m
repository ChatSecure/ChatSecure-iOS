//
//  OTRstatusImage.m
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRImages.h"
#import "OTRUtilities.h"
#import "OTRColors.h"
#import "UIImage+BBlock.h"

#import "OTRComposingImageView.h"

NSString *const OTRWarningImageKey = @"OTRWarningImageKey";
NSString *const OTRFacebookImageKey = @"OTRFacebookImageKey";

@implementation OTRImages

+ (UIImage *)mirrorImage:(UIImage *)image {
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}

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

+ (UIImage *)circleWithRadius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius*2, radius*2), NO, 0);
    //// Color Declarations
    UIColor* fillColor = [UIColor blackColor];
    
    //// Polygon Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0, 0, radius*2, radius*2)];
    [fillColor setFill];
    [ovalPath fill];
    
    UIImage *circle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return circle;
}

+ (UIView *)typingBubbleView
{
    UIImageView * bubbleImageView = nil;
    UIImage * bubbleImage = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        bubbleImage = [UIImage imageNamed:@"bubble-min-tailless"];
        
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
    }
    else {
        bubbleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MessageBubbleTyping"]];
    }
    return bubbleImageView;
}

+ (UIImage *)facebookImage
{
    return [UIImage imageWithIdentifier:OTRFacebookImageKey forSize:CGSizeMake(267, 267) andDrawingBlock:^{
        //// Color Declarations
        UIColor* color1 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
        UIColor* color0 = [UIColor colorWithRed: 0.181 green: 0.272 blue: 0.529 alpha: 1];
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(248.08, 262.31)];
        [bezierPath addCurveToPoint: CGPointMake(262.31, 248.08) controlPoint1: CGPointMake(255.94, 262.31) controlPoint2: CGPointMake(262.31, 255.94)];
        [bezierPath addLineToPoint: CGPointMake(262.31, 18.81)];
        [bezierPath addCurveToPoint: CGPointMake(248.08, 4.59) controlPoint1: CGPointMake(262.31, 10.95) controlPoint2: CGPointMake(255.94, 4.59)];
        [bezierPath addLineToPoint: CGPointMake(18.81, 4.59)];
        [bezierPath addCurveToPoint: CGPointMake(4.59, 18.81) controlPoint1: CGPointMake(10.96, 4.59) controlPoint2: CGPointMake(4.59, 10.95)];
        [bezierPath addLineToPoint: CGPointMake(4.59, 248.08)];
        [bezierPath addCurveToPoint: CGPointMake(18.81, 262.31) controlPoint1: CGPointMake(4.59, 255.94) controlPoint2: CGPointMake(10.95, 262.31)];
        [bezierPath addLineToPoint: CGPointMake(248.08, 262.31)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [color0 setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(182.41, 264)];
        [bezier2Path addLineToPoint: CGPointMake(182.41, 162.5)];
        [bezier2Path addLineToPoint: CGPointMake(215.91, 162.5)];
        [bezier2Path addLineToPoint: CGPointMake(220.92, 123.61)];
        [bezier2Path addLineToPoint: CGPointMake(182.41, 123.61)];
        [bezier2Path addLineToPoint: CGPointMake(182.41, 98.78)];
        [bezier2Path addCurveToPoint: CGPointMake(201.68, 79.84) controlPoint1: CGPointMake(182.41, 87.52) controlPoint2: CGPointMake(185.54, 79.84)];
        [bezier2Path addLineToPoint: CGPointMake(222.28, 79.83)];
        [bezier2Path addLineToPoint: CGPointMake(222.28, 45.05)];
        [bezier2Path addCurveToPoint: CGPointMake(192.27, 43.51) controlPoint1: CGPointMake(218.72, 44.57) controlPoint2: CGPointMake(206.49, 43.51)];
        [bezier2Path addCurveToPoint: CGPointMake(142.24, 94.93) controlPoint1: CGPointMake(162.57, 43.51) controlPoint2: CGPointMake(142.24, 61.64)];
        [bezier2Path addLineToPoint: CGPointMake(142.24, 123.61)];
        [bezier2Path addLineToPoint: CGPointMake(108.66, 123.61)];
        [bezier2Path addLineToPoint: CGPointMake(108.66, 162.5)];
        [bezier2Path addLineToPoint: CGPointMake(142.24, 162.5)];
        [bezier2Path addLineToPoint: CGPointMake(142.24, 264)];
        [bezier2Path addLineToPoint: CGPointMake(182.41, 264)];
        [bezier2Path closePath];
        bezier2Path.miterLimit = 4;
        
        [color1 setFill];
        [bezier2Path fill];
    }];
}

+ (UIImage *)warningImage
{
    return [UIImage imageWithIdentifier:OTRWarningImageKey forSize:CGSizeMake(92.0, 92.0) andDrawingBlock:^{
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(76.52, 86.78)];
        [bezierPath addLineToPoint: CGPointMake(15.48, 86.78)];
        [bezierPath addCurveToPoint: CGPointMake(2.43, 80.68) controlPoint1: CGPointMake(9.34, 86.78) controlPoint2: CGPointMake(4.71, 84.61)];
        [bezierPath addCurveToPoint: CGPointMake(3.67, 66.32) controlPoint1: CGPointMake(0.16, 76.74) controlPoint2: CGPointMake(0.6, 71.64)];
        [bezierPath addLineToPoint: CGPointMake(34.19, 13.47)];
        [bezierPath addCurveToPoint: CGPointMake(46, 5.22) controlPoint1: CGPointMake(37.26, 8.15) controlPoint2: CGPointMake(41.45, 5.22)];
        [bezierPath addCurveToPoint: CGPointMake(57.81, 13.47) controlPoint1: CGPointMake(50.54, 5.22) controlPoint2: CGPointMake(54.74, 8.15)];
        [bezierPath addLineToPoint: CGPointMake(88.33, 66.32)];
        [bezierPath addCurveToPoint: CGPointMake(89.56, 80.68) controlPoint1: CGPointMake(91.4, 71.64) controlPoint2: CGPointMake(91.84, 76.74)];
        [bezierPath addCurveToPoint: CGPointMake(76.52, 86.78) controlPoint1: CGPointMake(87.29, 84.61) controlPoint2: CGPointMake(82.66, 86.78)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(52.23, 68.18)];
        [bezierPath addCurveToPoint: CGPointMake(46.48, 62.44) controlPoint1: CGPointMake(52.23, 65.01) controlPoint2: CGPointMake(49.65, 62.44)];
        [bezierPath addCurveToPoint: CGPointMake(40.74, 68.18) controlPoint1: CGPointMake(43.31, 62.44) controlPoint2: CGPointMake(40.74, 65.01)];
        [bezierPath addCurveToPoint: CGPointMake(46.48, 73.92) controlPoint1: CGPointMake(40.74, 71.35) controlPoint2: CGPointMake(43.31, 73.92)];
        [bezierPath addCurveToPoint: CGPointMake(52.23, 68.18) controlPoint1: CGPointMake(49.65, 73.92) controlPoint2: CGPointMake(52.23, 71.35)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(52.38, 33.61)];
        [bezierPath addCurveToPoint: CGPointMake(46.48, 27.72) controlPoint1: CGPointMake(52.38, 30.36) controlPoint2: CGPointMake(49.74, 27.72)];
        [bezierPath addCurveToPoint: CGPointMake(40.59, 33.61) controlPoint1: CGPointMake(43.23, 27.72) controlPoint2: CGPointMake(40.59, 30.36)];
        [bezierPath addLineToPoint: CGPointMake(41.98, 54.55)];
        [bezierPath addLineToPoint: CGPointMake(42, 54.55)];
        [bezierPath addCurveToPoint: CGPointMake(46.48, 58.68) controlPoint1: CGPointMake(42.2, 56.86) controlPoint2: CGPointMake(44.12, 58.68)];
        [bezierPath addCurveToPoint: CGPointMake(50.92, 55.06) controlPoint1: CGPointMake(48.67, 58.68) controlPoint2: CGPointMake(50.5, 57.13)];
        [bezierPath addCurveToPoint: CGPointMake(50.97, 54.55) controlPoint1: CGPointMake(50.95, 54.9) controlPoint2: CGPointMake(50.95, 54.72)];
        [bezierPath addLineToPoint: CGPointMake(51.01, 54.55)];
        [bezierPath addLineToPoint: CGPointMake(52.38, 33.61)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [[OTRColors warnColor] setFill];
        [bezierPath fill];

    }];
}


@end
