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
NSString *const OTRFacebookActivityImageKey = @"OTRFacebookActivityImageKey";
NSString *const OTRTwitterImageKey = @"OTRTwitterImageKey";

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
    
    return bubbleImageView;
}

+ (UIImage *)twitterImage
{
    return [UIImage imageWithIdentifier:OTRTwitterImageKey forSize:CGSizeMake(100, 100) andDrawingBlock:^{
        UIColor* color = [UIColor colorWithRed: 0.147 green: 0.595 blue: 0.848 alpha: 1];
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(99.71, 19.55)];
        [bezierPath addCurveToPoint: CGPointMake(88.03, 22.75) controlPoint1: CGPointMake(96.07, 21.17) controlPoint2: CGPointMake(92.15, 22.26)];
        [bezierPath addCurveToPoint: CGPointMake(96.98, 11.49) controlPoint1: CGPointMake(92.23, 20.23) controlPoint2: CGPointMake(95.46, 16.24)];
        [bezierPath addCurveToPoint: CGPointMake(84.06, 16.43) controlPoint1: CGPointMake(93.05, 13.82) controlPoint2: CGPointMake(88.69, 15.52)];
        [bezierPath addCurveToPoint: CGPointMake(69.21, 10) controlPoint1: CGPointMake(80.35, 12.47) controlPoint2: CGPointMake(75.06, 10)];
        [bezierPath addCurveToPoint: CGPointMake(48.87, 30.36) controlPoint1: CGPointMake(57.98, 10) controlPoint2: CGPointMake(48.87, 19.11)];
        [bezierPath addCurveToPoint: CGPointMake(49.4, 35) controlPoint1: CGPointMake(48.87, 31.95) controlPoint2: CGPointMake(49.05, 33.51)];
        [bezierPath addCurveToPoint: CGPointMake(7.48, 13.73) controlPoint1: CGPointMake(32.5, 34.15) controlPoint2: CGPointMake(17.51, 26.04)];
        [bezierPath addCurveToPoint: CGPointMake(4.73, 23.96) controlPoint1: CGPointMake(5.73, 16.73) controlPoint2: CGPointMake(4.73, 20.23)];
        [bezierPath addCurveToPoint: CGPointMake(13.77, 40.91) controlPoint1: CGPointMake(4.73, 31.02) controlPoint2: CGPointMake(8.32, 37.25)];
        [bezierPath addCurveToPoint: CGPointMake(4.56, 38.36) controlPoint1: CGPointMake(10.44, 40.8) controlPoint2: CGPointMake(7.3, 39.88)];
        [bezierPath addCurveToPoint: CGPointMake(4.56, 38.61) controlPoint1: CGPointMake(4.56, 38.44) controlPoint2: CGPointMake(4.56, 38.53)];
        [bezierPath addCurveToPoint: CGPointMake(20.87, 58.58) controlPoint1: CGPointMake(4.56, 48.48) controlPoint2: CGPointMake(11.57, 56.71)];
        [bezierPath addCurveToPoint: CGPointMake(15.52, 59.29) controlPoint1: CGPointMake(19.17, 59.04) controlPoint2: CGPointMake(17.37, 59.29)];
        [bezierPath addCurveToPoint: CGPointMake(11.69, 58.93) controlPoint1: CGPointMake(14.21, 59.29) controlPoint2: CGPointMake(12.93, 59.16)];
        [bezierPath addCurveToPoint: CGPointMake(30.69, 73.06) controlPoint1: CGPointMake(14.28, 67.01) controlPoint2: CGPointMake(21.79, 72.9)];
        [bezierPath addCurveToPoint: CGPointMake(5.43, 81.78) controlPoint1: CGPointMake(23.73, 78.52) controlPoint2: CGPointMake(14.96, 81.78)];
        [bezierPath addCurveToPoint: CGPointMake(0.58, 81.49) controlPoint1: CGPointMake(3.79, 81.78) controlPoint2: CGPointMake(2.17, 81.68)];
        [bezierPath addCurveToPoint: CGPointMake(31.76, 90.64) controlPoint1: CGPointMake(9.58, 87.27) controlPoint2: CGPointMake(20.27, 90.64)];
        [bezierPath addCurveToPoint: CGPointMake(89.62, 32.72) controlPoint1: CGPointMake(69.17, 90.64) controlPoint2: CGPointMake(89.62, 59.62)];
        [bezierPath addCurveToPoint: CGPointMake(89.57, 30.08) controlPoint1: CGPointMake(89.62, 31.83) controlPoint2: CGPointMake(89.6, 30.96)];
        [bezierPath addCurveToPoint: CGPointMake(99.71, 19.55) controlPoint1: CGPointMake(93.54, 27.21) controlPoint2: CGPointMake(96.99, 23.63)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [color setFill];
        [bezierPath fill];

    }];
}

+ (UIImage *)facebookActivityImage
{
    return [UIImage imageWithIdentifier:OTRFacebookActivityImageKey forSize:CGSizeMake(267, 267) andDrawingBlock:^{
        UIColor* color = [UIColor colorWithRed: 0.181 green: 0.272 blue: 0.529 alpha: 1];
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(182.41, 262.31)];
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
        [bezier2Path addLineToPoint: CGPointMake(142.24, 262.31)];
        [bezier2Path addLineToPoint: CGPointMake(182.41, 262.31)];
        [bezier2Path closePath];
        bezier2Path.miterLimit = 4;
        
        [color setFill];
        [bezier2Path fill];

    }];
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
