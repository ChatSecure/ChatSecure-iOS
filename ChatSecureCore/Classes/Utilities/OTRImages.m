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
@import BBlock;
@import JSQMessagesViewController;
#import "OTRComposingImageView.h"
#import "NSString+ChatSecure.h"
@import OTRAssets;

NSString *const OTRWarningImageKey = @"OTRWarningImageKey";
NSString *const OTRWarningCircleImageKey = @"OTRWarningCircleImageKey";
NSString *const OTRFacebookActivityImageKey = @"OTRFacebookActivityImageKey";
NSString *const OTRTwitterImageKey = @"OTRTwitterImageKey";
NSString *const OTRCheckmarkImageKey = @"OTRCeckmarkImageKey";
NSString *const OTRErrorImageKey = @"OTRErrorImageKey";
NSString *const OTRWifiImageKey = @"OTRWifiImageKey";
NSString *const OTRMicrophoneImageKey = @"OTRMicrophoneImageKey";
NSString *const OTRDuckDuckGoImageKey = @"OTRMicrophoneImageKey";

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

+ (UIImage *)duckduckgoImage
{
    return [UIImage imageWithIdentifier:OTRDuckDuckGoImageKey forSize:CGSizeMake(100, 100) andDrawingBlock:^{
        //// General Declarations
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        //// Color Declarations
        UIColor* gradientColor = [UIColor colorWithRed: 0.82 green: 0.267 blue: 0.153 alpha: 1];
        UIColor* gradientColor2 = [UIColor colorWithRed: 0.898 green: 0.322 blue: 0.145 alpha: 1];
        UIColor* gradientColor3 = [UIColor colorWithRed: 0.38 green: 0.463 blue: 0.725 alpha: 1];
        UIColor* gradientColor4 = [UIColor colorWithRed: 0.224 green: 0.29 blue: 0.624 alpha: 1];
        UIColor* fillColor = [UIColor colorWithRed: 0.835 green: 0.843 blue: 0.847 alpha: 1];
        UIColor* fillColor2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
        UIColor* fillColor3 = [UIColor colorWithRed: 0.176 green: 0.31 blue: 0.557 alpha: 1];
        UIColor* fillColor4 = [UIColor colorWithRed: 0.992 green: 0.824 blue: 0.039 alpha: 1];
        UIColor* fillColor5 = [UIColor colorWithRed: 0.396 green: 0.737 blue: 0.275 alpha: 1];
        UIColor* fillColor6 = [UIColor colorWithRed: 0.263 green: 0.635 blue: 0.267 alpha: 1];
        
        //// Gradient Declarations
        CGFloat linearGradient3082Locations[] = {0, 1};
        CGGradientRef linearGradient3082 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)gradientColor.CGColor, (id)gradientColor2.CGColor], linearGradient3082Locations);
        CGFloat linearGradient3084Locations[] = {0.01, 0.69};
        CGGradientRef linearGradient3084 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)gradientColor3.CGColor, (id)gradientColor4.CGColor], linearGradient3084Locations);
        
        //// duck
        {
            //// g3
            {
                //// path10 Drawing
                UIBezierPath* path10Path = UIBezierPath.bezierPath;
                [path10Path moveToPoint: CGPointMake(93.75, 50)];
                [path10Path addCurveToPoint: CGPointMake(50, 93.75) controlPoint1: CGPointMake(93.75, 74.16) controlPoint2: CGPointMake(74.16, 93.75)];
                [path10Path addCurveToPoint: CGPointMake(6.25, 50) controlPoint1: CGPointMake(25.84, 93.75) controlPoint2: CGPointMake(6.25, 74.16)];
                [path10Path addCurveToPoint: CGPointMake(50, 6.25) controlPoint1: CGPointMake(6.25, 25.84) controlPoint2: CGPointMake(25.84, 6.25)];
                [path10Path addCurveToPoint: CGPointMake(93.75, 50) controlPoint1: CGPointMake(74.16, 6.25) controlPoint2: CGPointMake(93.75, 25.84)];
                [path10Path closePath];
                [path10Path moveToPoint: CGPointMake(100, 50)];
                [path10Path addCurveToPoint: CGPointMake(50, 100) controlPoint1: CGPointMake(100, 77.61) controlPoint2: CGPointMake(77.61, 100)];
                [path10Path addCurveToPoint: CGPointMake(0, 50) controlPoint1: CGPointMake(22.39, 100) controlPoint2: CGPointMake(0, 77.61)];
                [path10Path addCurveToPoint: CGPointMake(50, 0) controlPoint1: CGPointMake(0, 22.39) controlPoint2: CGPointMake(22.39, 0)];
                [path10Path addCurveToPoint: CGPointMake(100, 50) controlPoint1: CGPointMake(77.61, 0) controlPoint2: CGPointMake(100, 22.39)];
                [path10Path closePath];
                [path10Path moveToPoint: CGPointMake(95.87, 50)];
                [path10Path addCurveToPoint: CGPointMake(50, 4.13) controlPoint1: CGPointMake(95.87, 24.67) controlPoint2: CGPointMake(75.33, 4.13)];
                [path10Path addCurveToPoint: CGPointMake(4.13, 50) controlPoint1: CGPointMake(24.67, 4.13) controlPoint2: CGPointMake(4.13, 24.67)];
                [path10Path addCurveToPoint: CGPointMake(50, 95.87) controlPoint1: CGPointMake(4.13, 75.33) controlPoint2: CGPointMake(24.67, 95.87)];
                [path10Path addCurveToPoint: CGPointMake(95.87, 50) controlPoint1: CGPointMake(75.33, 95.87) controlPoint2: CGPointMake(95.87, 75.33)];
                [path10Path closePath];
                path10Path.miterLimit = 4;
                
                CGContextSaveGState(context);
                [path10Path addClip];
                CGContextDrawLinearGradient(context, linearGradient3082,
                                            CGPointMake(50, 100),
                                            CGPointMake(50, -0),
                                            kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
                CGContextRestoreGState(context);
                
                
                //// g12
                {
                    //// g14
                    {
                        //// g16
                        {
                            //// g18
                            {
                                //// g20
                                {
                                    //// g28
                                    {
                                        CGContextSaveGState(context);
                                        CGContextBeginTransparencyLayer(context, NULL);
                                        
                                        //// Clip g
                                        UIBezierPath* gPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(6.05, 6, 87.9, 87.8)];
                                        [gPath addClip];
                                        
                                        
                                        //// path30 Drawing
                                        UIBezierPath* path30Path = UIBezierPath.bezierPath;
                                        [path30Path moveToPoint: CGPointMake(67.57, 113.86)];
                                        [path30Path addCurveToPoint: CGPointMake(53.97, 84.55) controlPoint1: CGPointMake(66.06, 106.91) controlPoint2: CGPointMake(57.29, 91.2)];
                                        [path30Path addCurveToPoint: CGPointMake(48.83, 62.49) controlPoint1: CGPointMake(50.65, 77.9) controlPoint2: CGPointMake(47.31, 68.53)];
                                        [path30Path addCurveToPoint: CGPointMake(46.86, 52.42) controlPoint1: CGPointMake(49.11, 61.39) controlPoint2: CGPointMake(45.95, 53.01)];
                                        [path30Path addCurveToPoint: CGPointMake(58.59, 50.86) controlPoint1: CGPointMake(53.91, 47.82) controlPoint2: CGPointMake(55.77, 52.92)];
                                        [path30Path addCurveToPoint: CGPointMake(62.53, 49.97) controlPoint1: CGPointMake(60.05, 49.79) controlPoint2: CGPointMake(62.02, 51.74)];
                                        [path30Path addCurveToPoint: CGPointMake(55.18, 27.74) controlPoint1: CGPointMake(64.34, 43.63) controlPoint2: CGPointMake(60.01, 32.57)];
                                        [path30Path addCurveToPoint: CGPointMake(48.45, 24.65) controlPoint1: CGPointMake(53.6, 26.16) controlPoint2: CGPointMake(51.18, 25.18)];
                                        [path30Path addCurveToPoint: CGPointMake(43.3, 20.56) controlPoint1: CGPointMake(47.4, 23.21) controlPoint2: CGPointMake(45.7, 21.83)];
                                        [path30Path addCurveToPoint: CGPointMake(31.81, 16.76) controlPoint1: CGPointMake(40.63, 19.14) controlPoint2: CGPointMake(34.82, 17.26)];
                                        [path30Path addCurveToPoint: CGPointMake(28.36, 17.15) controlPoint1: CGPointMake(29.72, 16.42) controlPoint2: CGPointMake(29.25, 17)];
                                        [path30Path addCurveToPoint: CGPointMake(33.9, 19.28) controlPoint1: CGPointMake(29.19, 17.22) controlPoint2: CGPointMake(33.13, 19.17)];
                                        [path30Path addCurveToPoint: CGPointMake(29.44, 19.91) controlPoint1: CGPointMake(33.13, 19.8) controlPoint2: CGPointMake(30.88, 19.26)];
                                        [path30Path addCurveToPoint: CGPointMake(28.18, 22.07) controlPoint1: CGPointMake(28.71, 20.23) controlPoint2: CGPointMake(28.17, 21.48)];
                                        [path30Path addCurveToPoint: CGPointMake(42.51, 23.74) controlPoint1: CGPointMake(32.29, 21.65) controlPoint2: CGPointMake(38.71, 22.05)];
                                        [path30Path addCurveToPoint: CGPointMake(32.92, 25.51) controlPoint1: CGPointMake(39.49, 24.09) controlPoint2: CGPointMake(34.9, 24.47)];
                                        [path30Path addCurveToPoint: CGPointMake(26.16, 44.06) controlPoint1: CGPointMake(27.18, 28.53) controlPoint2: CGPointMake(24.65, 35.59)];
                                        [path30Path addCurveToPoint: CGPointMake(36.44, 93.61) controlPoint1: CGPointMake(27.67, 52.5) controlPoint2: CGPointMake(34.32, 83.32)];
                                        [path30Path addCurveToPoint: CGPointMake(27.67, 112.35) controlPoint1: CGPointMake(38.55, 103.89) controlPoint2: CGPointMake(31.9, 110.53)];
                                        [path30Path addLineToPoint: CGPointMake(32.21, 112.65)];
                                        [path30Path addLineToPoint: CGPointMake(30.7, 115.98)];
                                        [path30Path addCurveToPoint: CGPointMake(42.17, 114.77) controlPoint1: CGPointMake(36.13, 116.58) controlPoint2: CGPointMake(42.17, 114.77)];
                                        [path30Path addCurveToPoint: CGPointMake(32.81, 119.3) controlPoint1: CGPointMake(40.97, 118.09) controlPoint2: CGPointMake(32.81, 119.3)];
                                        [path30Path addCurveToPoint: CGPointMake(43.08, 118.09) controlPoint1: CGPointMake(32.81, 119.3) controlPoint2: CGPointMake(36.74, 120.51)];
                                        [path30Path addCurveToPoint: CGPointMake(53.36, 114.16) controlPoint1: CGPointMake(49.43, 115.67) controlPoint2: CGPointMake(53.36, 114.16)];
                                        [path30Path addLineToPoint: CGPointMake(56.38, 122.02)];
                                        [path30Path addLineToPoint: CGPointMake(62.12, 116.28)];
                                        [path30Path addLineToPoint: CGPointMake(64.54, 122.32)];
                                        [path30Path addCurveToPoint: CGPointMake(67.57, 113.86) controlPoint1: CGPointMake(64.55, 122.32) controlPoint2: CGPointMake(69.08, 120.81)];
                                        [path30Path closePath];
                                        path30Path.miterLimit = 4;
                                        
                                        [fillColor setFill];
                                        [path30Path fill];
                                        
                                        
                                        //// path32 Drawing
                                        UIBezierPath* path32Path = UIBezierPath.bezierPath;
                                        [path32Path moveToPoint: CGPointMake(69.39, 112.45)];
                                        [path32Path addCurveToPoint: CGPointMake(55.8, 83.13) controlPoint1: CGPointMake(67.89, 105.5) controlPoint2: CGPointMake(59.12, 89.78)];
                                        [path32Path addCurveToPoint: CGPointMake(50.66, 61.08) controlPoint1: CGPointMake(52.47, 76.48) controlPoint2: CGPointMake(49.15, 67.12)];
                                        [path32Path addCurveToPoint: CGPointMake(51.86, 54.89) controlPoint1: CGPointMake(50.94, 59.98) controlPoint2: CGPointMake(50.94, 55.49)];
                                        [path32Path addCurveToPoint: CGPointMake(61.23, 52.67) controlPoint1: CGPointMake(58.9, 50.29) controlPoint2: CGPointMake(58.4, 54.74)];
                                        [path32Path addCurveToPoint: CGPointMake(64.36, 48.56) controlPoint1: CGPointMake(62.69, 51.61) controlPoint2: CGPointMake(63.86, 50.32)];
                                        [path32Path addCurveToPoint: CGPointMake(57.01, 26.32) controlPoint1: CGPointMake(66.18, 42.21) controlPoint2: CGPointMake(61.84, 31.16)];
                                        [path32Path addCurveToPoint: CGPointMake(50.28, 23.23) controlPoint1: CGPointMake(55.44, 24.75) controlPoint2: CGPointMake(53.01, 23.76)];
                                        [path32Path addCurveToPoint: CGPointMake(45.15, 19.14) controlPoint1: CGPointMake(49.24, 21.8) controlPoint2: CGPointMake(47.54, 20.42)];
                                        [path32Path addCurveToPoint: CGPointMake(29.84, 16.73) controlPoint1: CGPointMake(40.63, 16.74) controlPoint2: CGPointMake(35.03, 15.79)];
                                        [path32Path addCurveToPoint: CGPointMake(33.33, 18.63) controlPoint1: CGPointMake(30.67, 16.8) controlPoint2: CGPointMake(32.57, 18.52)];
                                        [path32Path addCurveToPoint: CGPointMake(29.12, 21.06) controlPoint1: CGPointMake(32.17, 19.42) controlPoint2: CGPointMake(29.1, 19.32)];
                                        [path32Path addCurveToPoint: CGPointMake(41.55, 22.99) controlPoint1: CGPointMake(33.24, 20.65) controlPoint2: CGPointMake(37.75, 21.3)];
                                        [path32Path addCurveToPoint: CGPointMake(33.74, 25.12) controlPoint1: CGPointMake(38.53, 23.33) controlPoint2: CGPointMake(35.72, 24.07)];
                                        [path32Path addCurveToPoint: CGPointMake(28, 42.64) controlPoint1: CGPointMake(28, 28.14) controlPoint2: CGPointMake(26.49, 34.18)];
                                        [path32Path addCurveToPoint: CGPointMake(38.27, 92.2) controlPoint1: CGPointMake(29.51, 51.11) controlPoint2: CGPointMake(36.16, 81.92)];
                                        [path32Path addCurveToPoint: CGPointMake(29.51, 110.93) controlPoint1: CGPointMake(40.39, 102.47) controlPoint2: CGPointMake(33.74, 109.12)];
                                        [path32Path addLineToPoint: CGPointMake(34.05, 111.23)];
                                        [path32Path addLineToPoint: CGPointMake(32.54, 114.56)];
                                        [path32Path addCurveToPoint: CGPointMake(44.02, 113.35) controlPoint1: CGPointMake(37.97, 115.16) controlPoint2: CGPointMake(44.02, 113.35)];
                                        [path32Path addCurveToPoint: CGPointMake(34.65, 117.88) controlPoint1: CGPointMake(42.81, 116.68) controlPoint2: CGPointMake(34.65, 117.88)];
                                        [path32Path addCurveToPoint: CGPointMake(44.92, 116.67) controlPoint1: CGPointMake(34.65, 117.88) controlPoint2: CGPointMake(38.58, 119.09)];
                                        [path32Path addCurveToPoint: CGPointMake(55.2, 112.75) controlPoint1: CGPointMake(51.27, 114.25) controlPoint2: CGPointMake(55.2, 112.75)];
                                        [path32Path addLineToPoint: CGPointMake(58.22, 120.6)];
                                        [path32Path addLineToPoint: CGPointMake(63.97, 114.86)];
                                        [path32Path addLineToPoint: CGPointMake(66.39, 120.9)];
                                        [path32Path addCurveToPoint: CGPointMake(69.39, 112.45) controlPoint1: CGPointMake(66.38, 120.91) controlPoint2: CGPointMake(70.91, 119.39)];
                                        [path32Path closePath];
                                        path32Path.miterLimit = 4;
                                        
                                        [fillColor2 setFill];
                                        [path32Path fill];
                                        
                                        
                                        //// path34 Drawing
                                        UIBezierPath* path34Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(34.7, 39.9, 6.3, 6.3)];
                                        [fillColor3 setFill];
                                        [path34Path fill];
                                        
                                        
                                        //// path36 Drawing
                                        UIBezierPath* path36Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(38.45, 41.2, 1.6, 1.6)];
                                        [fillColor2 setFill];
                                        [path36Path fill];
                                        
                                        
                                        //// path38 Drawing
                                        UIBezierPath* path38Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(56.3, 38.45, 5.5, 5.5)];
                                        [fillColor3 setFill];
                                        [path38Path fill];
                                        
                                        
                                        //// path40 Drawing
                                        UIBezierPath* path40Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(59.55, 39.6, 1.4, 1.4)];
                                        [fillColor2 setFill];
                                        [path40Path fill];
                                        
                                        
                                        //// path47 Drawing
                                        UIBezierPath* path47Path = UIBezierPath.bezierPath;
                                        [path47Path moveToPoint: CGPointMake(38.73, 33.87)];
                                        [path47Path addCurveToPoint: CGPointMake(34.02, 34.25) controlPoint1: CGPointMake(38.73, 33.87) controlPoint2: CGPointMake(36.34, 32.79)];
                                        [path47Path addCurveToPoint: CGPointMake(31.78, 37.2) controlPoint1: CGPointMake(31.7, 35.71) controlPoint2: CGPointMake(31.78, 37.2)];
                                        [path47Path addCurveToPoint: CGPointMake(33.84, 33.1) controlPoint1: CGPointMake(31.78, 37.2) controlPoint2: CGPointMake(30.55, 34.45)];
                                        [path47Path addCurveToPoint: CGPointMake(38.73, 33.87) controlPoint1: CGPointMake(37.13, 31.75) controlPoint2: CGPointMake(38.73, 33.87)];
                                        [path47Path closePath];
                                        path47Path.miterLimit = 4;
                                        
                                        CGContextSaveGState(context);
                                        [path47Path addClip];
                                        CGContextDrawLinearGradient(context, linearGradient3084,
                                                                    CGPointMake(31.55, 34.93),
                                                                    CGPointMake(38.73, 34.93),
                                                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
                                        CGContextRestoreGState(context);
                                        
                                        
                                        //// path54 Drawing
                                        UIBezierPath* path54Path = UIBezierPath.bezierPath;
                                        [path54Path moveToPoint: CGPointMake(60.69, 33.65)];
                                        [path54Path addCurveToPoint: CGPointMake(57.63, 32.69) controlPoint1: CGPointMake(60.69, 33.65) controlPoint2: CGPointMake(58.97, 32.67)];
                                        [path54Path addCurveToPoint: CGPointMake(54.14, 33.93) controlPoint1: CGPointMake(54.89, 32.72) controlPoint2: CGPointMake(54.14, 33.93)];
                                        [path54Path addCurveToPoint: CGPointMake(58.11, 31.63) controlPoint1: CGPointMake(54.14, 33.93) controlPoint2: CGPointMake(54.6, 31.05)];
                                        [path54Path addCurveToPoint: CGPointMake(60.69, 33.65) controlPoint1: CGPointMake(60.01, 31.94) controlPoint2: CGPointMake(60.69, 33.65)];
                                        [path54Path closePath];
                                        path54Path.miterLimit = 4;
                                        
                                        CGContextSaveGState(context);
                                        [path54Path addClip];
                                        CGContextDrawLinearGradient(context, linearGradient3084,
                                                                    CGPointMake(54.14, 32.74),
                                                                    CGPointMake(60.69, 32.74),
                                                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
                                        CGContextRestoreGState(context);
                                        
                                        
                                        CGContextEndTransparencyLayer(context);
                                        CGContextRestoreGState(context);
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    //// path56 Drawing
                    UIBezierPath* path56Path = UIBezierPath.bezierPath;
                    [path56Path moveToPoint: CGPointMake(47.55, 55.31)];
                    [path56Path addCurveToPoint: CGPointMake(56.34, 49.53) controlPoint1: CGPointMake(47.86, 53.39) controlPoint2: CGPointMake(52.83, 49.75)];
                    [path56Path addCurveToPoint: CGPointMake(63.89, 48.66) controlPoint1: CGPointMake(59.86, 49.31) controlPoint2: CGPointMake(60.96, 49.36)];
                    [path56Path addCurveToPoint: CGPointMake(76.49, 45.1) controlPoint1: CGPointMake(66.83, 47.96) controlPoint2: CGPointMake(74.39, 46.07)];
                    [path56Path addCurveToPoint: CGPointMake(81.21, 49.07) controlPoint1: CGPointMake(78.59, 44.14) controlPoint2: CGPointMake(87.47, 45.58)];
                    [path56Path addCurveToPoint: CGPointMake(65.98, 54.93) controlPoint1: CGPointMake(78.5, 50.59) controlPoint2: CGPointMake(71.2, 53.37)];
                    [path56Path addCurveToPoint: CGPointMake(55.87, 56) controlPoint1: CGPointMake(60.77, 56.49) controlPoint2: CGPointMake(57.6, 53.44)];
                    [path56Path addCurveToPoint: CGPointMake(61.82, 61.41) controlPoint1: CGPointMake(54.49, 58.04) controlPoint2: CGPointMake(55.59, 60.83)];
                    [path56Path addCurveToPoint: CGPointMake(79.18, 60.05) controlPoint1: CGPointMake(70.23, 62.19) controlPoint2: CGPointMake(78.3, 57.62)];
                    [path56Path addCurveToPoint: CGPointMake(67.01, 65.6) controlPoint1: CGPointMake(80.08, 62.48) controlPoint2: CGPointMake(71.96, 65.51)];
                    [path56Path addCurveToPoint: CGPointMake(50.62, 61.3) controlPoint1: CGPointMake(62.07, 65.69) controlPoint2: CGPointMake(52.11, 62.34)];
                    [path56Path addCurveToPoint: CGPointMake(47.55, 55.31) controlPoint1: CGPointMake(49.13, 60.26) controlPoint2: CGPointMake(47.13, 57.84)];
                    [path56Path closePath];
                    path56Path.miterLimit = 4;
                    
                    [fillColor4 setFill];
                    [path56Path fill];
                }
            }
            
            
            //// tie
            {
                //// path102 Drawing
                UIBezierPath* path102Path = UIBezierPath.bezierPath;
                [path102Path moveToPoint: CGPointMake(51.35, 81.53)];
                [path102Path addCurveToPoint: CGPointMake(39.34, 77.79) controlPoint1: CGPointMake(51.35, 81.53) controlPoint2: CGPointMake(39.54, 75.23)];
                [path102Path addCurveToPoint: CGPointMake(40.72, 91.58) controlPoint1: CGPointMake(39.14, 80.35) controlPoint2: CGPointMake(39.34, 90.79)];
                [path102Path addCurveToPoint: CGPointMake(51.95, 86.46) controlPoint1: CGPointMake(42.1, 92.36) controlPoint2: CGPointMake(51.95, 86.46)];
                [path102Path addLineToPoint: CGPointMake(51.35, 81.53)];
                [path102Path closePath];
                path102Path.miterLimit = 4;
                
                [fillColor5 setFill];
                [path102Path fill];
                
                
                //// path104 Drawing
                UIBezierPath* path104Path = UIBezierPath.bezierPath;
                [path104Path moveToPoint: CGPointMake(55.88, 81.14)];
                [path104Path addCurveToPoint: CGPointMake(65.73, 75.43) controlPoint1: CGPointMake(55.88, 81.14) controlPoint2: CGPointMake(63.96, 75.03)];
                [path104Path addCurveToPoint: CGPointMake(66.32, 89.02) controlPoint1: CGPointMake(67.5, 75.83) controlPoint2: CGPointMake(67.9, 88.42)];
                [path104Path addCurveToPoint: CGPointMake(55.5, 85.82) controlPoint1: CGPointMake(64.74, 89.61) controlPoint2: CGPointMake(55.5, 85.82)];
                [path104Path addLineToPoint: CGPointMake(55.88, 81.14)];
                [path104Path closePath];
                path104Path.miterLimit = 4;
                
                [fillColor5 setFill];
                [path104Path fill];
                
                
                //// path106 Drawing
                UIBezierPath* path106Path = UIBezierPath.bezierPath;
                [path106Path moveToPoint: CGPointMake(48.49, 82.2)];
                [path106Path addCurveToPoint: CGPointMake(49.67, 88.5) controlPoint1: CGPointMake(48.49, 86.33) controlPoint2: CGPointMake(47.9, 88.11)];
                [path106Path addCurveToPoint: CGPointMake(55.97, 87.72) controlPoint1: CGPointMake(51.44, 88.9) controlPoint2: CGPointMake(54.79, 88.5)];
                [path106Path addCurveToPoint: CGPointMake(55.78, 80.62) controlPoint1: CGPointMake(57.16, 86.93) controlPoint2: CGPointMake(56.17, 81.61)];
                [path106Path addCurveToPoint: CGPointMake(48.49, 82.2) controlPoint1: CGPointMake(55.38, 79.64) controlPoint2: CGPointMake(48.49, 80.43)];
                [path106Path closePath];
                path106Path.miterLimit = 4;
                
                [fillColor6 setFill];
                [path106Path fill];
                
                
                //// tiepath Drawing
                UIBezierPath* tiepathPath = UIBezierPath.bezierPath;
                [tiepathPath moveToPoint: CGPointMake(49.24, 81.28)];
                [tiepathPath addCurveToPoint: CGPointMake(50.42, 87.58) controlPoint1: CGPointMake(49.24, 85.42) controlPoint2: CGPointMake(48.65, 87.19)];
                [tiepathPath addCurveToPoint: CGPointMake(56.73, 86.8) controlPoint1: CGPointMake(52.19, 87.98) controlPoint2: CGPointMake(55.54, 87.58)];
                [tiepathPath addCurveToPoint: CGPointMake(56.53, 79.7) controlPoint1: CGPointMake(57.91, 86.01) controlPoint2: CGPointMake(56.92, 80.7)];
                [tiepathPath addCurveToPoint: CGPointMake(49.24, 81.28) controlPoint1: CGPointMake(56.13, 78.72) controlPoint2: CGPointMake(49.24, 79.51)];
                [tiepathPath closePath];
                tiepathPath.miterLimit = 4;
                
                [fillColor5 setFill];
                [tiepathPath fill];
            }
        }
        
        
        //// Cleanup
        CGGradientRelease(linearGradient3082);
        CGGradientRelease(linearGradient3084);
        CGColorSpaceRelease(colorSpace);

    }];
}

+ (UIImage *)xmppServerImageWithName:(NSString *)name
{
    if ([name isEqualToString:@"dukgo"]) {
        return [self duckduckgoImage];
    }
    else {
        return [UIImage imageNamed:name inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    }
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

+ (UIImage *)microphoneWithColor:(UIColor *)color size:(CGSize)size
{
    if (!color) {
        color = [UIColor blackColor];
    }
    
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = CGSizeMake(69.232, 100);
    } else {
        CGFloat normalRatio = 0.69232;
        CGFloat ratio = size.width / size.height;
        if (ratio < 0.69232 ) {
            size.height = size.width / normalRatio;
            
        } else {
            size.width = size.height * normalRatio;
        }
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@%@",OTRMicrophoneImageKey,[color description]];
    return [UIImage imageWithIdentifier:identifier forSize:size andDrawingBlock:^{
        
        CGRect group2 = CGRectMake(0, 0, size.width, size.height);
        
        
        //// Group 2
        {
            //// Bezier Drawing
            UIBezierPath* bezierPath = UIBezierPath.bezierPath;
            [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.49999 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69230 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.69616 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.63582 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.57639 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69230 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.64177 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.67347 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.75055 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.59817 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.55289 * CGRectGetHeight(group2))];
            [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.19231 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.69616 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.05649 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.13942 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.75057 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.09416 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.49999 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.00000 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.64177 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.01884 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.57639 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.00000 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.30382 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.05649 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.42360 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.00000 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.35822 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.01884 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.19231 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.24942 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.09415 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.13942 * CGRectGetHeight(group2))];
            [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.30382 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.63582 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.55289 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.24943 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.59817 * CGRectGetHeight(group2))];
            [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.49999 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69230 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.35821 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.67347 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.42360 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69230 * CGRectGetHeight(group2))];
            [bezierPath closePath];
            bezierPath.miterLimit = 4;
            
            [color setFill];
            [bezierPath fill];
            
            
            //// Bezier 3 Drawing
            UIBezierPath* bezier3Path = UIBezierPath.bezierPath;
            [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.98349 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.39603 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.94443 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.97251 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38842 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.95947 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.90537 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.39603 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.92938 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.91636 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38842 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.88888 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.42307 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.89437 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.40365 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.88888 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.41266 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.88888 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.77473 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69020 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.88888 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.57412 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.85082 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.63751 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.49999 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.76923 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.69864 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.74289 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.60706 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.76923 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.22525 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.69020 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.39293 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.76923 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.30136 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.74289 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.11111 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.14916 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.63753 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.11111 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.57412 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.11111 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.42307 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.09462 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.39603 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.11111 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.41266 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.10562 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.40365 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.05556 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.08363 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38842 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.07062 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.01649 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.39603 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.04051 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38461 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.02749 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.38842 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.42307 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.00550 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.40365 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.41266 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.12803 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.73107 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.58854 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.04268 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.66557 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.44443 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.84374 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.21338 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.79657 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.31885 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.83413 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.44443 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.18316 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.93449 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.20717 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.19415 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92688 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.16666 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.96153 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.17216 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.94210 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.16666 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.95112 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.18316 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.98857 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.16666 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.97194 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.17216 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.98097 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.22222 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 1.00000 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.19415 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.99619 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.20717 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 1.00000 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 1.00000 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.81681 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.98857 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.79280 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 1.00000 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.80584 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.99619 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.83332 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.96153 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.82782 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.98097 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.83332 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.97194 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.81681 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.93449 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.83332 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.95112 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.82782 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.94210 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.77775 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.80584 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92688 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.79280 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.55556 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.92307 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 0.55556 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.84374 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.87195 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.73107 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.68112 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.83413 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.78658 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.79657 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 1.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.50000 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 0.95731 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.66557 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 1.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.58854 * CGRectGetHeight(group2))];
            [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(group2) + 1.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.42307 * CGRectGetHeight(group2))];
            [bezier3Path addCurveToPoint: CGPointMake(CGRectGetMinX(group2) + 0.98349 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.39603 * CGRectGetHeight(group2)) controlPoint1: CGPointMake(CGRectGetMinX(group2) + 1.00000 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.41266 * CGRectGetHeight(group2)) controlPoint2: CGPointMake(CGRectGetMinX(group2) + 0.99449 * CGRectGetWidth(group2), CGRectGetMinY(group2) + 0.40365 * CGRectGetHeight(group2))];
            [bezier3Path closePath];
            bezier3Path.miterLimit = 4;
            
            [color setFill];
            [bezier3Path fill];
        }

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
            if (!name) {
                name = @"";
            }
            image = [self avatarImageWithUsername:name];
        }
        
        [self setImage:image forIdentifier:identifier];
    }
    
    return image;
}

@end
