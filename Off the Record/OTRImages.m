//
//  OTRstatusImage.m
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRImages.h"


@implementation OTRImages

+(UIColor *)colorWithStatus:(OTRBuddyStatus)status
{
    switch(status)
    {
        case OTRBuddyStatusOffline:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
        case OTRBuddyStatusAway:
            return [UIColor colorWithRed: 0.901 green: 0.527 blue: 0.23 alpha: 1];
            break;
        case OTRBuddyStatusXa:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRBuddyStatusDnd:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRBuddyStatusAvailable:
            return [UIColor colorWithRed: 0.083 green: 0.767 blue: 0.194 alpha: 1];
            break;
        default:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
    }
    
}

+(UIImage *)rawStatusImageWithStatus:(OTRBuddyStatus)status
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* bubbleColor = [OTRImages colorWithStatus:status];
    CGFloat bubbleColorRGBA[4];
    [bubbleColor getRed: &bubbleColorRGBA[0] green: &bubbleColorRGBA[1] blue: &bubbleColorRGBA[2] alpha: &bubbleColorRGBA[3]];
    
    UIColor* strokeColor = [UIColor colorWithRed: (bubbleColorRGBA[0] * 0.5) green: (bubbleColorRGBA[1] * 0.5) blue: (bubbleColorRGBA[2] * 0.5) alpha: (bubbleColorRGBA[3] * 0.5 + 0.5)];
    UIColor* outerShaddowColor = [bubbleColor colorWithAlphaComponent: 0.6];
    
    //// Shadow Declarations
    UIColor* outerShaddow = outerShaddowColor;
    CGSize outerShaddowOffset = CGSizeMake(0.1, -0.1);
    CGFloat outerShaddowBlurRadius = 3;
    
    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(3, 3, 12, 12)];
    [bubbleColor setFill];
    [ovalPath fill];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, outerShaddowOffset, outerShaddowBlurRadius, outerShaddow.CGColor);
    [strokeColor setStroke];
    ovalPath.lineWidth = 1;
    [ovalPath stroke];
    CGContextRestoreGState(context);
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dotImage;

}

+ (UIImage *)facebookImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(267, 267), NO, 0);
    
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
    
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)statusImageWithStatus:(OTRBuddyStatus)status
{
    switch (status) {
        case OTRBuddyStatusDnd:
            return [OTRImages dndImage];
            break;
        case OTRBuddyStatusXa:
            return [OTRImages xaImage];
            break;
        case OTRBuddyStatusAvailable:
            return [OTRImages availableImage];
            break;
        case OTRBuddyStatusAway:
            return [OTRImages awayImage];
            break;
        default:
            return [OTRImages offlineImage];
            break;
    }
    
}

+ (UIImage*) offlineImage {
    static UIImage *offlineImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        offlineImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusOffline];
    });
    return offlineImage;
}

+ (UIImage*) awayImage {
    static UIImage *awayImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        awayImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusAway];
    });
    return awayImage;
}

+ (UIImage*) availableImage {
    static UIImage *availableImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusAvailable];
    });
    return availableImage;
}

+ (UIImage*) xaImage {
    static UIImage *xaImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xaImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusXa];
    });
    return xaImage;
}

+ (UIImage*) dndImage {
    static UIImage *dndImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dndImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusDnd];
    });
    return dndImage;
}

+(UIImage *)caratImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, 0);
    //// Color Declarations
    UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// Polygon Drawing
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(6, 10.39)];
    [polygonPath addLineToPoint: CGPointMake(0.8, 2.6)];
    [polygonPath addLineToPoint: CGPointMake(11.2, 2.6)];
    [polygonPath closePath];
    [strokeColor setFill];
    [polygonPath fill];
    
    UIImage *carat = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return carat;
    
}

+(CGFloat)scale
{
    CGFloat scale = 1.0;
    if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
        CGFloat tmp = [[UIScreen mainScreen]scale];
        if (tmp > 1.5) {
            scale = 2.0;
        }
    }
    
    return scale;
}

+(UIImage *)openCaratImage
{
    
    
    UIImage * carat = [OTRImages caratImage];
    return [[UIImage alloc] initWithCGImage:carat.CGImage scale:[OTRImages scale] orientation:UIImageOrientationLeft];
    return carat;
    
}
+(UIImage *)closeCaratImage
{
    UIImage * carat = [OTRImages caratImage];
    return [[UIImage alloc] initWithCGImage: carat.CGImage
                               scale: [OTRImages scale] 
                         orientation: UIImageOrientationUp];
    
}



@end
