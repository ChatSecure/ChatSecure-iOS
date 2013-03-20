//
//  OTRstatusImage.m
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRStatusImage.h"


@implementation OTRStatusImage

+(UIColor *)colorWithStatus:(OTRBuddyStatus)status
{
    switch(status)
    {
        case kOTRBuddyStatusOffline:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
        case kOTRBuddyStatusAway:
            return [UIColor colorWithRed: 0.901 green: 0.527 blue: 0.23 alpha: 1];
            break;
        case kOTRBuddyStatusXa:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case kOTRBUddyStatusDnd:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case kOTRBuddyStatusAvailable:
            return [UIColor colorWithRed: 0.083 green: 0.767 blue: 0.194 alpha: 1];
            break;
        default:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
    }
    
}

+(UIImage *)statusImageWithStatus:(OTRBuddyStatus)status
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* bubbleColor = [OTRStatusImage colorWithStatus:status];
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

@end
