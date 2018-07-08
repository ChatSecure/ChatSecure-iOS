//
//  OTRColors.m
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRColors.h"
@import OTRAssets;

@implementation OTRColors

+(UIColor *)colorWithStatus:(OTRThreadStatus)status
{
    if (!OTRBranding.showsColorForStatus) {
        return [UIColor clearColor];
    }
    UIColor *color = nil;
    switch(status)
    {
        case OTRThreadStatusUnknown:
        case OTRThreadStatusOffline:
            color = [UIColor clearColor];
            break;
        case OTRThreadStatusAway:
            color = [UIColor colorWithRed: 0.901 green: 0.527 blue: 0.23 alpha: 1];
            break;
        case OTRThreadStatusExtendedAway:
            color = [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRThreadStatusDoNotDisturb:
            color = [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRThreadStatusAvailable:
            color = [UIColor colorWithRed: 0.083 green: 0.767 blue: 0.194 alpha: 1];
            break;
    }
    return color;
}



+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(color.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(color.CGColor);
    CGFloat newComponents[4];
    
    if (isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

+ (UIColor *)bubbleBlueColor
{
    return [UIColor colorWithHue:210.0f / 360.0f
                      saturation:0.94f
                      brightness:1.0f
                           alpha:1.0f];
}

+ (UIColor *)bubbleLightGrayColor
{
    return [UIColor colorWithHue:240.0f / 360.0f
                      saturation:0.02f
                      brightness:0.92f
                           alpha:1.0f];
}

+ (UIColor *)blueInfoColor
{
    return [UIColor colorWithRed:0.25f green:0.60f blue:1.00f alpha:1.00f];
}

+ (UIColor *)redErrorColor
{
    return [UIColor colorWithRed:0.89f green:0.42f blue:0.36f alpha:1.00f];
}

+ (UIColor *)greenNoErrorColor
{
    return [UIColor colorWithRed:0.32f green:0.64f blue:0.32f alpha:1.00f];
}

+ (UIColor *)warnColor {
    return [UIColor colorWithRed:0.94 green:0.77 blue:0 alpha:1];
}

+ (UIColor *)defaultBlueColor
{
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

@end
