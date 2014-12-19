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
#import "JSQMessagesAvatarImageFactory.h"
#import "OTRComposingImageView.h"
#import "NSString+ChatSecure.h"

NSString *const OTRWarningImageKey = @"OTRWarningImageKey";
NSString *const OTRWarningCircleImageKey = @"OTRWarningCircleImageKey";
NSString *const OTRFacebookImageKey = @"OTRFacebookImageKey";
NSString *const OTRFacebookActivityImageKey = @"OTRFacebookActivityImageKey";
NSString *const OTRTwitterImageKey = @"OTRTwitterImageKey";
NSString *const OTRCheckmarkImageKey = @"OTRCeckmarkImageKey";
NSString *const OTRErrorImageKey = @"OTRErrorImageKey";
NSString *const OTRWifiImageKey = @"OTRWifiImageKey";

@implementation OTRImages

+ (NSCache *)imageCache{
    static NSCache *imageCache = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        imageCache = [[NSCache alloc] init];
    });
    return imageCache;
}

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
    return [self circleWithRadius:radius lineWidth:0 lineColor:nil fillColor:nil];
}

+ (UIImage *)circleWithRadius:(CGFloat)radius lineWidth:(CGFloat)lineWidth lineColor:(UIColor *)lineColor fillColor:(UIColor *)fillColor
{
    if (!fillColor) {
        fillColor = [UIColor blackColor];
    }
    
    if (!lineColor) {
        lineColor = [UIColor blackColor];
    }
    
    return [UIImage imageForSize:CGSizeMake(radius*2+lineWidth, radius*2+lineWidth) opaque:NO withDrawingBlock:^{
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(lineWidth/2.0, lineWidth/2.0, radius*2.0, radius*2.0)];
        [fillColor setFill];
        [ovalPath fill];
        [lineColor setStroke];
        ovalPath.lineWidth = lineWidth;
        [ovalPath stroke];
        
    }];
    
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

+(UIImage *)warningImage
{
    return [self warningImageWithColor:[OTRColors warnColor]];
}

+ (UIImage *)warningImageWithColor:(UIColor *)color;
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@",OTRWarningImageKey,[color description]];
    
    return [UIImage imageWithIdentifier:identifier forSize:CGSizeMake(92.0, 92.0) andDrawingBlock:^{
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
        
        [color setFill];
        [bezierPath fill];

    }];
}

+ (UIImage *)circleWarningWithColor:(UIColor *)color
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@",OTRWarningCircleImageKey,color.description];
    
    return [UIImage imageWithIdentifier:identifier forSize:CGSizeMake(60, 60) andDrawingBlock:^{
        //// Color Declarations
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(30, 1)];
        [bezierPath addCurveToPoint: CGPointMake(1, 30) controlPoint1: CGPointMake(13.98, 1) controlPoint2: CGPointMake(1, 13.98)];
        [bezierPath addCurveToPoint: CGPointMake(30, 59) controlPoint1: CGPointMake(1, 46.02) controlPoint2: CGPointMake(13.98, 59)];
        [bezierPath addCurveToPoint: CGPointMake(59, 30) controlPoint1: CGPointMake(46.02, 59) controlPoint2: CGPointMake(59, 46.02)];
        [bezierPath addCurveToPoint: CGPointMake(30, 1) controlPoint1: CGPointMake(59, 13.98) controlPoint2: CGPointMake(46.02, 1)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(29.36, 6.59)];
        [bezierPath addCurveToPoint: CGPointMake(30, 6.59) controlPoint1: CGPointMake(29.57, 6.57) controlPoint2: CGPointMake(29.78, 6.59)];
        [bezierPath addCurveToPoint: CGPointMake(36.32, 12.56) controlPoint1: CGPointMake(33.49, 6.59) controlPoint2: CGPointMake(36.32, 9.26)];
        [bezierPath addLineToPoint: CGPointMake(34.82, 33.8)];
        [bezierPath addLineToPoint: CGPointMake(34.79, 33.8)];
        [bezierPath addCurveToPoint: CGPointMake(34.73, 34.31) controlPoint1: CGPointMake(34.77, 33.98) controlPoint2: CGPointMake(34.76, 34.14)];
        [bezierPath addCurveToPoint: CGPointMake(30, 37.98) controlPoint1: CGPointMake(34.28, 36.4) controlPoint2: CGPointMake(32.34, 37.98)];
        [bezierPath addCurveToPoint: CGPointMake(25.21, 33.8) controlPoint1: CGPointMake(27.47, 37.98) controlPoint2: CGPointMake(25.43, 36.15)];
        [bezierPath addLineToPoint: CGPointMake(25.18, 33.8)];
        [bezierPath addLineToPoint: CGPointMake(23.68, 12.56)];
        [bezierPath addCurveToPoint: CGPointMake(29.36, 6.59) controlPoint1: CGPointMake(23.68, 9.46) controlPoint2: CGPointMake(26.18, 6.9)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(30, 41.79)];
        [bezierPath addCurveToPoint: CGPointMake(36.13, 47.6) controlPoint1: CGPointMake(33.4, 41.79) controlPoint2: CGPointMake(36.13, 44.38)];
        [bezierPath addCurveToPoint: CGPointMake(30, 53.41) controlPoint1: CGPointMake(36.13, 50.82) controlPoint2: CGPointMake(33.4, 53.41)];
        [bezierPath addCurveToPoint: CGPointMake(23.87, 47.6) controlPoint1: CGPointMake(26.6, 53.41) controlPoint2: CGPointMake(23.87, 50.82)];
        [bezierPath addCurveToPoint: CGPointMake(30, 41.79) controlPoint1: CGPointMake(23.87, 44.38) controlPoint2: CGPointMake(26.6, 41.79)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        bezierPath.usesEvenOddFillRule = YES;
        
        [color setFill];
        [bezierPath fill];
    }];
}

+ (UIImage *)checkmarkWithColor:(UIColor *)color
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@",OTRCheckmarkImageKey,[color description]];
    
    return [UIImage imageWithIdentifier:identifier forSize:CGSizeMake(100, 100) andDrawingBlock:^{
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(50, 0)];
        [bezierPath addCurveToPoint: CGPointMake(0, 50) controlPoint1: CGPointMake(22.33, 0) controlPoint2: CGPointMake(0, 22.33)];
        [bezierPath addCurveToPoint: CGPointMake(50, 100) controlPoint1: CGPointMake(0, 77.67) controlPoint2: CGPointMake(22.33, 100)];
        [bezierPath addCurveToPoint: CGPointMake(100, 50) controlPoint1: CGPointMake(77.67, 100) controlPoint2: CGPointMake(100, 77.67)];
        [bezierPath addCurveToPoint: CGPointMake(50, 0) controlPoint1: CGPointMake(100, 22.33) controlPoint2: CGPointMake(77.67, 0)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(79.89, 33.33)];
        [bezierPath addLineToPoint: CGPointMake(47.78, 73.44)];
        [bezierPath addCurveToPoint: CGPointMake(43.89, 75.44) controlPoint1: CGPointMake(46.78, 74.67) controlPoint2: CGPointMake(45.44, 75.33)];
        [bezierPath addCurveToPoint: CGPointMake(43.56, 75.44) controlPoint1: CGPointMake(43.78, 75.44) controlPoint2: CGPointMake(43.67, 75.44)];
        [bezierPath addCurveToPoint: CGPointMake(39.78, 73.89) controlPoint1: CGPointMake(42.11, 75.44) controlPoint2: CGPointMake(40.78, 74.89)];
        [bezierPath addLineToPoint: CGPointMake(20.56, 55)];
        [bezierPath addCurveToPoint: CGPointMake(20.56, 47.33) controlPoint1: CGPointMake(18.44, 52.89) controlPoint2: CGPointMake(18.44, 49.44)];
        [bezierPath addCurveToPoint: CGPointMake(28.22, 47.33) controlPoint1: CGPointMake(22.67, 45.22) controlPoint2: CGPointMake(26.11, 45.22)];
        [bezierPath addLineToPoint: CGPointMake(43.11, 62)];
        [bezierPath addLineToPoint: CGPointMake(71.44, 26.56)];
        [bezierPath addCurveToPoint: CGPointMake(79.11, 25.67) controlPoint1: CGPointMake(73.33, 24.22) controlPoint2: CGPointMake(76.78, 23.78)];
        [bezierPath addCurveToPoint: CGPointMake(79.89, 33.33) controlPoint1: CGPointMake(81.33, 27.56) controlPoint2: CGPointMake(81.78, 31)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [color setFill];
        [bezierPath fill];
    }];
}

+ (UIImage *)errorWithColor:(UIColor *)color
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@",OTRErrorImageKey,[color description]];
    
    return [UIImage imageWithIdentifier:identifier forSize:CGSizeMake(100, 100) andDrawingBlock:^{
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(50, 0)];
        [bezierPath addCurveToPoint: CGPointMake(0, 50) controlPoint1: CGPointMake(22.33, 0) controlPoint2: CGPointMake(0, 22.33)];
        [bezierPath addCurveToPoint: CGPointMake(50, 100) controlPoint1: CGPointMake(0, 77.67) controlPoint2: CGPointMake(22.33, 100)];
        [bezierPath addCurveToPoint: CGPointMake(100, 50) controlPoint1: CGPointMake(77.67, 100) controlPoint2: CGPointMake(100, 77.67)];
        [bezierPath addCurveToPoint: CGPointMake(50, 0) controlPoint1: CGPointMake(100, 22.33) controlPoint2: CGPointMake(77.67, 0)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(75.89, 69)];
        [bezierPath addCurveToPoint: CGPointMake(75.78, 76.67) controlPoint1: CGPointMake(78, 71.11) controlPoint2: CGPointMake(77.89, 74.56)];
        [bezierPath addCurveToPoint: CGPointMake(72, 78.22) controlPoint1: CGPointMake(74.78, 77.67) controlPoint2: CGPointMake(73.33, 78.22)];
        [bezierPath addCurveToPoint: CGPointMake(68.11, 76.56) controlPoint1: CGPointMake(70.56, 78.22) controlPoint2: CGPointMake(69.11, 77.67)];
        [bezierPath addLineToPoint: CGPointMake(50, 57.78)];
        [bezierPath addLineToPoint: CGPointMake(31.89, 76.56)];
        [bezierPath addCurveToPoint: CGPointMake(28, 78.22) controlPoint1: CGPointMake(30.78, 77.67) controlPoint2: CGPointMake(29.44, 78.22)];
        [bezierPath addCurveToPoint: CGPointMake(24.22, 76.67) controlPoint1: CGPointMake(26.67, 78.22) controlPoint2: CGPointMake(25.33, 77.67)];
        [bezierPath addCurveToPoint: CGPointMake(24.11, 69) controlPoint1: CGPointMake(22.11, 74.56) controlPoint2: CGPointMake(22, 71.11)];
        [bezierPath addLineToPoint: CGPointMake(42.44, 50)];
        [bezierPath addLineToPoint: CGPointMake(24.11, 31)];
        [bezierPath addCurveToPoint: CGPointMake(24.22, 23.33) controlPoint1: CGPointMake(22, 28.89) controlPoint2: CGPointMake(22.11, 25.44)];
        [bezierPath addCurveToPoint: CGPointMake(31.89, 23.44) controlPoint1: CGPointMake(26.33, 21.22) controlPoint2: CGPointMake(29.78, 21.33)];
        [bezierPath addLineToPoint: CGPointMake(50, 42.22)];
        [bezierPath addLineToPoint: CGPointMake(68.11, 23.56)];
        [bezierPath addCurveToPoint: CGPointMake(75.78, 23.44) controlPoint1: CGPointMake(70.22, 21.44) controlPoint2: CGPointMake(73.67, 21.33)];
        [bezierPath addCurveToPoint: CGPointMake(75.89, 31.11) controlPoint1: CGPointMake(77.89, 25.56) controlPoint2: CGPointMake(78, 29)];
        [bezierPath addLineToPoint: CGPointMake(57.56, 50)];
        [bezierPath addLineToPoint: CGPointMake(75.89, 69)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [color setFill];
        [bezierPath fill];
    }];
}

+ (UIImage *)wifiWithColor:(UIColor *)color
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@",OTRWifiImageKey,color];
    return [UIImage imageWithIdentifier:identifier forSize:CGSizeMake(100, 100) andDrawingBlock:^{
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(50, 15.69)];
        [bezierPath addCurveToPoint: CGPointMake(0, 35.77) controlPoint1: CGPointMake(30.38, 15.69) controlPoint2: CGPointMake(12.72, 23.39)];
        [bezierPath addLineToPoint: CGPointMake(6.43, 42.4)];
        [bezierPath addCurveToPoint: CGPointMake(50, 25.05) controlPoint1: CGPointMake(17.42, 31.7) controlPoint2: CGPointMake(32.82, 25.05)];
        [bezierPath addCurveToPoint: CGPointMake(93.57, 42.4) controlPoint1: CGPointMake(67.18, 25.05) controlPoint2: CGPointMake(82.58, 31.7)];
        [bezierPath addLineToPoint: CGPointMake(100, 35.77)];
        [bezierPath addCurveToPoint: CGPointMake(50, 15.69) controlPoint1: CGPointMake(87.28, 23.39) controlPoint2: CGPointMake(69.62, 15.69)];
        [bezierPath addLineToPoint: CGPointMake(50, 15.69)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(50, 34.4)];
        [bezierPath addCurveToPoint: CGPointMake(13.65, 49.22) controlPoint1: CGPointMake(36, 34.4) controlPoint2: CGPointMake(22.97, 39.9)];
        [bezierPath addLineToPoint: CGPointMake(20.28, 55.85)];
        [bezierPath addCurveToPoint: CGPointMake(50, 43.76) controlPoint1: CGPointMake(27.8, 48.32) controlPoint2: CGPointMake(38.43, 43.76)];
        [bezierPath addCurveToPoint: CGPointMake(79.83, 55.55) controlPoint1: CGPointMake(61.57, 43.76) controlPoint2: CGPointMake(72.3, 48.3)];
        [bezierPath addLineToPoint: CGPointMake(86.26, 48.83)];
        [bezierPath addCurveToPoint: CGPointMake(50.01, 34.4) controlPoint1: CGPointMake(76.95, 39.86) controlPoint2: CGPointMake(64.01, 34.4)];
        [bezierPath addLineToPoint: CGPointMake(50, 34.4)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(50.01, 53.12)];
        [bezierPath addCurveToPoint: CGPointMake(27.98, 62.28) controlPoint1: CGPointMake(41.48, 53.12) controlPoint2: CGPointMake(33.54, 56.72)];
        [bezierPath addLineToPoint: CGPointMake(34.61, 68.91)];
        [bezierPath addCurveToPoint: CGPointMake(50.01, 62.47) controlPoint1: CGPointMake(38.4, 65.11) controlPoint2: CGPointMake(44.19, 62.47)];
        [bezierPath addCurveToPoint: CGPointMake(65.41, 68.91) controlPoint1: CGPointMake(55.82, 62.47) controlPoint2: CGPointMake(61.61, 65.11)];
        [bezierPath addLineToPoint: CGPointMake(72.03, 62.28)];
        [bezierPath addCurveToPoint: CGPointMake(50.01, 53.12) controlPoint1: CGPointMake(66.47, 56.72) controlPoint2: CGPointMake(58.54, 53.12)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(50.01, 71.83)];
        [bezierPath addCurveToPoint: CGPointMake(41.23, 75.54) controlPoint1: CGPointMake(46.58, 71.83) controlPoint2: CGPointMake(43.42, 73.35)];
        [bezierPath addLineToPoint: CGPointMake(50.01, 84.31)];
        [bezierPath addLineToPoint: CGPointMake(58.78, 75.54)];
        [bezierPath addCurveToPoint: CGPointMake(50.01, 71.83) controlPoint1: CGPointMake(56.6, 73.04) controlPoint2: CGPointMake(53.44, 71.83)];
        [bezierPath closePath];
        bezierPath.miterLimit = 4;
        
        [color setFill];
        [bezierPath fill];
    }];
}

+ (UIImage *)imageWithIdentifier:(NSString *)identifier
{
    return [[self imageCache] objectForKey:identifier];
}

+ (void)removeImageWithIdentifier:(NSString *)identifier
{
    [[self imageCache] removeObjectForKey:identifier];
}

+ (void)setImage:(UIImage *)image forIdentifier:(NSString *)identifier
{
    if (![identifier length]) {
        return;
    }
    
    if (image && [image isKindOfClass:[UIImage class]]) {
        
        [[self imageCache] setObject:image forKey:identifier];
        
    } else if (!image) {
        [self removeImageWithIdentifier:identifier];
    }
}

+ (UIImage *)avatarImageWithUsername:(NSString *)username
{
    NSString *initials = [username otr_stringInitialsWithMaxCharacters:2];
    JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:initials
                                                                                  backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                        textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                             font:[UIFont systemFontOfSize:30.0f]
                                                                                         diameter:60];
    return jsqImage.avatarImage;
}

+ (UIImage *)avatarImageWithUniqueIdentifier:(NSString *)identifier avatarData:(NSData *)data displayName:(NSString *)displayName username:(NSString *)username
{
    UIImage *image = [self imageWithIdentifier:identifier];
    if (!image) {
        if (data) {
            image = [UIImage imageWithData:data];
        }
        else {
            NSString *name  = displayName;
            if (![name length]) {
                name = [[username componentsSeparatedByString:@"@"] firstObject];
                if (![name length]) {
                    name = username;
                }
            }
            image = [self avatarImageWithUsername:name];
        }
        
        [self setImage:image forIdentifier:identifier];
    }
    
    return image;
}

@end
